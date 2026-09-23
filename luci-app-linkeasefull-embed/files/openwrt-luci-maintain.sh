#!/bin/sh

set -eu

ACTION=${1:-}
ROOT=${2:-}
PRIVATE_DIR=/usr/share/linkeasefull/openwrt-luci/protocol-fallbacks
PUBLIC_DIR=/www/luci-static/resources/protocol

case "$ROOT" in
	""|/*) ;;
	*) echo "invalid root: $ROOT" >&2; exit 2 ;;
esac
case "/$ROOT/" in
	*/../*) echo "invalid root: $ROOT" >&2; exit 2 ;;
esac

install_fallbacks() {
	mkdir -p "$ROOT$PUBLIC_DIR"
	for name in bonding.js directip.js wwan.js; do
		source="$ROOT$PRIVATE_DIR/$name"
		destination="$ROOT$PUBLIC_DIR/$name"
		[ -f "$source" ] || continue
		if [ ! -e "$destination" ] && [ ! -L "$destination" ]; then
			ln -s "$PRIVATE_DIR/$name" "$destination"
		fi
	done
}

remove_fallbacks() {
	for name in bonding.js directip.js wwan.js; do
		destination="$ROOT$PUBLIC_DIR/$name"
		if [ "$(readlink "$destination" 2>/dev/null || true)" = "$PRIVATE_DIR/$name" ]; then
			rm -f "$destination"
		fi
	done
}

case "$ACTION" in
	install) install_fallbacks ;;
	remove) remove_fallbacks ;;
	*) echo "usage: $0 {install|remove} [root]" >&2; exit 2 ;;
esac
