#!/bin/sh
# Download and install Zashboard for HONK

TARGET_DIR="${1:-/etc/honk/zashboard}"
DOWNLOAD_URL="${2:-https://github.com/Zephyruso/zashboard/releases/latest/download/dist-no-fonts.zip}"

LOG_FILE="/tmp/honk_zashboard_download.log"
STATUS_FILE="/tmp/honk_zashboard_download.status"
TMP_DIR="/tmp/zashboard_dl_$$"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

set_status() {
    echo "$1" > "$STATUS_FILE"
    log "STATUS -> $1"
}

mkdir -p /tmp
: > "$LOG_FILE"
set_status "DOWNLOADING"

log "Starting Zashboard deployment to: $TARGET_DIR"
log "Download URL: $DOWNLOAD_URL"
log "Downloading package..."

rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR"
ARCHIVE_FILE="$TMP_DIR/package.tmp"

download_file() {
    local url="$1" output="$2"
    if command -v curl >/dev/null 2>&1; then
        curl -s -S -k -L -f --connect-timeout 15 --max-time 180 -o "$output" "$url" >> "$LOG_FILE" 2>&1
    elif command -v wget >/dev/null 2>&1; then
        wget --no-check-certificate -q -T 15 -t 3 -O "$output" "$url" >> "$LOG_FILE" 2>&1
    elif command -v uclient-fetch >/dev/null 2>&1; then
        uclient-fetch --no-check-certificate -q --timeout 15 -O "$output" "$url" >> "$LOG_FILE" 2>&1
    else
        log "Error: No download tool found (curl, wget, or uclient-fetch)!"
        return 1
    fi
}

if ! download_file "$DOWNLOAD_URL" "$ARCHIVE_FILE" || [ ! -s "$ARCHIVE_FILE" ]; then
    log "Error: Download failed or file is empty."
    set_status "FAILED"
    rm -rf "$TMP_DIR"
    exit 1
fi

log "Download completed successfully. Extracting archive..."
set_status "EXTRACTING"
EXTRACT_DIR="$TMP_DIR/extracted"
mkdir -p "$EXTRACT_DIR"

if ! command -v unzip >/dev/null 2>&1; then
    log "Error: 'unzip' command not found! Please run 'opkg update && opkg install unzip'."
    set_status "FAILED"
    rm -rf "$TMP_DIR"
    exit 1
fi

if ! unzip -o -q "$ARCHIVE_FILE" -d "$EXTRACT_DIR" >> "$LOG_FILE" 2>&1; then
    log "Error: Failed to unzip archive."
    set_status "FAILED"
    rm -rf "$TMP_DIR"
    exit 1
fi

DEPLOY_SRC="$EXTRACT_DIR"
if [ ! -f "$DEPLOY_SRC/index.html" ] && [ -f "$EXTRACT_DIR/dist/index.html" ]; then
    DEPLOY_SRC="$EXTRACT_DIR/dist"
fi

if [ ! -f "$DEPLOY_SRC/index.html" ]; then
    log "Error: index.html not found in extracted package."
    set_status "FAILED"
    rm -rf "$TMP_DIR"
    exit 1
fi

log "Deploying new files to $TARGET_DIR..."
mkdir -p "$TARGET_DIR"
if [ -n "$TARGET_DIR" ] && [ "$TARGET_DIR" != "/" ] && [ "$TARGET_DIR" != "/etc" ] && [ "$TARGET_DIR" != "/tmp" ]; then
    rm -rf "${TARGET_DIR:?}"/* "${TARGET_DIR:?}"/.[!.]* 2>/dev/null || true
fi
cp -rf "$DEPLOY_SRC/"* "$TARGET_DIR/"
chmod -R 755 "$TARGET_DIR"

if [ -f "$TARGET_DIR/index.html" ]; then
    log "Installation completed successfully!"
    set_status "SUCCESS"
    rm -rf "$TMP_DIR"
    exit 0
else
    log "Error: Failed to deploy files to $TARGET_DIR."
    set_status "FAILED"
    rm -rf "$TMP_DIR"
    exit 1
fi
