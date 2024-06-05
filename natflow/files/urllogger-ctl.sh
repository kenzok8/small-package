#!/bin/sh


test -c /dev/urllogger_queue || exit 1

urllogger_stop()
{
	echo "0" >/proc/sys/urllogger_store/enable
	echo clear >/dev/urllogger_queue
	return 0
}

urllogger_start()
{
	echo "1" >/proc/sys/urllogger_store/enable
}

urllogger_read()
{
	UP=$(cat /proc/uptime | cut -d\. -f1)
	UP=$((UP&0xffffffff))
	NOW=$(date +%s)
	cat /dev/urllogger_queue | sed 's/,/ /' | while read time data; do
		T=$((NOW+time-UP))
		T=$(date "+%Y-%m-%d %H:%M:%S" -d @$T)
		echo $T,$data
	done
}

[ "$1" = "stop" ] && urllogger_stop && exit 0
[ "$1" = "start" ] && urllogger_start && exit 0
[ "$1" = "read" ] && urllogger_read && exit 0

echo "usage: $0 start|stop|read"
exit 0
