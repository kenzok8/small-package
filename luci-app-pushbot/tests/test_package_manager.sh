#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
helper="$repo_root/root/usr/bin/pushbot/package_manager.sh"

if [ ! -f "$helper" ]; then
    echo "helper not found: $helper" >&2
    exit 1
fi

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/bin"

cat >"$tmpdir/bin/opkg" <<'EOF'
#!/bin/sh
case "$1" in
    list-installed)
        printf 'iputils-arping - 20221126-1\ncurl - 8.4.0-1\nwrtbwmon - 1.2.1\n'
        ;;
esac
EOF
chmod +x "$tmpdir/bin/opkg"

# Mock apk mirrors real OpenWrt behavior:
#   apk info <pkg>   -> name-version   (used by get_package_version)
#   apk info -v <pkg>-> description    (verbose; must NOT be used)
cat >"$tmpdir/bin/apk" <<'EOF'
#!/bin/sh
if [ "$1" = "info" ]; then
    if [ "$2" = "-v" ]; then
        case "$3" in
            iputils-arping)
                printf 'iputils-arping: Send ARP REQUEST packets to a neighbor host\n'
                printf 'iputils-arping: https://github.com/iputils/iputils\n'
                printf 'iputils-arping: 19 KiB\n'
                ;;
            curl)
                printf 'curl: A client-side URL transfer utility\n'
                printf 'curl: https://curl.se/\n'
                printf 'curl: 160 KiB\n'
                ;;
        esac
    else
        case "$2" in
            iputils-arping)
                printf 'iputils-arping-20250605-r1\n'
                ;;
            curl)
                printf 'curl-8.21.0-r1\n'
                ;;
            wrtbwmon)
                printf 'wrtbwmon-1.2.1-r3\n'
                ;;
            iw)
                printf 'iw-6.17-r1\niw-full-6.17-r1\n'
                ;;
        esac
    fi
fi
EOF
chmod +x "$tmpdir/bin/apk"

PATH="$tmpdir/bin:$PATH"
. "$helper"

# ---- apk path (name-version extraction) ----
apk_version=$(get_package_version iputils-arping)
[ "$apk_version" = "20250605-r1" ] || {
    echo "apk iputils-arping parsing failed: $apk_version" >&2
    exit 1
}

curl_version=$(get_package_version curl)
[ "$curl_version" = "8.21.0-r1" ] || {
    echo "apk curl parsing failed: $curl_version" >&2
    exit 1
}

wrtbwmon_version=$(get_package_version wrtbwmon)
[ "$wrtbwmon_version" = "1.2.1-r3" ] || {
    echo "apk wrtbwmon parsing failed: $wrtbwmon_version" >&2
    exit 1
}

# iw prints two rows (iw + iw-full); head -1 must pick the exact match
iw_version=$(get_package_version iw)
[ "$iw_version" = "6.17-r1" ] || {
    echo "apk iw parsing failed: $iw_version" >&2
    exit 1
}

# ---- opkg path (unchanged logic) ----
# move apk aside so opkg branch is exercised
mv "$tmpdir/bin/apk" "$tmpdir/bin/apk.bak"
opkg_version=$(get_package_version curl)
[ "$opkg_version" = "8.4.0-1" ] || {
    echo "opkg parsing failed: $opkg_version" >&2
    exit 1
}
opkg_arping=$(get_package_version iputils-arping)
[ "$opkg_arping" = "20221126-1" ] || {
    echo "opkg arping parsing failed: $opkg_arping" >&2
    exit 1
}
mv "$tmpdir/bin/apk.bak" "$tmpdir/bin/apk"

# ---- command-detection fallback (no apk/opkg on PATH) ----
mkdir -p "$tmpdir/no_pkg/bin"
cat >"$tmpdir/no_pkg/bin/curl" <<'EOF'
#!/bin/sh
if [ "$1" = "-V" ]; then
    printf 'curl 8.21.0 (x86_64-openwrt-linux-gnu) libcurl/8.21.0\n'
fi
EOF
chmod +x "$tmpdir/no_pkg/bin/curl"

cat >"$tmpdir/no_pkg/bin/arping" <<'EOF'
#!/bin/sh
if [ "$1" = "-V" ]; then
    printf 'arping utility, iputils-20221126\n'
fi
EOF
chmod +x "$tmpdir/no_pkg/bin/arping"

cat >"$tmpdir/no_pkg/bin/iw" <<'EOF'
#!/bin/sh
if [ "$1" = "version" ]; then
    printf 'iw version 5.19\n'
fi
EOF
chmod +x "$tmpdir/no_pkg/bin/iw"

# PATH: mock commands first, system dirs for tools, apk/opkg mocks excluded
PATH="$tmpdir/no_pkg/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
export PATH

curl_fallback=$(get_package_version curl)
[ "$curl_fallback" = "8.21.0" ] || {
    echo "curl command fallback failed: $curl_fallback" >&2
    exit 1
}

arping_fallback=$(get_package_version iputils-arping)
[ "$arping_fallback" = "20221126" ] || {
    echo "arping command fallback failed: $arping_fallback" >&2
    exit 1
}

iw_fallback=$(get_package_version iw)
[ "$iw_fallback" = "5.19" ] || {
    echo "iw command fallback failed: $iw_fallback" >&2
    exit 1
}

# wrtbwmon has no -V; when absent from package manager it must stay empty
wrtbwmon_fallback=$(get_package_version wrtbwmon)
[ -z "$wrtbwmon_fallback" ] || {
    echo "wrtbwmon fallback should be empty: $wrtbwmon_fallback" >&2
    exit 1
}

echo "package manager compatibility test passed"
