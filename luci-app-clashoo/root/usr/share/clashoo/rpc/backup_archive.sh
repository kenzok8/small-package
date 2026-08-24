#!/bin/sh

set -eu

TMP_ROOT='/tmp/clashoo-backup'
RESTORE_LOCK_DIR="$TMP_ROOT/restore.lock"
IMPORT_LOCK_DIR="$TMP_ROOT/import.lock"
IMPORT_OWNER_FILE="$IMPORT_LOCK_DIR/path"
EXPORT_GUARD_DIR="$TMP_ROOT/export.lock"
MAX_ARCHIVE_BYTES=33554432
MAX_EXTRACTED_BYTES=67108864
MAX_TAR_BYTES=71303168
MAX_EXTRACTED_KB=65536
MAX_ENTRIES=2048
WORK_DIR=''
EXTRACT_DIR=''
RESTORE_LOCKED=0
EXPORT_GUARD_LOCKED=0

die() {
	printf '%s\n' "$*" >&2
	exit 1
}

cleanup() {
	case "$WORK_DIR" in
		"$TMP_ROOT"/*) rm -rf "$WORK_DIR" ;;
	esac
	if [ "$RESTORE_LOCKED" -eq 1 ]; then
		rmdir "$RESTORE_LOCK_DIR" >/dev/null 2>&1 || true
	fi
	if [ "$EXPORT_GUARD_LOCKED" -eq 1 ]; then
		rmdir "$EXPORT_GUARD_DIR" >/dev/null 2>&1 || true
	fi
}

trap cleanup EXIT INT TERM

is_safe_name() {
	local name="$1"
	[ -n "$name" ] || return 1
	case "$name" in
		.*|*..*|*/*|*\\*|*' '*|*'#'*|*'?'*|*'*'*|*':'*) return 1 ;;
	esac
	! printf '%s' "$name" | LC_ALL=C grep -q '[[:cntrl:]]'
}

