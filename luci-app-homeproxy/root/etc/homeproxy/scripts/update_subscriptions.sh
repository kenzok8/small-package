#!/bin/sh
# SPDX-License-Identifier: GPL-2.0-only
#
# Copyright (C) 2023 ImmortalWrt.org

SCRIPTS_DIR="/etc/homeproxy/scripts"
RUN_DIR="/var/run/homeproxy"
LOG_PATH="$RUN_DIR/homeproxy.log"
LOCK_PATH="$RUN_DIR/update_subscriptions.lock"

mkdir -p "$RUN_DIR" || exit 1

log() {
	printf '%s [SUBSCRIBE] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$LOG_PATH"
}

exec 9>"$LOCK_PATH" || {
	log "Failed to open the subscription update lock."
	exit 1
}

if ! flock -n 9 >"/dev/null" 2>&1; then
	log "Subscription update did not complete; another task may be running."
	exit 2
fi

ucode "$SCRIPTS_DIR/update_subscriptions.uc" 2>>"$LOG_PATH"
status="$?"
if [ "$status" -ne 0 ]; then
	log "Subscription update failed with exit code $status."
	exit "$status"
fi
