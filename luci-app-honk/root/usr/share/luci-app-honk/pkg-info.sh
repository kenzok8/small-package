#!/bin/sh
# SPDX-License-Identifier: GPL-3.0-only
# pkg-info.sh <honk|luci-app-honk>
# Prints "<installed>\t<latest>" for the named package, either field empty when
# unknown. Used by the Maintenance view to decide whether to enable [升级].

PKG="$1"
case "$PKG" in
	honk|luci-app-honk) ;;
	*) printf '\t\n'; exit 64 ;;
esac

installed=""
latest=""

if command -v apk >/dev/null 2>&1; then
	if apk info -e "$PKG" >/dev/null 2>&1; then
		installed=$(apk list -I "$PKG" 2>/dev/null | awk -v p="$PKG" '
			$1 ~ "^" p "-" {
				sub("^" p "-", "", $1);
				print $1;
				exit
			}
		')
	fi
	latest=$(apk list "$PKG" 2>/dev/null | awk -v p="$PKG" '
		$1 ~ "^" p "-[0-9]" {
			v = $1; sub("^" p "-", "", v);
			print v
		}
	' | sort -V | tail -1)
fi

printf '%s\t%s\n' "$installed" "$latest"
