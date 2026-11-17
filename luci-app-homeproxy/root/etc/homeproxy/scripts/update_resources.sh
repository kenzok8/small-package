#!/bin/sh
# SPDX-License-Identifier: GPL-2.0-only
#
# Copyright (C) 2022-2025 ImmortalWrt.org

NAME="homeproxy"

RESOURCES_DIR="${RESOURCES_DIR:-/etc/$NAME/resources}"
DASHBOARD_DIR="${DASHBOARD_DIR:-/etc/$NAME/dashboard}"
RUN_DIR="${RUN_DIR:-/var/run/$NAME}"
LOG_PATH="$RUN_DIR/$NAME.log"
RESULT_PATH="$RUN_DIR/update_resources.result"
GEOIP_SOURCE="${GEOIP_SOURCE:-https://cdn.jsdelivr.net/gh/SagerNet/sing-geoip@rule-set/geoip-cn.srs}"
GEOIP_VERSION_URL="${GEOIP_VERSION_URL:-https://github.com/SagerNet/sing-geoip/releases/latest}"
GEOSITE_SOURCE="${GEOSITE_SOURCE:-https://cdn.jsdelivr.net/gh/SagerNet/sing-geosite@rule-set-unstable/geosite-cn.srs}"
GEOSITE_VERSION_URL="${GEOSITE_VERSION_URL:-https://github.com/SagerNet/sing-geosite/releases/latest}"
DASHBOARD_SOURCE="${DASHBOARD_SOURCE:-https://codeload.github.com/SagerNet/sing-box-dashboard/zip/refs/heads/gh-pages}"
DASHBOARD_VERSION_URL="${DASHBOARD_VERSION_URL:-https://github.com/SagerNet/sing-box-dashboard/commits/gh-pages.atom}"
USER_AGENT="HomeProxy resource updater"
UPDATE_PROXY="${HOMEPROXY_UPDATE_PROXY:-}"
SING_BOX="${SING_BOX:-/usr/bin/sing-box}"
UPDATE_BUDGET="${HOMEPROXY_UPDATE_BUDGET:-180}"
case "$UPDATE_BUDGET" in ''|*[!0-9]*) UPDATE_BUDGET=180 ;; esac
JOB_ID="${HOMEPROXY_JOB_ID:-$(date +%s)-$$}"
STARTED_AT="${HOMEPROXY_JOB_STARTED:-$(date +%s)}"
DEADLINE=$((STARTED_AT + UPDATE_BUDGET))
WORKER_PID="$$"
RUNNING=1
PHASE="starting"
APPLY_FAILED=0
ERROR=""

if ! mkdir -p "$RESOURCES_DIR" "$DASHBOARD_DIR" "$RUN_DIR"; then
	printf '%s\n' "Failed to prepare HomeProxy resource directories." >&2
	exit 1
fi

log() {
	printf '%s %s\n' "$(date "+%Y-%m-%d %H:%M:%S")" "$*" >> "$LOG_PATH"
}

UPDATED_BRANCHES=""
FAILED_BRANCHES=""
CORE_UPDATED=0
DASHBOARD_UPDATED=0

mark_updated() {
	UPDATED_BRANCHES="${UPDATED_BRANCHES:+$UPDATED_BRANCHES,}$1"
	case "$1" in
	dashboard) DASHBOARD_UPDATED=1 ;;
	*) CORE_UPDATED=1 ;;
	esac
}

mark_failed() {
	FAILED_BRANCHES="${FAILED_BRANCHES:+$FAILED_BRANCHES,}$1"
}

write_result() {
	local stage="$RESULT_PATH.$$.tmp"
	(umask 077; printf 'status=%s\nrunning=%s\njob_id=%s\npid=%s\nstarted_at=%s\nphase=%s\ncore_updated=%s\ndashboard_updated=%s\napply_failed=%s\nupdated=%s\nfailed=%s\nerror=%s\n' \
		"$1" "$RUNNING" "$JOB_ID" "$WORKER_PID" "$STARTED_AT" "$PHASE" \
		"$CORE_UPDATED" "$DASHBOARD_UPDATED" "$APPLY_FAILED" \
		"$UPDATED_BRANCHES" "$FAILED_BRANCHES" "$ERROR" > "$stage") &&
		mv -f "$stage" "$RESULT_PATH"
}

finish() {
	ERROR="${2:-}"
	if [ -z "$ERROR" ] && [ -n "$FAILED_BRANCHES" ] && [ "$(date +%s)" -ge "$DEADLINE" ]; then
		ERROR="deadline_exceeded"
	fi
	if [ "${HOMEPROXY_APPLY_DASHBOARD:-0}" = 1 ] &&
	   [ "$DASHBOARD_UPDATED" = 1 ] && /etc/init.d/homeproxy running >/dev/null 2>&1; then
		PHASE="applying"
		write_result "$1"
		/etc/init.d/homeproxy reload >/dev/null 2>&1 || APPLY_FAILED=1
	fi
	RUNNING=0
	PHASE="finished"
	write_result "$1"
	exit "$1"
}