is_allowed_entry() {
	local entry="$1" base
	case "$entry" in
		manifest.json|uci|meta/confit_list.conf|meta/template_bindings.conf)
			return 0
			;;
		meta|config|config/sub|config/upload|config/custom|config/singbox|templates)
			return 0
			;;
		config/sub/*)
			base="${entry#config/sub/}"
			is_safe_name "$base"
			;;
		config/upload/*)
			base="${entry#config/upload/}"
			is_safe_name "$base"
			;;
		config/custom/*)
			base="${entry#config/custom/}"
			is_safe_name "$base"
			;;
		config/singbox/*)
			base="${entry#config/singbox/}"
			is_safe_name "$base"
			;;
		templates/*)
			base="${entry#templates/}"
			is_safe_name "$base"
			;;
		*)
			return 1
			;;
	esac
}

normalise_entry() {
	local entry="$1"
	while [ "${entry#./}" != "$entry" ]; do
		entry="${entry#./}"
	done
	entry="${entry%/}"
	printf '%s\n' "$entry"
}

require_archive_path() {
	case "$1" in
		"$TMP_ROOT"/*) ;;
		*) die '备份临时路径无效' ;;
	esac
}

ensure_tmp_root() {
	local owner
	[ ! -L "$TMP_ROOT" ] || die '备份临时目录不能是符号链接'
	if [ -e "$TMP_ROOT" ]; then
		[ -d "$TMP_ROOT" ] || die '备份临时路径不是目录'
		owner="$(LC_ALL=C ls -nd "$TMP_ROOT" 2>/dev/null | awk '{ print $3 }')"
		[ "$owner" = '0' ] || die '备份临时目录所有者异常'
	else
		mkdir -m 700 "$TMP_ROOT" || die '无法创建备份临时目录'
	fi
	chmod 700 "$TMP_ROOT" || die '无法保护备份临时目录'
}

cleanup_stale_upload() {
	local upload=''
	if [ -d "$IMPORT_LOCK_DIR" ]; then
		if [ -f "$IMPORT_OWNER_FILE" ] &&
		   find "$IMPORT_OWNER_FILE" -mmin +15 | grep -q .; then
			upload="$(sed -n '1p' "$IMPORT_OWNER_FILE" 2>/dev/null || true)"
			case "$upload" in
				"$TMP_ROOT"/import.??????) rm -f "$upload" "$upload.result" ;;
			esac
			rm -rf "$IMPORT_LOCK_DIR"
		elif [ ! -f "$IMPORT_OWNER_FILE" ] &&
		     find "$IMPORT_LOCK_DIR" -mmin +15 | grep -q .; then
			rm -rf "$IMPORT_LOCK_DIR"
		fi
	fi
	find "$TMP_ROOT" -maxdepth 1 -type f -name 'import.*' -mmin +15 \
		-exec rm -f {} \; 2>/dev/null || true
}

new_upload() {
	local upload
	cleanup_stale_upload
	mkdir "$IMPORT_LOCK_DIR" 2>/dev/null || die '已有备份正在上传，请稍后重试'
	if ! upload="$(mktemp "$TMP_ROOT/import.XXXXXX")"; then
		rmdir "$IMPORT_LOCK_DIR" >/dev/null 2>&1 || true
		die '无法创建上传临时文件'
	fi
	if ! chmod 600 "$upload" ||
	   ! printf '%s\n' "$upload" > "$IMPORT_OWNER_FILE" ||
	   ! chmod 600 "$IMPORT_OWNER_FILE"; then
		rm -f "$upload" "$IMPORT_OWNER_FILE"
		rmdir "$IMPORT_LOCK_DIR" >/dev/null 2>&1 || true
		die '无法保护上传临时文件'
	fi
	printf '%s\n' "$upload"
}

new_export() {
	local count file
	if [ -d "$EXPORT_GUARD_DIR" ] &&
	   find "$EXPORT_GUARD_DIR" -mmin +1 | grep -q .; then
		rmdir "$EXPORT_GUARD_DIR" >/dev/null 2>&1 || true
	fi
	if ! mkdir "$EXPORT_GUARD_DIR" 2>/dev/null; then
		sleep 1
		mkdir "$EXPORT_GUARD_DIR" 2>/dev/null || die '正在准备其他备份，请稍后重试'
	fi
	EXPORT_GUARD_LOCKED=1
	find "$TMP_ROOT" -maxdepth 1 -type f -name 'export.*' -mmin +15 \
		-exec rm -f {} \; 2>/dev/null || true
	count="$(find "$TMP_ROOT" -maxdepth 1 -type f -name 'export.??????' | wc -l | tr -d ' ')"
	[ "$count" -lt 2 ] || die '已有多个备份等待下载，请稍后重试'
	file="$(mktemp "$TMP_ROOT/export.XXXXXX")" || die '无法创建导出临时文件'
	chmod 600 "$file" || die '无法保护导出临时文件'
	rmdir "$EXPORT_GUARD_DIR" || die '无法释放导出准备锁'
	EXPORT_GUARD_LOCKED=0
	printf '%s\n' "$file"
}

lock_restore() {
	mkdir "$RESTORE_LOCK_DIR" 2>/dev/null || die '已有备份正在还原，请稍后重试'
}

unlock_restore() {
	rmdir "$RESTORE_LOCK_DIR" >/dev/null 2>&1 || true
}

copy_regular() {
	local root="$1" source="$2" relative="$3" parent
	[ -f "$source" ] || return 0
	[ ! -L "$source" ] || die "拒绝备份符号链接: $source"
	parent="${relative%/*}"
	[ "$parent" = "$relative" ] || mkdir -p "$root/$parent"
	cp "$source" "$root/$relative"
}

copy_directory() {
	local root="$1" source_dir="$2" prefix="$3" source base
	[ -d "$source_dir" ] || return 0
	mkdir -p "$root/$prefix"
	for source in "$source_dir"/*; do
		[ -f "$source" ] || continue
		[ ! -L "$source" ] || continue
		base="${source##*/}"
		is_safe_name "$base" || continue
		cp "$source" "$root/$prefix/$base"
	done
}

copy_current_tree() {
	local root="$1"
	mkdir -p "$root"
	copy_regular "$root" /etc/config/clashoo uci
	copy_regular "$root" /usr/share/clashbackup/confit_list.conf meta/confit_list.conf
	copy_regular "$root" /usr/share/clashbackup/template_bindings.conf meta/template_bindings.conf
	copy_directory "$root" /usr/share/clashoo/config/sub config/sub
	copy_directory "$root" /usr/share/clashoo/config/upload config/upload
	copy_directory "$root" /usr/share/clashoo/config/custom config/custom
	copy_directory "$root" /usr/share/clashoo/config/singbox config/singbox
	copy_directory "$root" /etc/clashoo/templates templates
}

write_manifest() {
	local root="$1" host version created file
	host="$(uname -n 2>/dev/null || true)"
	version="$(sed -n '1p' /usr/share/clashoo/luci_version 2>/dev/null || true)"
	created="$(date +%s)"
	# jshn uses optional globals internally and is not nounset-safe.
	set +u
	. /usr/share/libubox/jshn.sh
	json_init
	json_add_string marker 'clashoo-backup-v2'
	json_add_int created_at "$created"
	json_add_string host "$host"
	json_add_string app_version "$version"
	json_add_array files
	for file in $(cd "$root" && find . -type f | sed 's#^\./##' | sort); do
		json_add_string '' "$file"
	done
	json_close_array
	json_dump > "$root/manifest.json"
	set -u
}

