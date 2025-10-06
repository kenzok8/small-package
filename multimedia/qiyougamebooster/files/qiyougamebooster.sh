#!/bin/sh

ACTION=$1

url="https://static.qiyou.cn/upgrade/ljb/plugin/qyplug.sh"
sh_file="/tmp/qyplug.sh"
ret_file="/tmp/qyplug.ret"
get_file="/tmp/qyplug.get"
pid_file="/tmp/qyplug.pid"
#get_qyplug="wget -q -T 30 \"${url}\" -O \"${sh_file}\" --no-check-certificate"
get_qyplug="curl -s -k -L -m 30 \"${url}\" -o \"${sh_file}\""

stop(){
	pid=`cat ${get_file} 2> /dev/null`
	echo "qy_acc stop: ${pid}"
	[ "${pid}" = "" ] || kill -9 ${pid}
	rm -rf ${get_file}

	sleep 1

	if [ -e /tmp/qyplug.sh ]; then
		sh /tmp/qyplug.sh stop
		rm -rf /tmp/qyplug.sh
	fi

	sleep 2
	rm -rf ${ret_file}

	if [ -e /tmp/qy ]; then
		cd /tmp/qy && ./init.sh stop
		rm -rf /tmp/qy
	fi
}

start(){
	pid=$$
	echo ${pid} > ${get_file}
	echo "qy_acc start: ${pid}"

	while true
	do
		rm -rf ${sh_file} ${ret_file}

		sh -c "${get_qyplug}"
		if [ -e ${sh_file} ]; then
			export QY_NOT_INSTALL=1
			sh ${sh_file} &
		fi

		sleep 3
		[ ! -e ${ret_file} ] || break
		sleep 30
	done

	rm -rf ${get_file}
}

switch(){
	act=$1

	if [ ! -d /tmp/qy ]; then
		echo "没安装"
		return
	fi

	if [ "${act}" = "on" ]; then
		cd /tmp/qy && ./init.sh &> /dev/null
	elif [ "${act}" = "off" ]; then
		cd /tmp/qy && ./init.sh stop &> /dev/null
	fi
}

status(){
	status=`cat ${ret_file} 2> /dev/null`
	get=`cat ${get_file} 2> /dev/null`
	pid=`cat ${pid_file} 2> /dev/null`
	acc=`pidof qy_acc 2> /dev/null`

	if [ "${status}" = "succeeded" ]; then
		if [ ! -d /tmp/qy ]; then
			printf "NOT ENABLED"
		elif [ "${acc}" = "" ]; then
			printf "CLOSED"
		elif [ -d /sys/class/net/tun31 ] || [ -d /sys/class/net/tun32 ]; then
			printf "BOOSTING"
		else
			printf "RUNNING"
		fi
		return
	fi
	if [ "${status}" = "notsupport" ]; then
		printf "NOT SUPPORTED"
		return
	fi
	if [ "${status}" = "getpkgerr" ]; then
		printf "DOWNLOADING"
		return
	fi
	if [ "${get}" != "" ] && [ -e "/proc/${get}" ]; then
		printf "INSTALLING"
		return
	fi
	if [ "${pid}" != "" ] && [ -e "/proc/${pid}" ]; then
		printf "INSTALLING"
		return
	fi
	if [ ! -d /tmp/qy ]; then
		printf "NOT ENABLED"
		return
	fi
	printf "NOT RUNNING"
}

version(){
	ver=`sed -n 's;^VERSION=;;p' /tmp/qy/etc/PKG_INFO 2> /dev/null`
	printf "${ver}"
}

case $ACTION in
stop)
	stop
	;;
start)
	stop
	start
	;;
status)
	status
	;;
enable)
	switch on
	;;
disable)
	switch off
	;;
version)
	version
	;;
*)
	start
	;;
esac
