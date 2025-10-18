#!/bin/sh

. /usr/share/libubox/jshn.sh

CONF="fchomo"

RESOURCES_DIR="/etc/$CONF/resources"
VER_PATH="/etc/$CONF/resources.json"
mkdir -p "$RESOURCES_DIR"

RUN_DIR="/var/run/$CONF"
LOG_PATH="$RUN_DIR/$CONF.log"
mkdir -p "$RUN_DIR"

log() {
	echo -e "$(date "+%F %T") $*" >> "$LOG_PATH"
}

to_upper() {
	echo -e "$1" | tr "[a-z]" "[A-Z]"
}

get_local_ver() {
	local type="$1"
	local repoid="$2"

	local ver
	if [ -n "$repoid" ]; then
		ver="$(eval "jsonfilter -qi \"$VER_PATH\" -e '@[\"$type\"][\"$repoid\"].version'")"
	else
		ver="$(eval "jsonfilter -qi \"$VER_PATH\" -e '@[\"$type\"]'")"
	fi

	[ -n "$ver" ] && echo "$ver" || return 1
}

check_dashboard_update() {
	local dashtype="$1"
	local dashrepo="$2"
	local dashrepoid="$(echo -n "$dashrepo" | sed 's|\W|_|g' | tr 'A-Z' 'a-z')"
	local lock="$RUN_DIR/update_resources-$dashtype.lock"
	local wget="wget --tries=1 --timeout=10 -q"

	exec 200>"$lock"
	if ! flock -n 200 &> "/dev/null"; then
		log "[$(to_upper "$dashtype")] A task is already running."
		return 2
	fi

	local dash_ver="$($wget -O- "https://api.github.com/repos/$dashrepo/releases/latest" | jsonfilter -e "@.tag_name" 2>/dev/null)"
	[ -n "$dash_ver" ] || {
		dash_ver="$($wget -O- "https://api.github.com/repos/$dashrepo/tags" | jsonfilter -e "@[*].name" | head -n1)"
	}
	if [ -z "$dash_ver" ]; then
		log "[$(to_upper "$dashtype")] [$dashrepo] Failed to get the latest version, please retry later."
		return 1
	fi

	local local_dash_ver="$(get_local_ver "$dashtype" "$dashrepoid" || echo "NOT FOUND")"
	if [ "$local_dash_ver" = "$dash_ver" ]; then
		log "[$(to_upper "$dashtype")] [$dashrepo] Current version: $dash_ver."
		log "[$(to_upper "$dashtype")] [$dashrepo] You're already at the latest version."
		return 3
	else
		log "[$(to_upper "$dashtype")] [$dashrepo] Local version: $local_dash_ver, latest version: $dash_ver."
	fi

	if ! $wget "https://codeload.github.com/$dashrepo/tar.gz/refs/heads/gh-pages" -O "$RUN_DIR/$dashtype.tgz" || ! tar -tzf "$RUN_DIR/$dashtype.tgz" >/dev/null; then
		rm -f "$RUN_DIR/$dashtype.tgz"
		log "[$(to_upper "$dashtype")] [$dashrepo] Update failed."
		return 1
	fi

	mv -f "$RUN_DIR/$dashtype.tgz" "$RESOURCES_DIR/$dashrepoid.tgz"
	touch "$VER_PATH"
	json_init
	json_load_file "$VER_PATH"
	json_select "$dashtype" 2>/dev/null || json_add_object "$dashtype"
	json_select "$dashrepoid" 2>/dev/null || json_add_object "$dashrepoid"
	json_add_string repo "$dashrepo"
	json_add_string version "$dash_ver"
	json_dump > "$VER_PATH"
	log "[$(to_upper "$dashtype")] [$dashrepo] Successfully updated."
	return 0
}

# Reference from homeproxy
check_geodata_update() {
	local geotype="$1"
	local georepo="$2"
	local lock="$RUN_DIR/update_resources-$geotype.lock"
	local wget="wget --tries=1 --timeout=10 -q"

	exec 200>"$lock"
	if ! flock -n 200 &> "/dev/null"; then
		log "[$(to_upper "$geotype")] A task is already running."
		return 2
	fi

	local geodata_ver="$($wget -O- "https://api.github.com/repos/$georepo/releases/latest" | jsonfilter -e "@.tag_name")"
	if [ -z "$geodata_ver" ]; then
		log "[$(to_upper "$geotype")] Failed to get the latest version, please retry later."
		return 1
	fi

	local local_geodata_ver="$(get_local_ver "$geotype" || echo "NOT FOUND")"
	if [ "$local_geodata_ver" = "$geodata_ver" ]; then
		log "[$(to_upper "$geotype")] Current version: $geodata_ver."
		log "[$(to_upper "$geotype")] You're already at the latest version."
		return 3
	else
		log "[$(to_upper "$geotype")] Local version: $local_geodata_ver, latest version: $geodata_ver."
	fi

	local geodata_hash
	$wget "https://github.com/$georepo/releases/download/$geodata_ver/$geotype.dat" -O "$RUN_DIR/$geotype.dat"
	geodata_hash="$($wget -O- "https://github.com/$georepo/releases/download/$geodata_ver/$geotype.dat.sha256sum" | awk '{print $1}')"
	if ! echo -e "$geodata_hash $RUN_DIR/$geotype.dat" | sha256sum -s -c -; then
		rm -f "$RUN_DIR/$geotype.dat"
		log "[$(to_upper "$geotype")] Update failed."
		return 1
	fi

	mv -f "$RUN_DIR/$geotype.dat" "$RESOURCES_DIR/../$geotype.dat"
	touch "$VER_PATH"
	json_init
	json_load_file "$VER_PATH"
	json_add_string "$geotype" "$geodata_ver"
	json_dump > "$VER_PATH"
	log "[$(to_upper "$geotype")] Successfully updated."
	return 0
}

