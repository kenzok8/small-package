#!/bin/sh

mkdir -p /var/lock

for service in adb-enablemodem appfilter gpio_switch hd-idle \
	kmods kmods-unload led lm-sensors luci-fan \
	mdadm modemmanager smartd sysfixtime sysfsutils sysntpd \
	tuning_net usbmode wan_drop zprintk zram
do
	[ -x /etc/init.d/$service ] && /etc/init.d/$service disable
done

for file in \
	/etc/board.d \
	/etc/config/appfilter \
	/etc/config/kmods \
	/etc/init.d/appfilter \
	/ext_overlay \
	/lib/upgrade/ota.sh \
	/lib/upgrade/platform.sh \
	/lib/board \
	/sbin/ujail \
	/usr/libexec/fan-control \
	/usr/sbin/sandbox
do
	rm -rf "$file"
done

rm -rf /var/lock/*.lock
