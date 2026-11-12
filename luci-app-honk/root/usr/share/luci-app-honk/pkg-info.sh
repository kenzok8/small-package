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
elif command -v opkg >/dev/null 2>&1; then
	# 直接读状态文件：opkg update 占着锁时 opkg status 会失败，面板就误报未安装。
	if [ -r /usr/lib/opkg/status ]; then
		installed=$(awk -v p="$PKG" '
			$1 == "Package:" { cur = $2; ver = ""; ok = 0 }
			$1 == "Version:" { ver = $2 }
			$1 == "Status:" { ok = ($NF == "installed") }
			cur == p && ok && ver != "" { print ver; exit }
		' /usr/lib/opkg/status)
	else
		installed=$(opkg status "$PKG" 2>/dev/null | awk '
			/^Version: / { version = $2 }
			/^Status: .* installed$/ { installed = 1 }
			END { if (installed) print version }
		')
	fi
	_arch=$(sed -n "s/^DISTRIB_ARCH=['\"]\(.*\)['\"].*/\1/p" /etc/openwrt_release 2>/dev/null | head -n 1)
	latest=$(
		for _list in /var/opkg-lists/*; do
			[ "${_list%.sig}" = "$_list" ] || continue
			zcat "$_list" 2>/dev/null || cat "$_list" 2>/dev/null
		done | awk -v p="$PKG" -v a="$_arch" '
			$1 == "Package:" { cur = $2; ver = ""; ok = 0 }
			cur == p && $1 == "Version:" { ver = $2 }
			cur == p && $1 == "Architecture:" { ok = (a == "" || $2 == a || $2 == "all") }
			cur == p && ok && ver != "" { print ver; ok = 0 }
		' | sort -V | tail -1
	)
fi

printf '%s\t%s\n' "$installed" "$latest"
