#!/bin/sh

[ -n "$(uci -q get clashoo.config.download_core 2>/dev/null)" ] && exit 0

raw="$(uname -m 2>/dev/null)"
[ -n "$raw" ] || raw="$(apk --print-arch 2>/dev/null)"
[ -n "$raw" ] || raw="$(opkg status libc 2>/dev/null | awk -F': ' '/^Architecture/{print $2; exit}')"
[ -n "$raw" ] || exit 0

case "$raw" in
	x86_64|amd64)          arch="amd64-compatible" ;;
	aarch64*|arm64)        arch="arm64" ;;
	armv7*|arm_cortex-a[7-9]*|arm_cortex-a1[0-9]*) arch="armv7" ;;
	armv6*|arm_cortex-a[56]*) arch="armv6" ;;
	arm*)                  arch="armv5" ;;
	i[3-6]86)              arch="386" ;;
	mips64el*)             arch="mips64le" ;;
	mips64*)               arch="mips64" ;;
	mipsel*)               arch="mipsle" ;;
	mips*)                 arch="mips" ;;
	*)                     exit 0 ;;
esac

uci -q set clashoo.config.download_core="$arch"
uci -q commit clashoo
exit 0
