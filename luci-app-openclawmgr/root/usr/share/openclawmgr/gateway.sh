#!/bin/sh
set -eu
umask 077
[ "$(id -u)" -gt 0 ] || { echo "Gateway requires its dedicated non-root user" >&2; exit 126; }
base="$1"
shift
node="$base/node/bin/node"
cd "$base/data"
if [ -f "$base/current/runtime.json" ]; then
	# procd has already selected the service UID. Prove native/vector support
	# under that identity before executing the gateway, on every restart.
	probe="$base/data/.openclaw/runtime-native.json.$$"
	trap 'rm -f "$probe"' EXIT
	timeout -k 2 60 "$node" /usr/share/openclawmgr/runtime-check.cjs native \
		"$base/global" "$base/current/receipt.json" > "$probe"
	mv -f "$probe" "$base/data/.openclaw/runtime-native.json"
fi
exec "$node" "$@"