# Reference from homeproxy
check_list_update() {
	local listtype="$1"
	local listrepo="$2"
	local listref="$3"
	local listname="$4"
	local lock="$RUN_DIR/update_resources-$listtype.lock"
	local wget="wget --tries=1 --timeout=10 -q"

	exec 200>"$lock"
	if ! flock -n 200 &> "/dev/null"; then
		log "[$(to_upper "$listtype")] A task is already running."
		return 2
	fi

	local list_info="$($wget -O- "https://api.github.com/repos/$listrepo/commits?sha=$listref&path=$listname")"
	local list_sha="$(echo -e "$list_info" | jsonfilter -e "@[0].sha")"
	local list_ver="$(echo -e "$list_info" | jsonfilter -e "@[0].commit.message" | grep -Eo "[0-9-]+" | tr -d '-')"
	if [ -z "$list_sha" ] || [ -z "$list_ver" ]; then
		log "[$(to_upper "$listtype")] Failed to get the latest version, please retry later."
		return 1
	fi

	local local_list_ver="$(get_local_ver "$listtype" || echo "NOT FOUND")"
	if [ "$local_list_ver" = "$list_ver" ]; then
		log "[$(to_upper "$listtype")] Current version: $list_ver."
		log "[$(to_upper "$listtype")] You're already at the latest version."
		return 3
	else
		log "[$(to_upper "$listtype")] Local version: $local_list_ver, latest version: $list_ver."
	fi

	if ! $wget "https://fastly.jsdelivr.net/gh/$listrepo@$list_sha/$listname" -O "$RUN_DIR/$listname" || [ ! -s "$RUN_DIR/$listname" ]; then
		rm -f "$RUN_DIR/$listname"
		log "[$(to_upper "$listtype")] Update failed."
		return 1
	fi

	mv -f "$RUN_DIR/$listname" "$RESOURCES_DIR/$listtype.${listname##*.}"
	touch "$VER_PATH"
	json_init
	json_load_file "$VER_PATH"
	json_add_string "$listtype" "$list_ver"
	json_dump > "$VER_PATH"
	log "[$(to_upper "$listtype")] Successfully updated."
	return 0
}

case "$1" in
"ALL")
	# Since the VER_PATH lock is not designed, parallelism is not currently supported.
	for _type in geoip geosite asn china_ip4 china_ip6 gfw_list china_list; do
		"$0" "$_type"
	done
	# dashboard
	_repos="$(jsonfilter -qi "$VER_PATH" -e '@.dashboard[*].repo')"
	if [ -n "$_repos" ]; then
		for i in $(echo "$_repos" | sed -n '='); do
			"$0" "dashboard" "$(echo "$_repos" | sed -n "${i}p")"
		done
	else
		"$0" "dashboard"
	fi
	;;
"dashboard")
	check_dashboard_update "$1" "${2:-MetaCubeX/metacubexd}"
	;;
"geoip")
	check_geodata_update "$1" "Loyalsoldier/v2ray-rules-dat"
	;;
"geosite")
	check_geodata_update "$1" "Loyalsoldier/v2ray-rules-dat"
	;;
"asn")
	check_list_update "$1" "Loyalsoldier/geoip" "release" "GeoLite2-ASN.mmdb" &&
		mv -f "$RESOURCES_DIR/asn.mmdb" "$RESOURCES_DIR/../asn.mmdb"
	;;
"china_ip4")
	check_list_update "$1" "fcshark-org/route-list" "release" "china_ipv4.txt"
	;;
"china_ip6")
	check_list_update "$1" "fcshark-org/route-list" "release" "china_ipv6.txt"
	;;
"gfw_list")
	check_list_update "$1" "fcshark-org/route-list" "release" "gfwlist.txt"
	;;
"china_list")
	check_list_update "$1" "fcshark-org/route-list" "release" "china_list2.txt"
	;;
*)
	echo -e "Usage: $0 <ALL / dashboard / geoip / geosite / asn / china_ip4 / china_ip6 / gfw_list / china_list>"
	exit 1
	;;
esac
