#!/bin/bash
# NATMap
outter_ip=$1
outter_port=$2
ip4p=$3
inner_port=$4
protocol=$5

link_script=""
# echo "LINK_MODE: $LINK_MODE"

# 设置重试次数和时间间隔
max_retries=1
sleep_time=1

# 判断是否开启高级功能
if [ "${LINK_ADVANCED_ENABLE}" == 1 ]; then
	max_retries=$LINK_ADVANCED_MAX_RETRIES
	sleep_time=$LINK_ADVANCED_SLEEP_TIME
else
	# 默认重试次数为1，休眠时间为1s
	max_retries=1
	sleep_time=1
fi

# 如果$LINK_MODE非空则执行对应的脚本
case "${LINK_MODE}" in
"cloudflare_ddns")
	link_script="/usr/share/natmap/plugin-link/cloudflare_ddns.sh"
	;;
"cloudflare_origin_rule")
	link_script="/usr/share/natmap/plugin-link/cloudflare_origin_rule.sh"
	;;
"cloudflare_redirect_rule")
	link_script="/usr/share/natmap/plugin-link/cloudflare_redirect_rule.sh"
	;;
"emby")
	link_script="/usr/share/natmap/plugin-link/emby.sh"
	;;
"qbittorrent")
	link_script="/usr/share/natmap/plugin-link/qbittorrent.sh"
	;;
"transmission")
	link_script="/usr/share/natmap/plugin-link/transmission.sh"
	;;
*)
	link_script=""
	;;
esac

# if [ -n "${LINK_MODE}" ]; then
#     link_script="/usr/share/natmap/plugin-link/${LINK_MODE}.sh"
# fi

if [ -n "${link_script}" ]; then
	echo "$(date +'%Y-%m-%d %H:%M:%S') : $GENERAL_NAT_NAME execute link script" >>/var/log/natmap/natmap.log
	echo "$(date +'%Y-%m-%d %H:%M:%S') : $GENERAL_NAT_NAME execute link script"
	bash "${link_script}" "$outter_ip" "$outter_port" "$ip4p" "$inner_port" "$protocol" "$max_retries" "$sleep_time"
fi
