#!/bin/sh
set -eu

DATA_DIR=${DATA_DIR:-/mnt/baidudrive/data}
BAIDU_NAS_HOST=${BAIDU_NAS_HOST:-127.0.0.1}
BAIDU_NAS_PORT=${BAIDU_NAS_PORT:-8001}
BAIDU_NAS_USB_PATH=${BAIDU_NAS_USB_PATH:-/mnt}
BAIDU_NAS_QUOTA_PATH=${BAIDU_NAS_QUOTA_PATH:-$BAIDU_NAS_USB_PATH}
LOG_FILE="$DATA_DIR/sdk-init.log"

mkdir -p "$DATA_DIR"

log() {
	printf '%s %s\n' "$(date -Iseconds 2>/dev/null || date)" "$*" >> "$LOG_FILE"
}

while true; do
	token=$(sed -n 's/.*"access_token"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$DATA_DIR/session.json" 2>/dev/null | head -n 1)
	if [ -z "$token" ]; then
		log "session token not ready"
		sleep 2
		continue
	fi

	set -- $(df -m "$BAIDU_NAS_QUOTA_PATH" | awk 'NR==2 {print $2, $4}')
	total=${1:-0}
	free=${2:-0}
	sdk_ready=1

	register_response=$(curl -fsS --max-time 10 -G \
		--data-urlencode "access_token=$token" \
		"http://$BAIDU_NAS_HOST:$BAIDU_NAS_PORT/register" 2>/dev/null || true)
	if printf '%s' "$register_response" | grep -F '"errno":0' >/dev/null; then
		device_id=$(printf '%s' "$register_response" | sed -n 's/.*"device_id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1)
		log "register ok device_id=${device_id:-unknown}"
	else
		log "register failed"
		sdk_ready=0
	fi

	if curl -fsS --max-time 10 -G \
		--data-urlencode "type=quota" \
		--data-urlencode "path=$BAIDU_NAS_USB_PATH" \
		--data-urlencode "free=$free" \
		--data-urlencode "total=$total" \
		"http://$BAIDU_NAS_HOST:$BAIDU_NAS_PORT/event" >/dev/null 2>&1; then
		log "quota ok path=$BAIDU_NAS_USB_PATH total=${total} free=${free}"
	else
		log "quota failed"
		sdk_ready=0
	fi

	if curl -fsS --max-time 10 -G \
		--data-urlencode "type=usbIn" \
		--data-urlencode "path=$BAIDU_NAS_USB_PATH" \
		"http://$BAIDU_NAS_HOST:$BAIDU_NAS_PORT/event" >/dev/null 2>&1; then
		log "usbIn ok path=$BAIDU_NAS_USB_PATH"
	else
		log "usbIn failed"
		sdk_ready=0
	fi

	if [ "$sdk_ready" = "1" ]; then
		log "sdk init ready"
		sleep 60
	else
		sleep 2
	fi
done
