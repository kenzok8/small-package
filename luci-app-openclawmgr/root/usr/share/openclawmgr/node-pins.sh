# Node 24.22.1. SHA256 read from the official HTTPS SHASUMS256.txt on 2026-11-23.
# Update version, URL and digest together; never discover an unpinned archive.
# The function returns its pin through variables used by install-runtime.sh.
# shellcheck disable=SC2034
oc_node_pin() {
	NODE_VERSION=24.22.1
	local arch="$1" libc="$2" file
	file="node-v${NODE_VERSION}-linux-${arch}"
	[ "$libc" = glibc ] || return 1
	case "$arch" in
		x64) OC_NODE_SHA256=6c172a9ab6718f7b801fb5a7bd486af2ee5e32758086a04b84fcce2aa77095e6 ;;
		arm64) OC_NODE_SHA256=dbabf7a1cbf947e6059ffad2c27b80041db97dea1e553b62afdee7f13fca336e ;;
		*) return 1 ;;
	esac
	file="${file}.tar.xz"
	OC_NODE_URL="https://nodejs.org/dist/v${NODE_VERSION}/${file}"
}
