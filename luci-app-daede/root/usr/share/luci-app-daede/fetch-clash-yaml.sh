#!/bin/sh
# SPDX-License-Identifier: Apache-2.0

set -eu

CHUNK_BYTES=16384
ACTION="${1:-}"

case "$ACTION" in
	chunk)
		TOKEN="${2:-}"
		INDEX="${3:-}"
		case "$TOKEN" in *[!A-Za-z0-9]*|'') exit 2 ;; esac
		case "$INDEX" in *[!0-9]*|'') exit 2 ;; esac
		FILE="/tmp/daede-clash-yaml-result.$TOKEN"
		[ -f "$FILE" ] || exit 4
		dd if="$FILE" bs="$CHUNK_BYTES" skip="$INDEX" count=1 2>/dev/null | hexdump -ve '1/1 "%02x"'
		exit 0
		;;
	cleanup)
		TOKEN="${2:-}"
		case "$TOKEN" in *[!A-Za-z0-9]*|'') exit 2 ;; esac
		rm -f "/tmp/daede-clash-yaml-result.$TOKEN"
		exit 0
		;;
esac

URL="${1:-}"
UA_MODE="${2:-auto}"
OUTPUT_MODE="${3:-stdout}"
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
FIRST="$(mktemp /tmp/daede-clash-yaml-first.XXXXXX)"
ERR="$(mktemp /tmp/daede-clash-yaml-error.XXXXXX)"
trap 'rm -f "$TMP" "$FIRST" "$ERR"' EXIT INT TERM
chmod 600 "$TMP"
chmod 600 "$FIRST"
chmod 600 "$ERR"

case "$UA_MODE" in
	auto|browser|ClashMeta|clash-verge/v2.4.2|ClashForWindows/0.20.39|Clash) ;;
	*)
		echo "Unsupported subscription User-Agent" >&2
		exit 2
		;;
esac

case "$OUTPUT_MODE" in
	stdout|handle) ;;
	*)
		echo "Unsupported output mode" >&2
		exit 2
		;;
esac

LAST_ERROR="Failed to fetch subscription"

emit_result() {
	local source="$1" result token size
	if [ "$OUTPUT_MODE" = "stdout" ]; then
		cat "$source"
		return
	fi

	# Keep each RPC response small. The browser reads this root-only temporary
	# file through the chunk action and removes it in a finally handler.
	find /tmp -maxdepth 1 -name 'daede-clash-yaml-result.*' -mmin +10 -delete 2>/dev/null || true
	result="$(mktemp /tmp/daede-clash-yaml-result.XXXXXX)"
	chmod 600 "$result"
	cp "$source" "$result"
	token="${result##*.}"
	size="$(wc -c <"$result" | tr -d ' ')"
	printf '%s\t%s\n' "$token" "$size"
}

fetch_one() {
	local ua="$1" size response_error
	if [ "$ua" = "browser" ]; then
		ua="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/131.0.0.0 Safari/537.36"
	fi
	: >"$TMP"
	: >"$ERR"
	if ! "$FETCH_BIN" -q -T 20 -U "$ua" -O "$TMP" "$URL" 2>"$ERR"; then
		response_error="$(head -c 512 "$TMP" | tr '\r\n\t' '   ')"
		LAST_ERROR="${response_error:-$(cat "$ERR")}"
		[ -n "$LAST_ERROR" ] || LAST_ERROR="Failed to fetch subscription"
		return 1
	fi

	size="$(wc -c <"$TMP" | tr -d ' ')"
	if [ "$size" -eq 0 ]; then
		LAST_ERROR="Subscription response is empty"
		return 1
	fi
	if [ "$size" -gt "$MAX_BYTES" ]; then
		LAST_ERROR="Subscription response is too large (maximum 5 MiB)"
		return 1
	fi
	return 0
}

if [ "$UA_MODE" = "auto" ]; then
	for ua in ClashMeta clash-verge/v2.4.2 ClashForWindows/0.20.39 Clash browser; do
		if fetch_one "$ua"; then
			[ -s "$FIRST" ] || cp "$TMP" "$FIRST"
			if grep -Eq '^[[:space:]]*proxies[[:space:]]*:' "$TMP"; then
				emit_result "$TMP"
				exit 0
			fi
		fi
	done
	if [ -s "$FIRST" ]; then
		emit_result "$FIRST"
		exit 0
	fi
else
	if fetch_one "$UA_MODE"; then
		emit_result "$TMP"
		exit 0
	fi
fi

echo "$LAST_ERROR" >&2
exit 3
