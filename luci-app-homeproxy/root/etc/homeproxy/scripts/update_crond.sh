#!/bin/sh
# SPDX-License-Identifier: GPL-2.0-only
#
# Copyright (C) 2023 ImmortalWrt.org

SCRIPTS_DIR="/etc/homeproxy/scripts"
RUN_DIR="/var/run/homeproxy"
LOG_PATH="$RUN_DIR/homeproxy.log"

UPDATE_PROXY=""
if [ "$(uci -q get homeproxy.subscription.update_via_proxy)" = "1" ]; then
	MIXED_PORT="$(uci -q get homeproxy.infra.mixed_port)"
	case "$MIXED_PORT" in
	''|*[!0-9]*) MIXED_PORT="5330" ;;
	esac
	UPDATE_PROXY="http://127.0.0.1:$MIXED_PORT"
fi

HOMEPROXY_UPDATE_PROXY="$UPDATE_PROXY" "$SCRIPTS_DIR"/update_resources.sh
RESOURCE_STATUS="$?"
CORE_RESOURCES_UPDATED=0
DASHBOARD_UPDATED=0
if [ "$RESOURCE_STATUS" -ne 2 ]; then
	CORE_RESOURCES_UPDATED="$(sed -n 's/^core_updated=//p' "$RUN_DIR/update_resources.result" 2>"/dev/null")"
	[ "$CORE_RESOURCES_UPDATED" = "1" ] || CORE_RESOURCES_UPDATED=0
	DASHBOARD_UPDATED="$(sed -n 's/^dashboard_updated=//p' "$RUN_DIR/update_resources.result" 2>"/dev/null")"
	[ "$DASHBOARD_UPDATED" = "1" ] || DASHBOARD_UPDATED=0
fi
RESOURCES_UPDATED=$((CORE_RESOURCES_UPDATED || DASHBOARD_UPDATED))

SUBSCRIPTION_URLS="$(uci -q get homeproxy.subscription.subscription_url)"
SUBSCRIPTION_STATUS=0
if [ -n "$SUBSCRIPTION_URLS" ]; then
	HOMEPROXY_RESOURCES_UPDATED="$RESOURCES_UPDATED" \
		"$SCRIPTS_DIR"/update_subscriptions.sh || SUBSCRIPTION_STATUS="$?"
else
	mkdir -p "$RUN_DIR"
	printf '%s [SUBSCRIBE] No subscription URL configured; skipping update.\n' \
		"$(date '+%Y-%m-%d %H:%M:%S')" >> "$LOG_PATH"
fi

if [ "$RESOURCES_UPDATED" -eq 1 ] && \
	{ [ -z "$SUBSCRIPTION_URLS" ] || [ "$SUBSCRIPTION_STATUS" -eq 2 ]; } && \
	   /etc/init.d/homeproxy running >/dev/null 2>&1; then
	if ! /etc/init.d/homeproxy reload >/dev/null 2>&1; then
		printf '%s [RESOURCES] Failed to reload HomeProxy after updating resources.\n' \
			"$(date '+%Y-%m-%d %H:%M:%S')" >> "$LOG_PATH"
	fi
fi
