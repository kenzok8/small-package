#!/bin/sh
# Download and install Dashboard for HONK

TARGET_DIR="${1:-/etc/honk/dashboard}"
DOWNLOAD_URL="${2:-https://github.com/Zephyruso/zashboard/releases/latest/download/dist-no-fonts.zip}"

LOG_FILE="/tmp/honk_dashboard_download.log"
STATUS_FILE="/tmp/honk_dashboard_download.status"
TMP_DIR="/tmp/dashboard_dl_$$"

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

log "Starting Dashboard deployment to: $TARGET_DIR"
log "Download URL: $DOWNLOAD_URL"

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

fetch_text() {
    local url="$1"
    if command -v curl >/dev/null 2>&1; then
        curl -s -k -L -f --connect-timeout 8 --max-time 15 "$url" 2>/dev/null
    elif command -v wget >/dev/null 2>&1; then
        wget --no-check-certificate -q -T 8 -t 1 -O - "$url" 2>/dev/null
    elif command -v uclient-fetch >/dev/null 2>&1; then
        uclient-fetch --no-check-certificate -q --timeout 8 -O - "$url" 2>/dev/null
    fi
}

case "$DOWNLOAD_URL" in
    *github.com/Zakkaus/doona*)
        PREFIX="${DOWNLOAD_URL%%https://github.com/*}"
        DEFAULT_TAG="v0.1.0-beta.3"
        FALLBACK_URL="${PREFIX}https://github.com/Zakkaus/doona/releases/download/${DEFAULT_TAG}/doona-${DEFAULT_TAG}.tar.gz"
        log "Checking for latest Doona release online..."

        RESOLVED_URL=""
        RELEASES_HTML=$(fetch_text "https://github.com/Zakkaus/doona/releases")
        LATEST_TAG=$(printf "%s" "$RELEASES_HTML" | grep -o 'releases/tag/[^"/]*' | head -n 1 | sed 's|releases/tag/||')

        if [ -n "$LATEST_TAG" ]; then
            log "Detected latest release tag: $LATEST_TAG"
            ASSETS_HTML=$(fetch_text "https://github.com/Zakkaus/doona/releases/expanded_assets/$LATEST_TAG")
            ASSET_PATH=$(printf "%s" "$ASSETS_HTML" | grep -o '/Zakkaus/doona/releases/download/[^"]*\.tar\.gz' | grep -v 'fonts' | head -n 1)
            if [ -n "$ASSET_PATH" ]; then
                RESOLVED_URL="https://github.com${ASSET_PATH}"
                log "Found release package: $ASSET_PATH"
            else
                RESOLVED_URL="https://github.com/Zakkaus/doona/releases/download/${LATEST_TAG}/doona-${LATEST_TAG}.tar.gz"
                log "Standard release package URL inferred: $RESOLVED_URL"
            fi
        fi

        if [ -n "$RESOLVED_URL" ]; then
            DOWNLOAD_URL="${PREFIX}${RESOLVED_URL}"
            log "Adaptive resolution succeeded: $DOWNLOAD_URL"
        else
            log "Warning: Online tag resolution unavailable. Falling back to verified release ($DEFAULT_TAG)."
            DOWNLOAD_URL="$FALLBACK_URL"
            log "Fallback download URL: $DOWNLOAD_URL"
        fi
        ;;
esac

log "Downloading package..."

rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR"
ARCHIVE_FILE="$TMP_DIR/package.tmp"



if ! download_file "$DOWNLOAD_URL" "$ARCHIVE_FILE" || [ ! -s "$ARCHIVE_FILE" ]; then
    ALT_URL=""
    case "$DOWNLOAD_URL" in
        *doona-v*)
            ALT_URL=$(echo "$DOWNLOAD_URL" | sed 's/doona-v/doona-/')
            ;;
        *doona-[0-9]*)
            ALT_URL=$(echo "$DOWNLOAD_URL" | sed 's/doona-/doona-v/')
            ;;
    esac
    if [ -n "$ALT_URL" ] && [ "$ALT_URL" != "$DOWNLOAD_URL" ]; then
        log "Retrying with alternative naming format: $ALT_URL"
        download_file "$ALT_URL" "$ARCHIVE_FILE" || true
    fi
fi

if [ ! -s "$ARCHIVE_FILE" ]; then
    log "Error: Download failed or file is empty."
    set_status "FAILED"
    rm -rf "$TMP_DIR"
    exit 1
fi

log "Download completed successfully. Extracting archive..."
set_status "EXTRACTING"
EXTRACT_DIR="$TMP_DIR/extracted"
mkdir -p "$EXTRACT_DIR"

if case "$DOWNLOAD_URL" in *.tar.gz|*.tgz) true ;; *) false ;; esac; then
    if ! command -v tar >/dev/null 2>&1; then
        log "Error: 'tar' command not found!"
        set_status "FAILED"
        rm -rf "$TMP_DIR"
        exit 1
    fi
    if ! tar -xzf "$ARCHIVE_FILE" -C "$EXTRACT_DIR" >> "$LOG_FILE" 2>&1; then
        log "Error: Failed to extract tar.gz archive."
        set_status "FAILED"
        rm -rf "$TMP_DIR"
        exit 1
    fi
else
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
