# clashoo 运行日志格式化
# 输出: MM-DD HH:MM:SS msg

# mihomo 原生行: time="YYYY-MM-DDTHH:MM:SS..." level=... msg="..."
/^time="[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]T[0-9][0-9]:[0-9][0-9]:[0-9][0-9]/ {
	# extract YYYY-MM-DD and HH:MM:SS
	ts_date = substr($0, 7, 5)      # MM-DD
	ts_time = substr($0, 18, 8)     # HH:MM:SS
	utc_h = substr(ts_time, 1, 2) + 0
	cst_h = (utc_h + 8) % 24
	ts = sprintf("%s %02d:%s", ts_date, cst_h, substr(ts_time, 4))

	prefix = ""
	if (match($0, /level=warning /)) prefix = " [warn]"
	else if (match($0, /level=error /)) prefix = " [err]"
	else if (match($0, /level=fatal /)) prefix = " [fatal]"

	i = index($0, "msg=\"")
	if (i > 0) {
		rest = substr($0, i + 5)
		sub(/"[[:space:]]*$/, "", rest)
		print ts prefix " " rest
		next
	}
	print ts " " $0
	next
}

# log_msg 行: "  YYYY-MM-DD HH:MM:SS - msg" → "MM-DD HH:MM:SS msg"
/^[[:space:]]+[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9][[:space:]]+[0-9][0-9]:[0-9][0-9]:[0-9][0-9]/ {
	gsub(/^[[:space:]]+/, "")           # trim leading space
	ts_date = substr($0, 6, 5)          # MM-DD
	ts_time = substr($0, 12, 8)         # HH:MM:SS
	# remove "YYYY-MM-DD HH:MM:SS - " prefix
	sub(/^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9][[:space:]]+[0-9][0-9]:[0-9][0-9]:[0-9][0-9][[:space:]]*-[[:space:]]*/, "")
	print ts_date " " ts_time " " $0
	next
}

# 空行丢弃
NF == 0 { next }

{ print }
