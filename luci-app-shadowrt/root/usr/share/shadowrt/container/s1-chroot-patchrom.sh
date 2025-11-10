#!/bin/sh

mkdir -p /var/lock

for service in adb-enablemodem appfilter dockerd gpio_switch hd-idle \
	kmods kmods-unload lcdsimple led lm-sensors luci-fan \
	mdadm modemmanager odhcpd smartd sysfixtime sysfsutils sysntpd \
	tuning_net umount usbmode usbmuxd wan_drop zprintk zram
do
	[ -x /etc/init.d/$service ] && /etc/init.d/$service disable
done

for file in \
	/etc/board.d \
	/etc/config/appfilter \
	/etc/config/kmods \
	/etc/init.d/appfilter \
	/etc/init.d/umount \
	/ext_overlay \
	/lib/upgrade/ota.sh \
	/lib/upgrade/platform.sh \
	/lib/board \
	/sbin/ujail \
	/usr/lib/opkg/info/luci-app-oaf.control \
	/usr/libexec/fan-control \
	/usr/sbin/sandbox
do
	rm -rf "$file"
done

rm -rf /var/lock/*.lock
