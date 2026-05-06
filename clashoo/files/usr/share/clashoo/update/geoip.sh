#!/bin/sh

LOG_FILE="/tmp/geoip_update.txt"
TMP_DIR="/tmp/clash_geoip_$$"
MMDB_MIN_SIZE=2000000
GEOSITE_MIN_SIZE=2000000

geoip_source="$(uci -q get clashoo.config.geoip_source 2>/dev/null)"
license_key="$(uci -q get clashoo.config.license_key 2>/dev/null)"

cfg_mmdb_url="$(uci -q get clashoo.config.geoip_mmdb_url 2>/dev/null)"
cfg_geosite_url="$(uci -q get clashoo.config.geosite_url 2>/dev/null)"
cfg_geoip_dat_url="$(uci -q get clashoo.config.geoip_dat_url 2>/dev/null)"
cfg_geoip_asn_url="$(uci -q get clashoo.config.geoip_asn_url 2>/dev/null)"

DEFAULT_MMDB_URL="https://raw.githubusercontent.com/Loyalsoldier/geoip/release/Country.mmdb"
DEFAULT_GEOSITE_URL="https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/release/geosite.dat"
DEFAULT_GEOIP_DAT_URL="https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/release/geoip.dat"
DEFAULT_GEOIP_ASN_URL="https://github.com/xishang0128/geoip/releases/download/latest/GeoLite2-ASN.mmdb"

OPENCLASH_MMDB_URL="https://raw.githubusercontent.com/Loyalsoldier/geoip/release/Country.mmdb"
OPENCLASH_GEOSITE_URL="https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/geosite.dat"
OPENCLASH_GEOIP_DAT_URL="https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/geoip.dat"

