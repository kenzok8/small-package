#!/bin/sh
# Manage daed subscription auto-update cron entry.

ACTION="$1"
CRONTAB="/etc/crontabs/root"
TAG="# luci-app-daede daed-sub-update"
SCRIPT="/usr/share/luci-app-daede/daed-sub-update.sh"

clean() {
	[ -f "$CRONTAB" ] || return 0
	grep -vF -e "$TAG" -e "$SCRIPT" "$CRONTAB" > "$CRONTAB.tmp" 2>/dev/null
	mv "$CRONTAB.tmp" "$CRONTAB"
}

clean

if [ "$ACTION" = "enable" ] && [ "$(uci -q get daed.config.subscribe_auto_update)" = "1" ]; then
	hour="$(uci -q get daed.config.subscribe_update_hour)"
	case "$hour" in
		''|*[!0-9]*) hour=4 ;;
	esac
	[ "$hour" -ge 0 ] 2>/dev/null && [ "$hour" -le 23 ] 2>/dev/null || hour=4

	case "$(uci -q get daed.config.subscribe_update_cycle)" in
		weekly) sched="17 $hour * * 0" ;;
		*)      sched="17 $hour * * *" ;;
	esac

	mkdir -p /etc/crontabs
	{
		echo "$TAG"
		echo "$sched $SCRIPT >/dev/null 2>&1"
	} >> "$CRONTAB"
	/etc/init.d/cron enable >/dev/null 2>&1
fi

/etc/init.d/cron restart >/dev/null 2>&1
exit 0
