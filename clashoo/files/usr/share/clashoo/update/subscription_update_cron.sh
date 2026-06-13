#!/bin/sh

STATUS_FILE="${CLASHOO_STATUS_FILE:-/usr/share/clashbackup/subscription_update.status}"
UPDATER="${CLASHOO_SUBSCRIPTION_UPDATER:-/usr/share/clashoo/update/subscription_update.sh}"
SERVICE_CMD="${CLASHOO_SERVICE_CMD:-/etc/init.d/clashoo}"
interval="$(uci -q get clashoo.config.subscription_update_interval 2>/dev/null)"
now="$(date +%s)"
last=0

[ "$(uci -q get clashoo.config.auto_subscription_update 2>/dev/null)" = "1" ] || exit 0
"$SERVICE_CMD" status >/dev/null 2>&1 || exit 0
echo "$interval" | grep -Eq '^[0-9]+$' || interval=72
[ "$interval" -gt 0 ] || interval=72
[ -r "$STATUS_FILE" ] && last="$(sed -n 's/^last_run=//p' "$STATUS_FILE" | head -1)"
echo "$last" | grep -Eq '^[0-9]+$' || last=0

[ $((now - last)) -ge $((interval * 3600)) ] || exit 0
sh "$UPDATER" --all
