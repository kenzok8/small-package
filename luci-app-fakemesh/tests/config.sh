#!/bin/sh
# Run with sh tests/config.sh [path-to-fakemesh]; requires OpenWrt uci.
set -eu

source_file=${1:-"$(dirname "$0")/../root/usr/sbin/fakemesh"}
command -v uci >/dev/null

# Load only the production validators, without running service setup.
eval "$(sed -n '/^valid_wireless_key()/,/^}/p; /^validate_ac_config()/,/^)/p' "$source_file")"

test_dir=$(mktemp -d /tmp/fakemesh-config-test.XXXXXX)
trap 'rm -rf "$test_dir"' EXIT
trap 'exit 1' HUP INT TERM
mkdir "$test_dir/config" "$test_dir/changes"
config_file="$test_dir/config/fakemeshac"

cat > "$test_dir/base" <<'EOF'
config fakemesh 'default'
	option enabled '1'
	option role 'controller'
	option id 'test-mesh'
	option band '5g'

config wifim 'wifi'
	option ssid 'Test WiFi'
	option encryption 'psk2'
	option key 'test-password'
	option band '2g5g'
EOF

test_uci() {
	uci -q -c "$test_dir/config" -P "$test_dir/changes" "$@"
}

reset_config() {
	rm -f "$test_dir/changes/fakemeshac"
	cp "$test_dir/base" "$config_file"
}

persist_config() {
	test_uci export fakemeshac > "$test_dir/export"
	mv "$test_dir/export" "$config_file"
	rm -f "$test_dir/changes/fakemeshac"
}

expect_valid() {
	persist_config
	before=$(md5sum "$config_file")
	if ! validate_ac_config "$config_file"; then
		echo "FAIL: $1 rejected" >&2
		exit 1
	fi
	[ "$before" = "$(md5sum "$config_file")" ]
}

expect_invalid() {
	persist_config
	if validate_ac_config "$config_file"; then
		echo "FAIL: $1 accepted" >&2
		exit 1
	fi
}

reset_config
expect_valid 'explicit defaults'
test_uci delete fakemeshac.default.band
expect_valid 'omitted backhaul band'
test_uci delete fakemeshac.wifi.band
expect_valid 'omitted wireless catalog band'
test_uci set fakemeshac.wifi.enabled=0
expect_valid 'disabled wireless entry'

reset_config
test_uci set fakemeshac.default.band=invalid
expect_invalid 'invalid backhaul band'
reset_config
test_uci set fakemeshac.wifi.band=invalid
expect_invalid 'invalid wireless catalog band'
reset_config
test_uci set fakemeshac.wifi.key=short
expect_invalid 'short wireless key'
reset_config
test_uci set fakemeshac.wifi.band=6g
test_uci set "fakemeshac.wifi.key=$(printf '%064d' 0)"
expect_invalid 'raw PSK on 6 GHz'
reset_config
test_uci set fakemeshac.default.role=agent
expect_invalid 'non-controller report'
reset_config
test_uci delete fakemeshac.default.id
expect_invalid 'missing mesh ID'
reset_config
test_uci delete fakemeshac.wifi
expect_valid 'empty wireless catalog'

echo 'Configuration checks passed: omitted defaults, explicit bands, invalid settings, unchanged input.'
