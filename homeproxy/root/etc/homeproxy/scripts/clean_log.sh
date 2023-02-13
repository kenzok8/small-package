#!/bin/sh
# SPDX-License-Identifier: GPL-2.0-only
#
# Copyright (C) 2022-2023 ImmortalWrt.org

NAME="homeproxy"

log_max_size="10" #KB
main_log_file="/var/run/$NAME/$NAME.log"
sing_log_file="/var/run/$NAME/sing-box.log"

while true; do
	for i in "$main_log_file" "$sing_log_file"; do
		[ -s "$i" ] || continue
		[ "$(( $(ls -l "$i" | awk -F ' ' '{print $5}') / 1024 >= log_max_size))" -eq "0" ] || echo "" > "$i"
	done

	sleep 180
done
