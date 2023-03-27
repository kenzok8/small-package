#!/bin/sh
# SPDX-License-Identifier: GPL-2.0-only
#
# Copyright (C) 2023 ImmortalWrt.org

SCRIPTS_DIR="/etc/homeproxy/scripts"

for i in "china_ip4" "china_ip6" "gfw_list" "china_list"; do
	"$SCRIPTS_DIR"/update_resources.sh "$i"
done

if [ "$(uci -q get homeproxy.config.routing_mode)" = "custom" ]; then
	for i in "geoip" "geosite"; do
		"$SCRIPTS_DIR"/update_resources.sh "$i"
	done
fi

"$SCRIPTS_DIR"/update_subscriptions.uc
