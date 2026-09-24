#!/bin/sh
# Detect storage base path for cloudreve.
# Ported from iStoreOS official skill istoreos-storage-path/scripts/detect.sh
# Rules:
#   1. enumerate mounts via df -P -k, keep /mnt|/media|/opt
#   2. require >= 10MB free (10240 KB) AND writable test
#   3. pick the one with LARGEST available space
#   4. no fallback: nothing qualifies -> exit 1 and let the caller tell the user
#   5. validate against dangerous paths (/, /root/*, ../, system dirs, /tmp)
#
# Usage:
#   cloudreve-detect-base          -> print chosen base path (stderr: reason)
#   cloudreve-detect-base --list   -> print ALL writable candidates:
#                                      "<mountpoint>\t<availKB>\t<fstype>"
#   cloudreve-detect-base --check <p> -> verify single path writable+space+safe
set -eu

say() { echo "$*" >&2; }

MIN_KB=10240

# 路径安全性校验：照抄 luci-app-openclawmgr 的 validate_base_dir
# 禁止：空、相对路径、/、/root/*、含 ..、系统目录（/bin /sbin /lib /usr /etc /proc /sys /dev /run /tmp /var /overlay /rom）
validate_path() {
	local dir="$1"
	# 去除尾部空格和斜杠
	dir="$(printf "%s" "$dir" | sed 's/[[:space:]]*$//')"
	dir="${dir%/}"
	# 空值
	[ -n "$dir" ] || { say "路径为空"; return 1; }
	# 必须绝对路径
	case "$dir" in
		/*) ;;
		*) say "路径必须是绝对路径: $dir"; return 1 ;;
	esac
	# 禁止 /
	[ "$dir" != "/" ] || { say "不能使用根目录 /: $dir"; return 1; }
	# 禁止 /root 及子目录
	case "$dir" in
		/root|/root/*) say "不能使用 /root 开头的目录: $dir"; return 1 ;;
	esac
	# 禁止 ..
	case "$dir" in
		*"/../"*|*"/.."|*"/./"*|*"/.") say "路径不能包含 .. 或 .: $dir"; return 1 ;;
	esac
	# 禁止系统目录
	case "$dir" in
		/bin|/bin/*|/sbin|/sbin/*|/lib|/lib/*|/usr|/usr/*|/etc|/etc/*|/proc|/proc/*|/sys|/sys/*|/dev|/dev/*|/run|/run/*|/tmp|/tmp/*|/var|/var/*|/overlay|/overlay/*|/rom|/rom/*)
			say "$dir 是系统目录，禁止使用"; return 1
			;;
	esac
	return 0
}

ok() {
	base="$1"
	[ -n "$base" ] || return 1
	# 先校验路径安全
	validate_path "$base" || return 1
	mkdir -p "$base" 2>/dev/null || return 1
	t="$base/.cloudreve_write_test.$$"
	: >"$t" 2>/dev/null || return 1
	rm -f "$t" 2>/dev/null || true
	return 0
}

# list candidates: mountpoint, availKB, fstype
# 过滤掉 overlay（Docker 容器层）、tmpfs、devtmpfs 等虚拟文件系统
# 只保留 ext4/xfs/btrfs/trvfat/ntfs 等真实磁盘文件系统
list_cands() {
	df -P -kT 2>/dev/null | awk '
		NR==1 { next }
		($7 ~ "^/mnt/" || $7 ~ "^/media/" || $7 ~ "^/opt/") && \
		($2 == "ext4" || $2 == "xfs" || $2 == "btrfs" || $2 == "vfat" || $2 == "exfat" || $2 == "ntfs" || $2 == "ext3" || $2 == "ext2" || $2 == "f2fs") && \
		($7 !~ /overlay/) && \
		($7 !~ /docker/) \
		{ print $7 "	" $5 "	" $2 }
	' | sort -u
}

case "${1:-}" in

--list)
	list_cands | while IFS="$(printf '	')" read -r mp avail fstype; do
		[ -n "${mp:-}" ] || continue
		[ -n "${avail:-}" ] || continue
		[ "$avail" -ge "$MIN_KB" ] 2>/dev/null || continue
		ok "$mp" || continue
		echo "$mp	$avail	$fstype"
	done
	exit 0
	;;

--check)
	target="${2:-}"
	[ -n "$target" ] || { say "no path given"; exit 1; }
	validate_path "$target" || exit 1
	ok "$target" || { say "not writable: $target"; exit 1; }
	say "ok: $target"
	exit 0
	;;

*)
	chosen=""
	best_avail=0
	cands="$(list_cands)"
	tab="$(printf '	')"

	while IFS="$tab" read -r mp avail fstype; do
		[ -n "${mp:-}" ] || continue
		[ -n "${avail:-}" ] || continue
		[ "$avail" -ge "$MIN_KB" ] 2>/dev/null || continue
		ok "$mp" || continue
		if [ "$avail" -gt "$best_avail" ] 2>/dev/null; then
			best_avail="$avail"
			chosen="$mp"
		fi
	done <<EOF
$cands
EOF

	if [ -n "$chosen" ]; then
		say "picked: base path=$chosen (largest writable mount under /mnt|/media|/opt, >= 10MB free)"
		echo "$chosen"
		exit 0
	fi

	say "failed: no writable external mount found (need a mount under /mnt|/media|/opt with >= 10MB free); the system disk is not used on purpose."
	exit 1
	;;
esac