log() {
	echo "  $(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

cleanup() {
	rm -rf "$TMP_DIR" >/dev/null 2>&1
	rm -f /var/run/geoip_update >/dev/null 2>&1
}

download_to() {
	url="$1"
	target="$2"
	if [ -z "$url" ]; then
		return 1
	fi
	if command -v curl >/dev/null 2>&1; then
		curl -fsSL --connect-timeout 15 --max-time 300 -A "Clash/OpenWRT" "$url" -o "$target"
		return $?
	fi
	wget -q -c4 --timeout=300 --no-check-certificate --user-agent="Clash/OpenWRT" "$url" -O "$target"
}

download_optional() {
	url="$1"
	target="$2"
	name="$3"
	tmp_target="${TMP_DIR}/$(basename "$target").tmp"
	if [ -z "$url" ]; then
		log "$name skip (url empty)"
		return 0
	fi
	rm -f "$tmp_target" >/dev/null 2>&1
	if download_to "$url" "$tmp_target"; then
		mv -f "$tmp_target" "$target" >/dev/null 2>&1 || return 1
		chmod 644 "$target" >/dev/null 2>&1
		log "$name updated"
		return 0
	fi
	rm -f "$tmp_target" >/dev/null 2>&1
	log "$name update failed"
	return 0
}

download_geosite() {
	url="$1"
	tmp_target="${TMP_DIR}/GeoSite.dat.tmp"
	size=0
	if [ -z "$url" ]; then
		log "GeoSite.dat skip (url empty)"
		return 0
	fi
	rm -f "$tmp_target" >/dev/null 2>&1
	if ! download_to "$url" "$tmp_target"; then
		rm -f "$tmp_target" >/dev/null 2>&1
		log "GeoSite.dat update failed"
		return 0
	fi
	size=$(wc -c <"$tmp_target" 2>/dev/null)
	if [ -z "$size" ] || [ "$size" -lt "$GEOSITE_MIN_SIZE" ]; then
		log "GeoSite.dat download invalid or incomplete (${size:-0} bytes)"
		rm -f "$tmp_target" >/dev/null 2>&1
		return 0
	fi
	mv -f "$tmp_target" /etc/clashoo/GeoSite.dat >/dev/null 2>&1 || return 1
	cp -f /etc/clashoo/GeoSite.dat /etc/clashoo/geosite.dat >/dev/null 2>&1 || true
	chmod 644 /etc/clashoo/GeoSite.dat /etc/clashoo/geosite.dat >/dev/null 2>&1
	log "GeoSite.dat updated"
	return 0
}

download_mmdb() {
	url="$1"
	tmp_target="${TMP_DIR}/Country.mmdb.tmp"
	size=0
	rm -f "$tmp_target" >/dev/null 2>&1
	if ! download_to "$url" "$tmp_target"; then
		rm -f "$tmp_target" >/dev/null 2>&1
		return 1
	fi
	size=$(wc -c <"$tmp_target" 2>/dev/null)
	if [ -z "$size" ] || [ "$size" -lt "$MMDB_MIN_SIZE" ]; then
		log "Country.mmdb download invalid or incomplete (${size:-0} bytes)"
		rm -f "$tmp_target" >/dev/null 2>&1
		return 1
	fi
	mv -f "$tmp_target" /etc/clashoo/Country.mmdb >/dev/null 2>&1 || return 1
	chmod 644 /etc/clashoo/Country.mmdb >/dev/null 2>&1
	return 0
}

trap cleanup EXIT INT TERM
mkdir -p "$TMP_DIR" /etc/clashoo >/dev/null 2>&1

rm -f /var/run/geoip_down_complete >/dev/null 2>&1
: > "$LOG_FILE"
log "GeoIP 更新任务启动"

mmdb_url=""
geosite_url=""
geoip_dat_url=""
geoip_asn_url=""

case "$geoip_source" in
	1)
		if [ -z "$license_key" ]; then
			log "MaxMind source selected but license key is empty"
			exit 1
		fi
		log "Updating Country.mmdb from MaxMind"
		if ! download_to "https://download.maxmind.com/app/geoip_download?edition_id=GeoLite2-Country&license_key=${license_key}&suffix=tar.gz" "$TMP_DIR/geoip.tar.gz"; then
			log "MaxMind download failed"
			exit 1
		fi
		if ! tar zxf "$TMP_DIR/geoip.tar.gz" -C "$TMP_DIR" >/dev/null 2>&1; then
			log "MaxMind archive extract failed"
			exit 1
		fi
		mmdb_file="$(ls "$TMP_DIR"/GeoLite2-Country_*/GeoLite2-Country.mmdb 2>/dev/null | head -n 1)"
		if [ -z "$mmdb_file" ] || [ ! -f "$mmdb_file" ]; then
			log "MaxMind Country.mmdb not found in archive"
			exit 1
		fi
		cp -f "$mmdb_file" /etc/clashoo/Country.mmdb
		chmod 644 /etc/clashoo/Country.mmdb >/dev/null 2>&1
		log "Country.mmdb updated"
		;;
	3)
		mmdb_url="$OPENCLASH_MMDB_URL"
		geosite_url="$OPENCLASH_GEOSITE_URL"
		geoip_dat_url="$OPENCLASH_GEOIP_DAT_URL"
		;;
	4)
		mmdb_url="$cfg_mmdb_url"
		geosite_url="$cfg_geosite_url"
		geoip_dat_url="$cfg_geoip_dat_url"
		geoip_asn_url="$cfg_geoip_asn_url"
		;;
	*)
		mmdb_url="${cfg_mmdb_url:-$DEFAULT_MMDB_URL}"
		geosite_url="${cfg_geosite_url:-$DEFAULT_GEOSITE_URL}"
		geoip_dat_url="${cfg_geoip_dat_url:-$DEFAULT_GEOIP_DAT_URL}"
		geoip_asn_url="${cfg_geoip_asn_url:-$DEFAULT_GEOIP_ASN_URL}"
		;;
esac

if [ "$geoip_source" != "1" ]; then
	log "Updating Country.mmdb"
	if ! download_mmdb "$mmdb_url"; then
		log "Country.mmdb download failed"
		exit 1
	fi
	log "Country.mmdb updated"

	download_geosite "$geosite_url"
	download_optional "$geoip_dat_url" /etc/clashoo/geoip.dat "geoip.dat"
	download_optional "$geoip_asn_url" /etc/clashoo/GeoLite2-ASN.mmdb "GeoLite2-ASN.mmdb"
fi

touch /var/run/geoip_down_complete >/dev/null 2>&1

if pidof mihomo >/dev/null 2>&1 || pidof clash-meta >/dev/null 2>&1; then
	log "GeoIP update completed, apply on next Clashoo restart"
fi

log "GeoIP update completed"
exit 0
