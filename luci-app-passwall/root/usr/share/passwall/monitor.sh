#!/bin/sh

DIR="$(cd "$(dirname "$0")" && pwd)"
. $DIR/utils.sh
LOCK_FILE=${LOCK_PATH}/${CONFIG}_monitor.lock

MAX_RESTART_COUNT=10
RESTART_STATS_DIR="${TMP_PATH}/script_rstats"
mkdir -p "$RESTART_STATS_DIR"

[ "$(get_cache_var "ENABLED_DEFAULT_ACL")" != 1 ] && [ "$(get_cache_var "ENABLED_ACLS")" != 1 ] && exit 1
ENABLED=$(config_n_get @global_delay[0] start_daemon 0)
[ "$ENABLED" != 1 ] && exit 1
exec 9>"$LOCK_FILE"
flock -n 9 || exit 0
sleep 58s 9>&-
last_cleanup_date=$(date +%Y%m%d)
while [ "$ENABLED" -eq 1 ]; do
	for file in "$TMP_SCRIPT_FUNC_PATH"/*; do
		[ -f "$file" ] || continue
		{
			IFS= read -r pid
			IFS= read -r start_time
		} < "$file"
		cmd=$(sed '1,2d' "$file")
		[ -z "$cmd" ] && continue

		filename=$(basename "$file")
		stats_file="${RESTART_STATS_DIR}/${filename}.count"
		if [ -s "$stats_file" ]; then
			read restart_count < "$stats_file"
			[ -z "$restart_count" ] && restart_count=0
		else
			restart_count=0
		fi
		# 检查是否超过最大重启次数
		[ "$restart_count" -ge "$MAX_RESTART_COUNT" ] && continue

		current_start_time=$(get_process_start_time "$pid")
		if [ -z "$current_start_time" ] || [ "$current_start_time" != "$start_time" ]; then
			restart_count=$((restart_count + 1))
			echo "$restart_count" > "$stats_file"
			#echo "${cmd} 进程挂掉，重启" >> /tmp/log/passwall.log
			pid=$(sh -c "nohup ${cmd} & echo \$!" 9>&-)
			{
				printf '%s\n' "$pid" "$(get_process_start_time "$pid")"
				printf '%s\n' "$cmd"
			} > "$file"
			sleep 1 9>&-
		fi
	done

	# 每天清理一次统计文件（跨天后执行一次）
	current_date=$(date +%Y%m%d)
	if [ "$current_date" != "$last_cleanup_date" ]; then
		rm -f "${RESTART_STATS_DIR:?}"/* 2>/dev/null
		last_cleanup_date="$current_date"
	fi

	sleep 58s 9>&-
done
