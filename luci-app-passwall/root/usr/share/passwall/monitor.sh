#!/bin/sh

DIR="$(cd "$(dirname "$0")" && pwd)"
. $DIR/utils.sh
LOCK_FILE=${LOCK_PATH}/${CONFIG}_monitor.lock

MAX_RESTART_COUNT=10
RESTART_STATS_DIR="${TMP_PATH}/script_rstats"
mkdir -p "$RESTART_STATS_DIR"

sleep 58s
last_cleanup_date=$(date +%Y%m%d)
while [ 1 -eq 1 ]; do
	[ -f "$LOCK_FILE" ] && {
		sleep 6s
		continue
	}
	touch $LOCK_FILE

	for file in "$TMP_SCRIPT_FUNC_PATH"/*; do
		[ -f "$file" ] || continue
		IFS= read -r cmd < "$file"
		[ -z "$cmd" ] && continue
		cmd_check=$(printf '%s' "$cmd" | sed 's/>.*$//;s/[[:space:]]*$//')
		
		case "$cmd_check" in
			*dns2socks*) cmd_check=${cmd_check//:/ } ;;
		esac

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

		if ! busybox pgrep -f "$cmd_check" >/dev/null; then
			restart_count=$((restart_count + 1))
			echo "$restart_count" > "$stats_file"
			#echo "${cmd} 进程挂掉，重启" >> /tmp/log/passwall.log
			sh -c "nohup $cmd 2>&1 &"
			sleep 1
		fi
	done

	# 每天清理一次统计文件（跨天后执行一次）
	current_date=$(date +%Y%m%d)
	if [ "$current_date" != "$last_cleanup_date" ]; then
		rm -f "${RESTART_STATS_DIR:?}"/* 2>/dev/null
		last_cleanup_date="$current_date"
	fi

	rm -f $LOCK_FILE
	sleep 58s
done