run_curl() {
	local limit="$1" remaining
	shift
	remaining=$((DEADLINE - $(date +%s)))
	[ "$remaining" -gt 0 ] || return 28
	[ "$limit" -le "$remaining" ] || limit="$remaining"
	if [ -n "$UPDATE_PROXY" ]; then
		/usr/bin/curl --proxy "$UPDATE_PROXY" --connect-timeout 5 --max-time "$limit" "$@"
	else
		/usr/bin/curl --connect-timeout 5 --max-time "$limit" "$@"
	fi
}

download() {
	local attempt
	for attempt in 1 2; do
		if run_curl 60 -fsSL --compressed -A "$USER_AGENT" -o "$2" "$1" && test -s "$2"; then
			return 0
		fi
		[ "$attempt" -lt 2 ] && [ "$(date +%s)" -lt "$DEADLINE" ] || break
	done
	return 1
}

validate_rule_set() {
	"$SING_BOX" rule-set match -f binary "$1" 192.0.2.1 >/dev/null 2>&1
}

fetch_release_version() {
	local effective_url version
	effective_url="$(run_curl 8 -fsSL --compressed \
		-A "$USER_AGENT" -o /dev/null -w '%{url_effective}' "$1")" || return 1
	version="${effective_url##*/}"
	case "$version" in
	''|*[!0-9]*) return 1 ;;
	esac
	printf '%s\n' "$version"
}

fetch_dashboard_version() {
	local feed version

	feed="$(run_curl 8 -fsSL --compressed \
		-A "$USER_AGENT" "$DASHBOARD_VERSION_URL")" || return 1
	version="$(printf '%s\n' "$feed" | awk -F '[<>]' '
		/<updated>/ {
			version = $3
			gsub(/[-:TZ]/, "", version)
			print version
			exit
		}
	')"
	case "$version" in
	??????????????) case "$version" in *[!0-9]*) return 1 ;; esac ;;
	*) return 1 ;;
	esac
	printf '%s\n' "$version"
}

versioned_url() {
	case "$1" in
	http://*|https://*) printf '%s?v=%s' "$1" "$2" ;;
	*) printf '%s' "$1" ;;
	esac
}

install_rule_set() {
	local source_file="$1" version="$2" resource="$3"
	local stage_dir="$RESOURCES_DIR/.update.$$.tmp/$resource"

	mkdir -p "$stage_dir" &&
		cp "$source_file" "$stage_dir/$resource.srs" &&
		printf '%s\n' "$version" > "$stage_dir/$resource.ver" &&
		chmod 0644 "$stage_dir/$resource.srs" "$stage_dir/$resource.ver" || return 1
	if [ -e "$RESOURCES_DIR/$resource.srs" ]; then
		cp -p "$RESOURCES_DIR/$resource.srs" "$stage_dir/$resource.srs.old" || return 1
	fi
	mv -f "$stage_dir/$resource.srs" "$RESOURCES_DIR/$resource.srs" || return 1
	if ! mv -f "$stage_dir/$resource.ver" "$RESOURCES_DIR/$resource.ver"; then
		if [ -f "$stage_dir/$resource.srs.old" ]; then
			if ! mv -f "$stage_dir/$resource.srs.old" "$RESOURCES_DIR/$resource.srs"; then
				RESOURCE_RESTORE_FAILED=1
				printf 'Failed to restore %s; backup retained at %s.\n' "$resource" "$stage_dir" >&2
			fi
		else
			rm -f "$RESOURCES_DIR/$resource.srs" || RESOURCE_RESTORE_FAILED=1
		fi
		return 1
	fi
}

update_rule_set() {
	local resource="$1" source_url="$2" version_url="$3"
	local version old_version

	if ! version="$(fetch_release_version "$version_url")"; then
		log "[$resource] Failed to get the latest version; continuing with other resources."
		return 1
	fi
	old_version="$(cat "$RESOURCES_DIR/$resource.ver" 2>/dev/null)"
	if [ "$old_version" = "$version" ] && validate_rule_set "$RESOURCES_DIR/$resource.srs"; then
		log "[$resource] Current version: $version."
		return 0
	fi
	log "[$resource] Local version: ${old_version:-NOT FOUND}, latest version: $version."
	if ! download "$(versioned_url "$source_url" "$version")" "$TMP_DIR/$resource.srs"; then
		log "[$resource] Update failed while downloading the rule set."
		return 1
	fi
	if ! validate_rule_set "$TMP_DIR/$resource.srs"; then
		log "[$resource] Update failed: invalid binary rule set."
		return 1
	fi
	if ! install_rule_set "$TMP_DIR/$resource.srs" "$version" "$resource"; then
		log "[$resource] Update failed while installing the rule set."
		return 1
	fi
	mark_updated "$resource"
	log "[$resource] Successfully updated."
}

