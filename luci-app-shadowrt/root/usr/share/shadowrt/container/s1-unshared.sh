#!/bin/sh
NEWROOT=/rom
PATCHROM=/tmp/rom

SHAREDMNT=false
mountpoint -q /mnt && SHAREDMNT=true

mount --make-private /
mount --make-private /sys
mount --make-rprivate /tmp 2>/dev/null
mount --make-rprivate /proc
mount --make-private /rom
mount --make-private /overlay

mount -t tmpfs -o ro,relatime tmpfs /sys/block
mount -t tmpfs -o size=1M tmpfs /tmp

# make all private except /mnt
mkdir -p $PATCHROM
mount --bind / $PATCHROM
mount --move /proc $PATCHROM/proc
# move /mnt to tmproot/mnt
$SHAREDMNT && mount --move /mnt $PATCHROM/mnt
pivot_root $PATCHROM $PATCHROM/tmp || exit 1

# old root now in /tmp
mount --make-rprivate /tmp
$SHAREDMNT && mount --move /mnt /tmp/mnt
mount --move /proc /tmp/proc
pivot_root /tmp /tmp$PATCHROM || exit 1
umount $PATCHROM

# umount annoying docker rootfs
if $SHAREDMNT; then
	OLDROOTFS=`grep -m1 "^overlay / overlay" /proc/1/mounts | sed -nE 's#^.*,workdir=(/mnt/.*)/work 0 0$#\1/merged#p'`
	if [ -n "$OLDROOTFS" ]; then
		echo "umount $OLDROOTFS" >&2
		mount --make-rprivate "$OLDROOTFS"
		umount -l "$OLDROOTFS"
	fi
fi

# patch rom
LOWERDIR=/rom

mkdir -p /tmp/tmp/shadowrt /tmp/patch/upper/usr/libexec /tmp/patch/work

cp -a /rom/sbin/kmodloader /tmp/patch/upper/usr/libexec/

for o in 0 2; do
	cp -a /shadowrt/overwrite/$o/. /tmp/patch/upper/
done

OVERLAYFS_UUID=",uuid=null"
if ! mount -o noatime,lowerdir=$LOWERDIR,upperdir=/tmp/patch/upper,workdir=/tmp/patch/work,xino=off$OVERLAYFS_UUID \
		-t overlay "/dev/root" $PATCHROM ; then
	OVERLAYFS_UUID=""
	mount -o noatime,lowerdir=$LOWERDIR,upperdir=/tmp/patch/upper,workdir=/tmp/patch/work,xino=off \
		-t overlay "/dev/root" $PATCHROM || exit 1
fi

mount --bind /tmp/tmp $PATCHROM/tmp
mount --bind /shadowrt $PATCHROM/tmp/shadowrt
chroot $PATCHROM /tmp/shadowrt/s1-chroot-patchrom.sh
umount $PATCHROM/tmp/shadowrt
umount $PATCHROM/tmp
rm -rf /tmp/tmp

set_default_ip()
{
	local ip=$1
	[ -n "$ip" ] || return 1
	echo "pass ip address to shadow: $ip" >&2
	sed -i -e "s/^IP_PROTO=.*/IP_PROTO=static/g" -e "s#^IP_ADDRESS=.*#IP_ADDRESS=$ip#g" "$PATCHROM/bin/board_detect"
}

set_default_gw_dns()
{
	local gw=$1
	local dns="$2"
	echo "pass gateway/dns to shadow: $gw/$dns" >&2
	sed -i -e "s/^GATEWAY=.*/GATEWAY=$gw/g" -e "s/^DNS=.*/DNS='$dns'/g" "$PATCHROM/etc/uci-defaults/zzz-dockerenv"
}

set_default_network()
{
	if [ "dhcp" != "$IP_PROTO" ]; then
		# ip
		local ip=$IP_ADDRESS
		[ -z "$ip" ] && ip=`ip addr show dev eth0 | grep -m1 'inet ' | head -1 | sed -nE 's#.*inet ([0-9\.]*)/([0-9]*) .*#\1/\2#p'`
		set_default_ip "$ip"
		# gateway dns
		local gw dns
		gw=$IP_GATEWAY
		dns="$IP_DNS"
		[ -z "$gw" ] && gw="$(route -n | grep -m1 '^0\.0\.0\.0 .* eth0$' | head -1 | xargs -r sh -c 'echo $1')"
		[ -z "$dns" ] && dns="$(grep '^nameserver ' /etc/resolv.conf | grep -oE '\d+\.\d+\.\d+\.\d+' | xargs -r sh -c 'echo $@' ignored)"
		set_default_gw_dns "$gw" "$dns"

		[ "on" = "$DHCP_SERVER" ] && sed -i -e "s/^DHCP_SERVER=.*/DHCP_SERVER=1/g" "$PATCHROM/etc/uci-defaults/zzz-dockerenv"
	fi
}

set_default_network

export -n IP_PROTO IP_ADDRESS IP_GATEWAY IP_DNS DHCP_SERVER
unset IP_PROTO IP_ADDRESS IP_GATEWAY IP_DNS DHCP_SERVER

umount $PATCHROM


# make sysctl net.* writable
mount --bind -o rw /proc/sys/net /proc/sys/net
# workaround busybox mount bug (alpine 3.22.2 arm64/v8)
grep '^proc /proc' /proc/mounts > /tmp/proconly.txt
sh -c 'mount --bind /tmp/proconly.txt /proc/$$/mounts && exec mount -o rw,remount /proc/sys/net'
rm -f /tmp/proconly.txt


PROCD_VER=`grep -o '^Version: [0-9]*' /rom/usr/lib/opkg/info/procd.control | cut -d' ' -f2`
if [ -n "$PROCD_VER" -a "$PROCD_VER" -lt 2024 ]; then
	# workaround procd < 2024 infite loop on resolving rootfs type, e.g. `ubus call system board`
	echo "overwrite /proc/$$/mounts for bug on procd v$PROCD_VER" >&2
	echo "/dev/root /rom squashfs ro,relatime 0 0" > /tmp/procd_mounts.txt
	cat /proc/mounts | grep -v '^tmpfs /tmp tmpfs' | grep -v ' /shadowrt ' >> /tmp/procd_mounts.txt
	mount --bind /tmp/procd_mounts.txt /proc/$$/mounts
	rm -f /tmp/procd_mounts.txt
fi


# mount openwrt rootfs
mount -o ro,noatime,lowerdir=/tmp/patch/upper:$LOWERDIR,xino=off$OVERLAYFS_UUID \
	-t overlay "/dev/root" /rom || exit 1

umount /tmp

mount --bind -o private /overlay $NEWROOT/overlay
$SHAREDMNT && mount --move /mnt $NEWROOT/mnt

mount --move /dev $NEWROOT/dev
mount --move /sys $NEWROOT/sys
mount --move /shadowrt $NEWROOT/tmp/busy

mount --move /proc $NEWROOT/proc

pivot_root $NEWROOT $NEWROOT/tmp/oldroot || exit 1
cd /
exec /tmp/busy/s2-wrtroot.sh "$1" "/tmp/oldroot"

