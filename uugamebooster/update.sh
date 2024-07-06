#!/bin/bash
# SPDX-License-Identifier: GPL-3.0-only
#
# Copyright (C) 2021 ImmortalWrt.org

set -x

export CURDIR="$(cd "$(dirname $0)"; pwd)"

VERSION="$(curl -fsSL "https://router.uu.163.com/api/plugin?type=openwrt-aarch64" | jq -r ".url" | awk -F '/' '{print $6}' | tr -d 'v')" || exit 1
PKG_VERSION="$(awk -F "PKG_VERSION:=" '{print $2}' "$CURDIR/Makefile" | xargs)"
[ "$PKG_VERSION" != "$VERSION" ] || exit 0

for ARCH in "aarch64" "arm" "mipsel" "x86_64"; do
	FILE_INFO="$(curl -fsSL "https://router.uu.163.com/api/plugin?type=openwrt-$ARCH")"
	FILE_MD5="$(echo "$FILE_INFO" | jq -r ".md5")"
	FILE_VER="$(echo "$FILE_INFO" | jq -r ".url" | awk -F '/' '{print $6}' | tr -d 'v')"
	if [ "$FILE_VER" != "$VERSION" ]; then
		echo -e "Version mismatch. Expected version: $VERSION, got $FILE_VER."
		exit 1
	else
		curl -fsSL "https://uu.gdl.netease.com/uuplugin/openwrt-$ARCH/v$VERSION/uu.tar.gz" -o "$CURDIR/uu-$ARCH.tar.gz"
		ACTUAL_MD5="$(md5sum "$CURDIR/uu-$ARCH.tar.gz" | awk '{print $1}')"
		if [ "$ACTUAL_MD5" != "$FILE_MD5" ]; then
			echo -e "HASH mismatch. Expected md5: $FILE_MD5, got $ACTUAL_MD5."
		else
			FILE_HASH="$(sha256sum "$CURDIR/uu-$ARCH.tar.gz" | awk '{print $1}')"
			HASH_LINE="$(($(sed -n -e "/(\$(ARCH),$ARCH)/=" "$CURDIR/Makefile") + 1))"
			sed -i "${HASH_LINE}s/PKG_HASH:=.*/PKG_HASH:=$FILE_HASH/" "$CURDIR/Makefile"
		fi
		rm -f "$CURDIR/uu-$ARCH.tar.gz"
	fi
done

sed -i "s,PKG_VERSION:=.*,PKG_VERSION:=$VERSION,g" "$CURDIR/Makefile"
