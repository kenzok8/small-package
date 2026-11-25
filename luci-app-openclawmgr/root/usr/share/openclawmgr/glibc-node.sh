#!/bin/sh
set -eu
# Resolve on every exec: candidates move atomically into releases at commit.
node_root="$(dirname "$(dirname "$(readlink -f "$0")")")"
# npm's platform checker prefers host /usr/bin/ldd over Node's runtime report.
# Keep optional native dependency selection consistent with this glibc Node.
export npm_config_libc=glibc
# --library-path applies to this glibc process only. Host sh/git/ks-cli remain
# native OpenWrt processes and must not inherit glibc LD_LIBRARY_PATH.
exec "$node_root/glibc/ld.so" --library-path "$node_root/glibc" "$node_root/bin/node.real" --require "$node_root/node-loader.cjs" "$@"
