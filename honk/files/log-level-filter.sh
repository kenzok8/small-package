#!/bin/sh
# SPDX-License-Identifier: GPL-3.0-only

requested=$1
case "$requested" in all|debug|info|warn|error) ;; *) exit 2 ;; esac

awk -v requested="$requested" '
function rank(level) {
	if (level == "DEBUG" || level == "TRACE") return 0
	if (level == "INFO" || level == "NOTICE") return 1
	if (level == "WARN" || level == "WARNING") return 2
	if (level == "ERROR" || level == "FATAL" || level == "CRIT" || level == "CRITICAL" || level == "ALERT" || level == "EMERG") return 3
	return -1
}
function from_syslog(header, token, parts, count, level) {
	count = split(header, parts, /[[:space:]]+/)
	for (i = 1; i <= count; i++) {
		token = parts[i]
		if (token ~ /^[[:alnum:]_-]+\.(debug|info|notice|warn|warning|err|error|crit|critical|alert|emerg)$/) {
			sub(/^.*\./, "", token)
			if (token == "err") token = "error"
			return rank(toupper(token))
		}
	}
	return -1
}
{
	if (requested == "all" || requested == "debug") { print; next }
	line = $0
	header = line
	message = ""
	separator = index(line, "]: ")
	if (separator > 0) {
		header = substr(line, 1, separator + 1)
		message = substr(line, separator + 3)
	} else {
		separator = index(line, ": ")
		if (separator > 0) {
			header = substr(line, 1, separator - 1)
			message = substr(line, separator + 2)
		}
	}
	sub(/^[0-9][0-9][0-9][0-9]-[0-9T:.+Z-]+[[:space:]]+/, "", message)
	sub(/^[[:space:]]+/, "", message)
	if (match(message, /^(TRACE|DEBUG|INFO|NOTICE|WARN|WARNING|ERROR|FATAL|CRIT|CRITICAL|ALERT|EMERG)([[:space:]:]|$)/)) {
		level = message
		sub(/[[:space:]:].*$/, "", level)
		severity = rank(level)
	} else if (match(line, /^<[0-7]>/)) {
		priority = substr(line, 2, 1) + 0
		severity = priority <= 3 ? 3 : priority == 4 ? 2 : priority <= 6 ? 1 : 0
	} else {
		severity = from_syslog(header)
	}
	threshold = requested == "info" ? 1 : requested == "warn" ? 2 : 3
	if (severity >= threshold) print
}'
