#!/bin/sh
# SPDX-License-Identifier: GPL-3.0-only

honk_add_log_lines() {
	[ -s "$1" ] || return 0
	while IFS= read -r line; do
		json_add_string "" "$line"
	done < "$1"
}