validate_archive() {
	local archive="$1" size validation_dir fifo tar_file gzip_pid head_rc gzip_rc tar_size list verbose raw entry mode type manifest_seen=0 entry_count=0 extracted_bytes extracted_kb marker
	require_archive_path "$archive"
	[ -f "$archive" ] || die '备份文件不存在'
	size="$(wc -c < "$archive" | tr -d ' ')"
	[ "$size" -gt 0 ] || die '备份文件为空'
	[ "$size" -le "$MAX_ARCHIVE_BYTES" ] || die '备份文件超过 32MB'

	if [ -z "$WORK_DIR" ]; then
		WORK_DIR="$(mktemp -d "$TMP_ROOT/validate.XXXXXX")"
	fi
	validation_dir="$WORK_DIR/validation"
	mkdir -p "$validation_dir"
	fifo="$validation_dir/archive.pipe"
	tar_file="$validation_dir/archive.tar"
	mkfifo "$fifo" || die '无法创建备份校验管道'
	gzip -dc "$archive" > "$fifo" 2>/dev/null &
	gzip_pid=$!
	set +e
	head -c "$((MAX_TAR_BYTES + 1))" "$fifo" > "$tar_file" 2>/dev/null
	head_rc=$?
	wait "$gzip_pid"
	gzip_rc=$?
	set -e
	rm -f "$fifo"
	tar_size="$(wc -c < "$tar_file" | tr -d ' ')"
	[ "$tar_size" -le "$MAX_TAR_BYTES" ] || die '备份解压后超过 64MB'
	[ "$head_rc" -eq 0 ] && [ "$gzip_rc" -eq 0 ] || die '备份压缩包损坏'
	list="$validation_dir/list"
	verbose="$validation_dir/verbose"
	tar -tf "$tar_file" > "$list" 2>/dev/null || die '无法读取备份文件清单'
	tar -tvf "$tar_file" > "$verbose" 2>/dev/null || die '无法读取备份文件类型'

	while IFS= read -r raw; do
		entry_count=$((entry_count + 1))
		[ "$entry_count" -le "$MAX_ENTRIES" ] || die '备份文件条目过多'
		entry="$(normalise_entry "$raw")"
		[ -n "$entry" ] || continue
		case "$entry" in
			/*|*\\*) die '备份文件包含非法路径' ;;
		esac
		case "/$entry/" in
			*/../*|*/./*) die '备份文件包含目录穿越路径' ;;
		esac
		is_allowed_entry "$entry" || die "备份文件包含未知路径: $entry"
		[ "$entry" = 'manifest.json' ] && manifest_seen=1
	done < "$list"
	[ "$manifest_seen" -eq 1 ] || die '备份文件缺少 manifest.json'

	while IFS= read -r raw; do
		mode="${raw%% *}"
		type="$(printf '%s' "$mode" | cut -c 1)"
		case "$type" in
			-|d) ;;
			*) die '备份文件包含链接或特殊文件' ;;
		esac
	done < "$verbose"
	extracted_bytes="$(awk '$1 ~ /^-/ { total += $3 } END { printf "%.0f\n", total }' "$verbose")"
	[ "$extracted_bytes" -le "$MAX_EXTRACTED_BYTES" ] || die '备份解压后超过 64MB'

	EXTRACT_DIR="$validation_dir/extract"
	mkdir -p "$EXTRACT_DIR"
	tar -xf "$tar_file" -C "$EXTRACT_DIR" >/dev/null 2>&1 || die '备份文件解压失败'
	if find "$EXTRACT_DIR" -type l | grep -q .; then
		die '备份文件包含符号链接'
	fi
	extracted_kb="$(du -sk "$EXTRACT_DIR" | cut -f 1)"
	[ "$extracted_kb" -le "$MAX_EXTRACTED_KB" ] || die '备份解压后超过 64MB'
	[ -f "$EXTRACT_DIR/manifest.json" ] || die '备份清单不是普通文件'
	[ -f "$EXTRACT_DIR/uci" ] || die '备份文件缺少 UCI 配置'
	marker="$(jsonfilter -i "$EXTRACT_DIR/manifest.json" -e '@.marker' 2>/dev/null || true)"
	[ "$marker" = 'clashoo-backup-v2' ] || die '备份格式标记无效'
}

clear_target_directories() {
	local directory
	for directory in \
		/usr/share/clashoo/config/sub \
		/usr/share/clashoo/config/upload \
		/usr/share/clashoo/config/custom \
		/usr/share/clashoo/config/singbox \
		/etc/clashoo/templates; do
		mkdir -p "$directory" || return 1
		rm -rf "$directory"/* "$directory"/.[!.]* "$directory"/..?* || return 1
	done
}

copy_tree_to_system() {
	local root="$1" source base
	clear_target_directories || return 1
	[ -f "$root/uci" ] && cp "$root/uci" /etc/config/clashoo || return 1
	rm -f /usr/share/clashbackup/confit_list.conf \
		/usr/share/clashbackup/template_bindings.conf || return 1
	if [ -f "$root/meta/confit_list.conf" ]; then
		mkdir -p /usr/share/clashbackup || return 1
		cp "$root/meta/confit_list.conf" /usr/share/clashbackup/confit_list.conf || return 1
	fi
	if [ -f "$root/meta/template_bindings.conf" ]; then
		mkdir -p /usr/share/clashbackup || return 1
		cp "$root/meta/template_bindings.conf" /usr/share/clashbackup/template_bindings.conf || return 1
	fi
	for source in "$root/config/sub"/*; do
		[ -f "$source" ] || continue
		base="${source##*/}"
		cp "$source" "/usr/share/clashoo/config/sub/$base" || return 1
	done
	for source in "$root/config/upload"/*; do
		[ -f "$source" ] || continue
		base="${source##*/}"
		cp "$source" "/usr/share/clashoo/config/upload/$base" || return 1
	done
	for source in "$root/config/custom"/*; do
		[ -f "$source" ] || continue
		base="${source##*/}"
		cp "$source" "/usr/share/clashoo/config/custom/$base" || return 1
	done
	for source in "$root/config/singbox"/*; do
		[ -f "$source" ] || continue
		base="${source##*/}"
		cp "$source" "/usr/share/clashoo/config/singbox/$base" || return 1
	done
	for source in "$root/templates"/*; do
		[ -f "$source" ] || continue
		base="${source##*/}"
		cp "$source" "/etc/clashoo/templates/$base" || return 1
	done
}

