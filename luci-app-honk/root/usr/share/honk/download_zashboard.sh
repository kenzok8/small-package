#!/bin/sh
# Download and install Zashboard (no-fonts lightweight edition) for HONK

TARGET_DIR="${1:-/etc/honk/zashboard}"
DOWNLOAD_URL="${2:-https://github.com/Zephyruso/zashboard/releases/latest/download/dist-no-fonts.zip}"

LOG_FILE="/tmp/honk_zashboard_download.log"
STATUS_FILE="/tmp/honk_zashboard_download.status"
TMP_DIR="/tmp/zashboard_dl_$$"

log() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] $1"
    echo "$msg" >> "$LOG_FILE"
}

set_status() {
    echo "$1" > "$STATUS_FILE"
    log "STATUS -> $1"
}

# Initialize files
mkdir -p /tmp
: > "$LOG_FILE"
set_status "DOWNLOADING"

log "=================================================="
log "Starting Zashboard deployment..."
log "Target installation directory: $TARGET_DIR"
log "Download URL: $DOWNLOAD_URL"
log "=================================================="

# Create clean temp dir in /tmp (tmpfs RAM)
rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR"

ARCHIVE_FILE="$TMP_DIR/package.tmp"

# Downloader helper: curl -> wget -> uclient-fetch
download_file() {
    local url="$1"
    local output="$2"
    log "Fetching archive from network..."
    if command -v curl >/dev/null 2>&1; then
        log "Using curl..."
        curl -k -L -f --connect-timeout 15 --max-time 180 -o "$output" "$url" >> "$LOG_FILE" 2>&1
    elif command -v wget >/dev/null 2>&1; then
        log "Using wget..."
        wget --no-check-certificate -T 15 -t 3 -O "$output" "$url" >> "$LOG_FILE" 2>&1
    elif command -v uclient-fetch >/dev/null 2>&1; then
        log "Using uclient-fetch..."
        uclient-fetch --no-check-certificate --timeout 15 -O "$output" "$url" >> "$LOG_FILE" 2>&1
    else
        log "Error: No download tool found (curl, wget, or uclient-fetch)!"
        return 1
    fi
}

if ! download_file "$DOWNLOAD_URL" "$ARCHIVE_FILE"; then
    log "Error: Download failed! Please check network connectivity or choose a mirror."
    set_status "FAILED"
    rm -rf "$TMP_DIR"
    exit 1
fi

if [ ! -s "$ARCHIVE_FILE" ]; then
    log "Error: Downloaded file is empty or missing."
    set_status "FAILED"
    rm -rf "$TMP_DIR"
    exit 1
fi

FILE_SIZE=$(wc -c < "$ARCHIVE_FILE" 2>/dev/null || echo "0")
log "Download successful. Archive size: $((FILE_SIZE / 1024)) KB"

set_status "EXTRACTING"
EXTRACT_DIR="$TMP_DIR/extracted"
mkdir -p "$EXTRACT_DIR"

# Extract archive: zip or tar.gz
case "$DOWNLOAD_URL" in
    *.tar.gz|*.tgz)
        log "Extracting tar.gz archive with tar..."
        tar -xzf "$ARCHIVE_FILE" -C "$EXTRACT_DIR" >> "$LOG_FILE" 2>&1
        ;;
    *)
        if command -v unzip >/dev/null 2>&1; then
            log "Extracting zip archive with unzip..."
            unzip -o -q "$ARCHIVE_FILE" -d "$EXTRACT_DIR" >> "$LOG_FILE" 2>&1
        else
            log "Error: 'unzip' command not found! Please run 'opkg update && opkg install unzip'."
            set_status "FAILED"
            rm -rf "$TMP_DIR"
            exit 1
        fi
        ;;
esac

# Locate index.html
DEPLOY_SRC=""
if [ -f "$EXTRACT_DIR/index.html" ]; then
    DEPLOY_SRC="$EXTRACT_DIR"
elif [ -f "$EXTRACT_DIR/dist/index.html" ]; then
    DEPLOY_SRC="$EXTRACT_DIR/dist"
else
    # Check subdirectories
    for d in "$EXTRACT_DIR"/*; do
        if [ -d "$d" ] && [ -f "$d/index.html" ]; then
            DEPLOY_SRC="$d"
            break
        fi
    done
fi

if [ -z "$DEPLOY_SRC" ]; then
    log "Error: index.html not found in extracted files!"
    set_status "FAILED"
    rm -rf "$TMP_DIR"
    exit 1
fi

log "Source directory identified: $DEPLOY_SRC"
log "Deploying static assets to: $TARGET_DIR"

mkdir -p "$TARGET_DIR"
cp -rf "$DEPLOY_SRC/"* "$TARGET_DIR/"
chmod -R 755 "$TARGET_DIR"

if [ -f "$TARGET_DIR/index.html" ]; then
    log "Deployment verification passed: $TARGET_DIR/index.html exists."
    log "Zashboard installation completed successfully!"
    set_status "SUCCESS"
    rm -rf "$TMP_DIR"
    exit 0
else
    log "Error: Failed to copy assets to target directory $TARGET_DIR."
    set_status "FAILED"
    rm -rf "$TMP_DIR"
    exit 1
fi