update_dashboard() {
	local version old_version index source_dir=""
	local backup_dir="${DASHBOARD_DIR}.old.$$"

	if ! version="$(fetch_dashboard_version)"; then
		log "[dashboard] Failed to get the latest version; continuing with other resources."
		return 1
	fi
	old_version="$(cat "$DASHBOARD_DIR/dashboard.ver" 2>/dev/null)"
	if [ "$old_version" = "$version" ] && [ -s "$DASHBOARD_DIR/index.html" ]; then
		log "[dashboard] Current version: $version."
		return 0
	fi
	log "[dashboard] Local version: ${old_version:-NOT FOUND}, latest version: $version."
	if ! download "$(versioned_url "$DASHBOARD_SOURCE" "$version")" "$TMP_DIR/dashboard.zip"; then
		log "[dashboard] Update failed while downloading the dashboard."
		return 1
	fi
	if ! unzip -q "$TMP_DIR/dashboard.zip" -d "$TMP_DIR/dashboard"; then
		log "[dashboard] Update failed while extracting the dashboard."
		return 1
	fi
	for index in "$TMP_DIR/dashboard/index.html" "$TMP_DIR"/dashboard/*/index.html; do
		if [ -s "$index" ]; then
			source_dir="${index%/index.html}"
			break
		fi
	done
	if [ -z "$source_dir" ]; then
		log "[dashboard] Update failed: invalid dashboard archive."
		return 1
	fi
	if ! mkdir -p "$DASHBOARD_STAGE" ||
	   ! cp -a "$source_dir/." "$DASHBOARD_STAGE/" ||
	   ! rm -f "$DASHBOARD_STAGE/.etag" ||
	   ! printf '%s\n' "$version" > "$DASHBOARD_STAGE/dashboard.ver" ||
	   ! chmod -R a+rX "$DASHBOARD_STAGE"; then
		log "[dashboard] Update failed while staging the dashboard."
		return 1
	fi
	if ! mv "$DASHBOARD_DIR" "$backup_dir"; then
		log "[dashboard] Update failed while backing up the dashboard."
		return 1
	fi
	if ! mv "$DASHBOARD_STAGE" "$DASHBOARD_DIR"; then
		mv "$backup_dir" "$DASHBOARD_DIR" || log "[dashboard] Unable to restore the dashboard; backup retained at $backup_dir."
		log "[dashboard] Update failed: unable to replace dashboard files."
		return 1
	fi
	rm -rf "$backup_dir"
	mark_updated "dashboard"
	log "[dashboard] Successfully updated."
}

if [ "${1:-}" != --worker ]; then
	exec 9>"$RUN_DIR/update_resources.lock"
fi
if ! flock -n 9 >/dev/null 2>&1; then
	log "[RESOURCES] A task is already running."
	exit 2
fi
if [ "${1:-}" = --background ]; then
	WORKER_PID=0
	write_result 0 || exit 1
	HOMEPROXY_JOB_ID="$JOB_ID" HOMEPROXY_JOB_STARTED="$STARTED_AT" HOMEPROXY_APPLY_DASHBOARD=1 \
		"$0" --worker </dev/null >>"$LOG_PATH" 2>&1 &
	exit 0
fi
write_result 0 || exit 1

TMP_DIR="$(mktemp -d "$RUN_DIR/resources-update.XXXXXX")" || {
	log "[RESOURCES] Failed to prepare the temporary update directory."
	finish 1
}
DASHBOARD_STAGE="${DASHBOARD_DIR}.new.$$"
RESOURCE_RESTORE_FAILED=0
trap 'rm -rf "$TMP_DIR" "$DASHBOARD_STAGE"; [ "$RESOURCE_RESTORE_FAILED" -ne 0 ] || rm -rf "$RESOURCES_DIR/.update.$$.tmp"' EXIT
trap 'finish 1 interrupted' INT TERM HUP

PHASE="geoip_cn"
write_result 0
update_rule_set "geoip_cn" "$GEOIP_SOURCE" "$GEOIP_VERSION_URL" || mark_failed "geoip_cn"
PHASE="geosite_cn"
write_result 0
update_rule_set "geosite_cn" "$GEOSITE_SOURCE" "$GEOSITE_VERSION_URL" || mark_failed "geosite_cn"
PHASE="dashboard"
write_result 0
update_dashboard || mark_failed "dashboard"

if [ -n "$FAILED_BRANCHES" ]; then
	if [ -n "$UPDATED_BRANCHES" ]; then
		log "[RESOURCES] Partially updated ($UPDATED_BRANCHES); failed branches: $FAILED_BRANCHES."
		finish 4
	fi
	log "[RESOURCES] Update failed for: $FAILED_BRANCHES."
	finish 1
fi

if [ -z "$UPDATED_BRANCHES" ]; then
	log "[RESOURCES] You're already at the latest version."
	finish 3
fi

finish 0
