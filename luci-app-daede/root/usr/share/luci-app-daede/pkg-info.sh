#!/bin/sh
# pkg-info.sh <package>
# Prints "<installed>\t<latest>\t<state>" for the named package, where either
# version is empty when unknown. Used by the Updates view to decide whether to
# enable the [Upgrade] button.
#
# Both package managers take a global lock while they install or refresh, and a
# probe that shells out to them then comes back empty: during an install the
# panel showed "not installed via package manager" for packages that were being
# installed. Read the databases directly instead, and only shell out for the
# feed index, where a failure is harmless.

PKG="$1"
case "$PKG" in
	dae|daed|luci-app-daede) ;;
	*) echo "" ; exit 64 ;;
esac

# Overridable for tests; rpcd runs this with the real paths.
APK_DB=${DAEDE_APK_DB:-/lib/apk/db/installed}
OPKG_STATUS=${DAEDE_OPKG_STATUS:-/usr/lib/opkg/status}
OPKG_LISTS=${DAEDE_OPKG_LISTS:-/var/opkg-lists}

# Highest version of a newline-separated list (busybox sort has no -V).
max_version() {
	awk '
		function cmp(a, b,   A, B, n, m, i, x, y) {
			n = split(a, A, /[.-]/)
			m = split(b, B, /[.-]/)
			for (i = 1; i <= n || i <= m; i++) {
				x = (i <= n) ? A[i] : ""
				y = (i <= m) ? B[i] : ""
				if (x ~ /^[0-9]+$/ && y ~ /^[0-9]+$/) {
					if (x + 0 != y + 0)
						return (x + 0 < y + 0) ? -1 : 1
				}
				else if (x != y) {
					return (x < y) ? -1 : 1
				}
			}
			return 0
		}
		{
			if ($0 == "") next
			if (best == "" || cmp($0, best) > 0) best = $0
		}
		END { if (best != "") print best }
	'
}

installed=""
latest=""
state="absent"

if [ -f "$APK_DB" ]; then
	# apk database: blank-line separated stanzas with "P:<name>" and "V:<version>".
	installed=$(awk -v p="$PKG" '
		BEGIN { RS = "" }
		{
			hit = 0
			n = split($0, line, "\n")
			for (i = 1; i <= n; i++) {
				if (line[i] == "P:" p) hit = 1
				else if (hit && line[i] ~ /^V:/) { print substr(line[i], 3); exit }
			}
		}
	' "$APK_DB" 2>/dev/null)
	[ -n "$installed" ] || state="absent"
	latest=$(apk list -a "$PKG" 2>/dev/null | awk -v p="$PKG" '
		$1 ~ "^" p "-[0-9]" { v = $1; sub("^" p "-", "", v); print v }
	' | max_version)
elif [ -f "$OPKG_STATUS" ]; then
	# opkg database: blank-line separated stanzas with "Package:" and "Version:".
	installed=$(awk -v p="$PKG" '
		BEGIN { RS = "" }
		{
			name = ""; ver = ""
			n = split($0, line, "\n")
			for (i = 1; i <= n; i++) {
				if (line[i] ~ /^Package: /) name = substr(line[i], 10)
				else if (line[i] ~ /^Version: /) ver = substr(line[i], 10)
			}
			if (name == p && ver != "") { print ver; exit }
		}
	' "$OPKG_STATUS" 2>/dev/null)
	# Feed indexes are gzipped lists; reading them avoids opkg's lock entirely.
	latest=$(zcat "$OPKG_LISTS"/* 2>/dev/null | awk -v p="$PKG" '
		/^Package: / { name = substr($0, 10); next }
		/^Version: / { if (name == p) print substr($0, 10) }
	' | max_version)
fi

[ -n "$installed" ] && state="managed"

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
