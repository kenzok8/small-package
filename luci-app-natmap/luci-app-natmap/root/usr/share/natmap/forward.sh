#!/bin/bash
# NATMap
outter_ip=$1
outter_port=$2
ip4p=$3
inner_port=$4
protocol=$5

# 如果$forward_target_port为空或者$forward_target_ip为空则退出
if [ -z "$FORWARD_TARGET_PORT" ] || [ -z "$FORWARD_TARGET_IP" ]; then
    exit 0
fi

# 设置重试次数和时间间隔
max_retries=1
sleep_time=1

# 判断是否开启高级功能
if [ "${FORWARD_ADVANCED_ENABLE}" == 1 ]; then
	max_retries=$FORWARD_ADVANCED_MAX_RETRIES
	sleep_time=$FORWARD_ADVANCED_SLEEP_TIME
else
	# 默认重试次数为1，休眠时间为1s
	max_retries=1
	sleep_time=1
fi

forward_script=""
case $FORWARD_MODE in
"firewall")
    forward_script="/usr/share/natmap/plugin-forward/firewall-forward.sh"
    ;;
"ikuai")
    forward_script="/usr/share/natmap/plugin-forward/ikuai-forward.sh"
    ;;
*)
    forward_script=""
    ;;
esac

if [ -n "${forward_script}" ]; then
    echo "$(date +'%Y-%m-%d %H:%M:%S') : $GENERAL_NAT_NAME execute forward script" >>/var/log/natmap/natmap.log
    echo "$(date +'%Y-%m-%d %H:%M:%S') : $GENERAL_NAT_NAME execute forward script"
    bash "$forward_script" "$outter_ip" "$outter_port" "$ip4p" "$inner_port" "$protocol" "$max_retries" "$sleep_time"
fi
