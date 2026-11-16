#!/bin/bash
# NATMap
outter_ip=$1
outter_port=$2
ip4p=$3
inner_port=$4
protocol=$(echo $5 | tr 'a-z' 'A-Z')

# 构建消息内容
msg="${GENERAL_NAT_NAME}
New ${protocol} port mapping: ${inner_port} -> ${outter_ip}:${outter_port}
IP4P: ${ip4p}"
if [ ! -z "$MSG_OVERRIDE" ]; then
	msg="$MSG_OVERRIDE"
fi

# 设置重试次数和时间间隔
max_retries=1
sleep_time=1

# 判断是否开启高级功能
if [ "${NOTIFY_ADVANCED_ENABLE}" == 1 ]; then
	max_retries=$NOTIFY_ADVANCED_MAX_RETRIES
	sleep_time=$NOTIFY_ADVANCED_SLEEP_TIME
else
	# 默认重试次数为1，休眠时间为1s
	max_retries=1
	sleep_time=1
fi

# notify_mode 判断
notify_script=""
case $NOTIFY_MODE in
"telegram_bot")
	notify_script="/usr/share/natmap/plugin-notify/telegram_bot.sh"
	;;
"pushplus")
	notify_script="/usr/share/natmap/plugin-notify/pushplus.sh"
	;;
"serverchan")
	notify_script="/usr/share/natmap/plugin-notify/serverchan.sh"
	;;
"gotify")
	notify_script="/usr/share/natmap/plugin-notify/gotify.sh"
	;;
*)
	notify_script=""
	;;
esac

# # 如果$NOTIFY_MODE非空则执行对应的脚本
# if [ -n "${NOTIFY_MODE}" ]; then
# 	notify_script="/usr/share/natmap/plugin-notify/$NOTIFY_MODE.sh"
# fi

if [ -n "${notify_script}" ]; then
	echo "$(date +'%Y-%m-%d %H:%M:%S') : $GENERAL_NAT_NAME execute notify script" >>/var/log/natmap/natmap.log
	echo "$(date +'%Y-%m-%d %H:%M:%S') : $GENERAL_NAT_NAME execute notify script"
	bash "$notify_script" "$msg" "$max_retries" "$sleep_time"
fi
