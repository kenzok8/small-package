#!/bin/sh
# geo-cron.sh enable|disable
# Manage the geo auto-update crontab entry. enable reads the schedule from
# honk.main.geo_auto_freq (daily|weekly); both actions are idempotent.

ACTION="$1"
case "$ACTION" in
	enable|disable) ;;
	*) echo "usage: $0 enable|disable" >&2; exit 64 ;;
esac
CRONTAB="/etc/crontabs/root"
TAG="# luci-app-honk geo-update"
SCRIPT="/usr/share/luci-app-honk/update-geo.sh"

# Drop any previous honk geo entry (tag line + its command line).
clean() {
	[ -f "$CRONTAB" ] || return 0
	grep -vF -e "$TAG" -e "$SCRIPT" "$CRONTAB" > "$CRONTAB.tmp" 2>/dev/null
	mv "$CRONTAB.tmp" "$CRONTAB"
}

clean

if [ "$ACTION" = "enable" ]; then
	case "$(uci -q get honk.main.geo_auto_freq)" in
		weekly) sched="17 4 * * 0" ;;   # Sunday 04:17
		*)      sched="17 4 * * *" ;;    # every day 04:17
	esac
	mkdir -p /etc/crontabs
	{
		echo "$TAG"
		echo "$sched $SCRIPT geoip; $SCRIPT geosite"
	} >> "$CRONTAB"
	/etc/init.d/cron enable >/dev/null 2>&1
fi

/etc/init.d/cron restart >/dev/null 2>&1
exit 0
