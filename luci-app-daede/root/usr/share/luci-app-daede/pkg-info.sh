#!/bin/sh
# pkg-info.sh <package>
# Prints "<installed>\t<latest>\t<state>" for the named package, where either
# version is empty when unknown. Used by the Updates view to decide whether to
# enable the [Upgrade] button.

PKG="$1"
case "$PKG" in
	dae|daed|luci-app-daede) ;;
	*) echo "" ; exit 64 ;;
esac

installed=""
latest=""
state="absent"

if command -v apk >/dev/null 2>&1; then
	if apk info -e "$PKG" >/dev/null 2>&1; then
		state="managed"
		installed=$(apk list -I "$PKG" 2>/dev/null | awk -v p="$PKG" '
			$1 ~ "^" p "-[0-9]" {
				sub("^" p "-", "", $1);
				print $1;
				exit
			}
		')
		[ -n "$installed" ] || state="error"
	fi
	# apk search treats ^ and $ as literal chars (not regex anchors), so the old
	# `apk search "^pkg$"` matched nothing. Enumerate the exact-name package
	# across configured feeds via `apk list -a` and take the highest version.
	# The -a flag excludes locally installed packages that are absent from feeds.
	# Restricting to "<pkg>-<digit>" avoids sibling names like <pkg>-geoip.
	latest=$(apk list -a "$PKG" 2>/dev/null | awk -v p="$PKG" '
		$1 ~ "^" p "-[0-9]" {
			v = $1; sub("^" p "-", "", v);
			print v
		}
	' | sort -V | tail -1)
elif command -v opkg >/dev/null 2>&1; then
	installed=$(opkg status "$PKG" 2>/dev/null | awk -F': ' '$1=="Version"{print $2; exit}')
	latest=$(opkg info "$PKG" 2>/dev/null | awk -F': ' '$1=="Version"{print $2; exit}')
	[ -n "$installed" ] && state="managed"
fi

case "$PKG" in
	dae|daed)
		case "$installed" in
			20[0-9][0-9].[0-9]*) ;;
			*) [ -n "$installed" ] && state="foreign"; installed="" ;;
		esac
		;;
esac

if [ "$state" = "absent" ]; then
	case "$PKG" in
		dae|daed) [ -x "/usr/bin/$PKG" ] && state="manual" ;;
	esac
fi

printf '%s\t%s\t%s\n' "$installed" "$latest" "$state"