export_archive() {
	local archive="$1" stage
	require_archive_path "$archive"
	WORK_DIR="$(mktemp -d "$TMP_ROOT/export.XXXXXX")"
	stage="$WORK_DIR/stage"
	copy_current_tree "$stage"
	write_manifest "$stage"
	tar -C "$stage" -czf "$archive" .
	chmod 600 "$archive"
	if ! sh "$0" validate "$archive"; then
		rm -f "$archive"
		die '生成的备份不符合还原限制'
	fi
	printf 'files=%s\n' "$(find "$stage" -type f | wc -l | tr -d ' ')"
}

restore_archive() {
	local upload="$1" lock_mode="${2:-acquire}" archive rollback restored
	require_archive_path "$upload"
	if [ "$lock_mode" = 'acquire' ]; then
		lock_restore
		RESTORE_LOCKED=1
	else
		[ -d "$RESTORE_LOCK_DIR" ] || die '备份还原锁不存在'
	fi
	WORK_DIR="$(mktemp -d "$TMP_ROOT/restore.XXXXXX")"
	archive="$WORK_DIR/import.tar.gz"
	mv "$upload" "$archive" || die '无法接管已上传的备份文件'
	validate_archive "$archive"
	rollback="$WORK_DIR/rollback"
	copy_current_tree "$rollback"
	if ! copy_tree_to_system "$EXTRACT_DIR"; then
		if copy_tree_to_system "$rollback" >/dev/null 2>&1; then
			die '恢复写入失败，已回滚原配置'
		fi
		die '恢复写入失败，自动回滚也失败，请检查存储空间'
	fi
	restored="$(find "$EXTRACT_DIR" -type f ! -name manifest.json | wc -l | tr -d ' ')"
	printf 'restored=%s\n' "$restored"
}

ensure_tmp_root

command="${1:-}"
archive="${2:-}"

case "$command" in
	prepare) cleanup_stale_upload ;;
	new-upload) new_upload ;;
	new-export) new_export ;;
	lock) lock_restore ;;
	unlock) unlock_restore ;;
	export) export_archive "$archive" ;;
	validate) validate_archive "$archive" ;;
	restore) restore_archive "$archive" ;;
	restore-held) restore_archive "$archive" held ;;
	*) die '不支持的备份操作' ;;
esac
