#!/bin/sh
# SPDX-License-Identifier: GPL-2.0-only
#
# Copyright (C) 2022-2023 ImmortalWrt.org

. /usr/share/libubox/jshn.sh

NAME="homeproxy"

RESOURCES_DIR="/etc/$NAME/resources"
mkdir -p "$RESOURCES_DIR"

RUN_DIR="/var/run/$NAME"
LOG_PATH="$RUN_DIR/$NAME.log"
mkdir -p "$RUN_DIR"

log() {
	echo -e "$(date "+%Y-%m-%d %H:%M:%S") $*" >> "$LOG_PATH"
}

set_lock() {
	local act="$1"
	local type="$2"

	local lock="$RUN_DIR/update_resources-$type.lock"
	if [ "$act" = "set" ]; then
		if [ -e "$lock" ]; then
			log "[$(to_upper "$type")] A task is already running."
			exit 2
		else
			touch "$lock"
		fi
	elif [ "$act" = "remove" ]; then
		rm -f "$lock"
	fi
}

to_upper() {
	echo -e "$1" | tr "[a-z]" "[A-Z]"
}

get_local_vers() {
	local ver_file="$1"
	local repoid="$2"

	local ver="$(eval "jsonfilter -qi \"$ver_file\" -e '@[\"$repoid\"].version'")"
	[ -n "$ver" ] && echo "$ver" || return 1
}

check_clash_dashboard_update() {
	local dashtype="$1"
	local dashrepo="$2"
	local dashrepoid="$(echo -n "$dashrepo" | md5sum | cut -f1 -d' ')"
	local wget="wget --timeout=10 -q"

	set_lock "set" "$dashtype"

	local dashdata_ver="$($wget -O- "https://api.github.com/repos/$dashrepo/releases/latest" | jsonfilter -e "@.tag_name")"
	[ -n "$dashdata_ver" ] || {
		dashdata_ver="$($wget -O- "https://api.github.com/repos/$dashrepo/tags" | jsonfilter -e "@[*].name" | head -n1)"
	}
	if [ -z "$dashdata_ver" ]; then
		log "[$(to_upper "$dashtype")] [$dashrepo] Failed to get the latest version, please retry later."

		set_lock "remove" "$dashtype"
		return 1
	fi

	local local_dashdata_ver="$(get_local_vers "$RESOURCES_DIR/$dashtype.ver" "$dashrepoid" || echo "NOT FOUND")"
	if [ "$local_dashdata_ver" = "$dashdata_ver" ]; then
		log "[$(to_upper "$dashtype")] [$dashrepo] Current version: $dashdata_ver."
		log "[$(to_upper "$dashtype")] [$dashrepo] You're already at the latest version."

		set_lock "remove" "$dashtype"
		return 3
	else
		log "[$(to_upper "$dashtype")] [$dashrepo] Local version: $local_dashdata_ver, latest version: $dashdata_ver."
	fi

	$wget "https://codeload.github.com/$dashrepo/zip/refs/heads/gh-pages" -O "$RUN_DIR/$dashtype.zip"
	if [ ! -s "$RUN_DIR/$dashtype.zip" ]; then
		rm -f "$RUN_DIR/$dashtype.zip"
		log "[$(to_upper "$dashtype")] [$dashrepo] Update failed."

		set_lock "remove" "$dashtype"
		return 1
	fi

	mv -f "$RUN_DIR/$dashtype.zip" "$RESOURCES_DIR/${dashrepo//\//_}.zip"
	touch "$RESOURCES_DIR/$dashtype.ver"
	json_init
	json_load_file "$RESOURCES_DIR/$dashtype.ver"
	json_select "$dashrepoid" 2>/dev/null || json_add_object "$dashrepoid"
	json_add_string repo "$dashrepo"
	json_add_string version "$dashdata_ver"
	json_dump > "$RESOURCES_DIR/$dashtype.ver"
	log "[$(to_upper "$dashtype")] [$dashrepo] Successfully updated."

	set_lock "remove" "$dashtype"
	return 0
}

check_list_update() {
	local listtype="$1"
	local listrepo="$2"
	local listref="$3"
	local listname="$4"
	local wget="wget --timeout=10 -q"

	set_lock "set" "$listtype"

	local list_info="$($wget -O- "https://api.github.com/repos/$listrepo/commits?sha=$listref&path=$listname")"
	local list_sha="$(echo -e "$list_info" | jsonfilter -e "@[0].sha")"
	local list_ver="$(echo -e "$list_info" | jsonfilter -e "@[0].commit.message" | grep -Eo "[0-9-]+" | tr -d '-')"
	if [ -z "$list_sha" ] || [ -z "$list_ver" ]; then
		log "[$(to_upper "$listtype")] Failed to get the latest version, please retry later."

		set_lock "remove" "$listtype"
		return 1
	fi

	local local_list_ver="$(cat "$RESOURCES_DIR/$listtype.ver" 2>"/dev/null" || echo "NOT FOUND")"
	if [ "$local_list_ver" = "$list_ver" ]; then
		log "[$(to_upper "$listtype")] Current version: $list_ver."
		log "[$(to_upper "$listtype")] You're already at the latest version."

		set_lock "remove" "$listtype"
		return 3
	else
		log "[$(to_upper "$listtype")] Local version: $local_list_ver, latest version: $list_ver."
	fi

	$wget "https://fastly.jsdelivr.net/gh/$listrepo@$list_sha/$listname" -O "$RUN_DIR/$listname"
	if [ ! -s "$RUN_DIR/$listname" ]; then
		rm -f "$RUN_DIR/$listname"
		log "[$(to_upper "$listtype")] Update failed."

		set_lock "remove" "$listtype"
		return 1
	fi

	mv -f "$RUN_DIR/$listname" "$RESOURCES_DIR/$listtype.${listname##*.}"
	echo -e "$list_ver" > "$RESOURCES_DIR/$listtype.ver"
	log "[$(to_upper "$listtype")] Successfully updated."

	set_lock "remove" "$listtype"
	return 0
}

case "$1" in
"clash_dashboard")
	check_clash_dashboard_update "$1" "$2"
	;;
"china_ip4")
	check_list_update "$1" "1715173329/IPCIDR-CHINA" "master" "ipv4.txt"
	;;
"china_ip6")
	check_list_update "$1" "1715173329/IPCIDR-CHINA" "master" "ipv6.txt"
	;;
"gfw_list")
	check_list_update "$1" "Loyalsoldier/v2ray-rules-dat" "release" "gfw.txt"
	;;
"china_list")
	check_list_update "$1" "Loyalsoldier/v2ray-rules-dat" "release" "direct-list.txt" && \
		sed -i -e "s/full://g" -e "/:/d" "$RESOURCES_DIR/china_list.txt"
	;;
*)
	echo -e "Usage: $0 <clash_dashboard / china_ip4 / china_ip6 / gfw_list / china_list>"
	exit 1
	;;
esac
