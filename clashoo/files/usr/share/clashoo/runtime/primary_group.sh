#!/bin/sh

clashoo_resolve_primary_group() {
	local config_yaml="$1"
	local cached_group="$2"
	local group_rows
	local resolved_group

	if [ "$cached_group" = "GLOBAL" ]; then
		printf '%s\n' "GLOBAL"
		return 0
	fi

	if [ ! -f "$config_yaml" ] || ! command -v yq >/dev/null 2>&1; then
		printf '%s\n' "GLOBAL"
		return 0
	fi

	group_rows="$(yq -M e -r '(."proxy-groups" // [])[] | [.name, .type] | @tsv' "$config_yaml" 2>/dev/null)" || {
		printf '%s\n' "GLOBAL"
		return 0
	}

	if [ -n "$cached_group" ] && printf '%s\n' "$group_rows" |
		awk -F '\t' -v wanted="$cached_group" '$1 == wanted { found = 1; exit } END { exit !found }'
	then
		printf '%s\n' "$cached_group"
		return 0
	fi

	resolved_group="$(printf '%s\n' "$group_rows" | awk -F '\t' '
		tolower($2) == "select" &&
		(index($1, "节点选择") || index($1, "代理") || index($1, "🚀") || tolower($1) ~ /proxy/) {
			print $1
			exit
		}
	')"

	if [ -z "$resolved_group" ]; then
		resolved_group="$(printf '%s\n' "$group_rows" | awk -F '\t' '
			tolower($2) == "select" {
				print $1
				exit
			}
		')"
	fi

	printf '%s\n' "${resolved_group:-GLOBAL}"
}
