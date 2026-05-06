#!/bin/sh

UPDATE_LOG="/tmp/clash_update.txt"

log_update() {
	printf '  %s - %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1" >>"$UPDATE_LOG"
}

log_update "更新大陆白名单"
sh /usr/share/clashoo/update/update_china_ip.sh >> "$UPDATE_LOG" 2>&1

log_update "更新 GeoIP / GeoSite"
sh /usr/share/clashoo/update/geoip.sh >/dev/null 2>&1

exit 0
