#!/bin/sh
# Thanks to homeproxy

NAME="fchomo"

log_max_size="30" #KB
main_log_file="/var/run/$NAME/$NAME.log"
singc_log_file="/var/run/$NAME/mihomo-c.log"
sings_log_file="/var/run/$NAME/mihomo-s.log"

while true; do
	sleep 180
	for i in "$main_log_file" "$singc_log_file" "$sings_log_file"; do
		[ -s "$i" ] || continue
		[ "$(( $(ls -l "$i" | awk -F ' ' '{print $5}') / 1024 >= log_max_size))" -eq "0" ] || echo "" > "$i"
	done
done
