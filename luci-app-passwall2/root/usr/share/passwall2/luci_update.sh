#!/bin/sh
CONFIG=passwall2
dir="$1"
status="$2"
manager="$3"
force="$4"

[ "$manager" = apk ] && extension=apk || extension=ipk
set -- "$dir/luci-app-${CONFIG}.${extension}"
for package in "$dir"/luci-i18n-${CONFIG}-*.${extension}; do
	[ -f "$package" ] && set -- "$@" "$package"
done

if [ "$manager" = apk ]; then
	extra=""
	[ "$force" = 1 ] && extra="--force-reinstall --force-overwrite"
	apk add --allow-untrusted $extra "$@"
	result=$?
else
	extra=""
	[ "$force" = 1 ] && extra="--force-reinstall"
	opkg install $extra "$@"
	result=$?
fi

rm -rf "$dir"
if [ "$result" = 0 ]; then
	rm -f "/tmp/etc/${CONFIG}_tmp/${CONFIG}_version" /tmp/luci-indexcache /tmp/luci-indexcache.*
	if [ -x /etc/init.d/rpcd ]; then
		/etc/init.d/rpcd restart >/dev/null 2>&1
	fi
	if [ -x /etc/init.d/uhttpd ]; then
		/etc/init.d/uhttpd reload >/dev/null 2>&1
	fi
fi
[ "$result" = 0 ] && echo '{"code":0}' > "$status" || echo '{"code":1}' > "$status"
(sleep 60; rm -f "$status") >/dev/null 2>&1 &
