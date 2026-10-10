#!/bin/sh

MODEL_PATH="/etc/clashoo/Model.bin"
TMP_PATH="/tmp/clash_Model.bin"
LOG_FILE="/tmp/lgbm_update.log"

log() {
	echo "  $(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

: > "$LOG_FILE"

DOWNLOAD_URL=$(uci get clashoo.config.smart_lgbm_url 2>/dev/null)
[ -z "$DOWNLOAD_URL" ] && DOWNLOAD_URL="https://github.com/vernesong/mihomo/releases/download/LightGBM-Model/Model.bin"

log "Start downloading LightGBM model from: $DOWNLOAD_URL"

mkdir -p /etc/clashoo

rm -f "$TMP_PATH" 2>/dev/null
if command -v curl >/dev/null 2>&1; then
	curl -fL --connect-timeout 15 --max-time 120 -A "Clash/OpenWRT" "$DOWNLOAD_URL" -o "$TMP_PATH" 2>/dev/null
	dl_rc=$?
elif command -v wget >/dev/null 2>&1; then
	wget -q --timeout=30 -U "Clash/OpenWRT" "$DOWNLOAD_URL" -O "$TMP_PATH" 2>/dev/null
	dl_rc=$?
else
	log "No curl or wget found"
	exit 1
fi

if [ "$dl_rc" -ne 0 ] || [ ! -s "$TMP_PATH" ]; then
	log "Download failed (rc=$dl_rc)"
	rm -f "$TMP_PATH"
	exit 1
fi

if [ -f "$MODEL_PATH" ] && cmp -s "$TMP_PATH" "$MODEL_PATH"; then
	log "Model unchanged, no update needed"
	rm -f "$TMP_PATH"
	exit 0
fi

mv "$TMP_PATH" "$MODEL_PATH" 2>/dev/null
if [ $? -ne 0 ]; then
	log "Failed to install model to $MODEL_PATH"
	rm -f "$TMP_PATH"
	exit 1
fi

log "LightGBM model updated successfully"
exit 0
