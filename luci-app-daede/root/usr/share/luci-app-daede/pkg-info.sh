#!/bin/sh
# pkg-info.sh <package>
# Prints "<installed>\t<latest>" for the named package, where either field is
# empty when unknown. Used by the Updates view to decide whether to enable
# the [Upgrade] button.

PKG="$1"
case "$PKG" in
	dae|daed|luci-app-daede) ;;
	*) echo "" ; exit 64 ;;
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
	# apk search treats ^ and $ as literal chars (not regex anchors), so the old
	# `apk search "^pkg$"` matched nothing. Enumerate the exact-name package
	# across all feeds via `apk list` and take the highest version. Restricting
	# to "<pkg>-<digit>" avoids sibling names like <pkg>-geoip / luci-app-<pkg>.
	latest=$(apk list "$PKG" 2>/dev/null | awk -v p="$PKG" '
		$1 ~ "^" p "-[0-9]" {
			v = $1; sub("^" p "-", "", v);
			print v
		}
	' | sort -V | tail -1)
elif command -v opkg >/dev/null 2>&1; then
	installed=$(opkg status "$PKG" 2>/dev/null | awk -F': ' '$1=="Version"{print $2; exit}')
	latest=$(opkg info "$PKG" 2>/dev/null | awk -F': ' '$1=="Version"{print $2; exit}')
fi

case "$PKG" in
	dae|daed)
		case "$installed" in
			20[0-9][0-9].[0-9]*) ;;
			*) installed="" ;;
		esac
		;;
esac

printf '%s\t%s\n' "$installed" "$latest"
