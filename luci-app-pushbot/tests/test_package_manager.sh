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
        printf 'iputils-arping - 20221126-1\ncurl - 8.4.0-1\n'
        ;;
esac
EOF
chmod +x "$tmpdir/bin/opkg"

cat >"$tmpdir/bin/apk" <<'EOF'
#!/bin/sh
if [ "$1" = "info" ] && [ "$2" = "-v" ]; then
    case "$3" in
        iputils-arping)
            printf 'iputils-arping-20221126-r0\n'
            ;;
        curl)
            printf 'curl-8.4.0-r1\n'
            ;;
    esac
fi
EOF
chmod +x "$tmpdir/bin/apk"

PATH="$tmpdir/bin:$PATH"
. "$helper"

apk_version=$(get_package_version iputils-arping)
[ "$apk_version" = "20221126-r0" ] || {
    echo "apk parsing failed: $apk_version" >&2
    exit 1
}

curl_version=$(get_package_version curl)
[ "$curl_version" = "8.4.0-r1" ] || {
    echo "apk curl parsing failed: $curl_version" >&2
    exit 1
}

echo "package manager compatibility test passed"
