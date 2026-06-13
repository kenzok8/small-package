#!/bin/sh
# SPDX-License-Identifier: Apache-2.0

set -eu

URL="${1:-}"
MAX_BYTES=5242880
FETCH_BIN="${DAEDE_FETCH_BIN:-uclient-fetch}"

case "$URL" in
	http://*|https://*) ;;
	*)
		echo "Subscription URL must use HTTP or HTTPS" >&2
		exit 2
		;;
esac

TMP="$(mktemp /tmp/daede-clash-yaml.XXXXXX)"
trap 'rm -f "$TMP"' EXIT INT TERM
chmod 600 "$TMP"

if ! "$FETCH_BIN" -q -T 20 -U "ClashMeta" -O "$TMP" "$URL"; then
	echo "Failed to fetch subscription" >&2
	exit 3
fi

SIZE="$(wc -c <"$TMP" | tr -d ' ')"
if [ "$SIZE" -eq 0 ]; then
	echo "Subscription response is empty" >&2
	exit 4
fi
if [ "$SIZE" -gt "$MAX_BYTES" ]; then
	echo "Subscription response is too large (maximum 5 MiB)" >&2
	exit 5
fi

cat "$TMP"
