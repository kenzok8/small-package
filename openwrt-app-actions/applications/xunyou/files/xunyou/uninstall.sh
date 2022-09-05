#!/bin/sh

source /etc/profile

systemType=0
action=$1
ifname=$(
    . /lib/functions/network.sh

    network_is_up "lan" || exit 1
    network_get_device device "lan"
    printf "%s" "${device:-br-lan}"
)
[ -z "$ifname" ] && ifname="br-lan"

UdpPostProc="udp-post"
product_model=`uname -n`

#等待插件回复完消息后再卸载
sleep 1

BasePath=""

unbind_api="https://router-wan.xunyou.com:9004/v2/core/removeuserrouter"

get_json_value()
{
    local json=${1}
    local key=${2}
    local num=1
    local value=$(echo "${json}" | awk -F"[,:}]" '{for(i=1;i<=NF;i++){if($i~/'${key}'\042/){print $(i+1)}}}' | tr -d '"' | sed -n ${num}p)
    echo ${value}
}

send_unbind_msg()
{
    #远程卸载和升级卸载不需要发送解绑消息
    if [ "${action}" != "remote" -a "${action}" != "upgrade" ]; then
        if [ -e ${BasePath}/xunyou/configs/xunyou-user ]; then
            value=`cat ${BasePath}/xunyou/configs/xunyou-user`
            key="userId"
            userId=$(get_json_value $value $key)
            [ -z "${userId}" ] && return

            data='{"userid":"'${userId}'"}'

            curl -H "Content-Type: application/json" -X POST -d '{"userid":"'${userId}'"}' "${unbind_api}" > /dev/null 2&>1
        fi
    fi
}

xunyou_post_uninstall_log()
{
    [ ! -e "${BasePath}/xunyou/bin/${UdpPostProc}" ] && return 0
    #
    tmpfile="/tmp/.xy-post.log"
    value=`cat ${BasePath}/xunyou/configs/xunyou-user` >/dev/null 2>&1
    key="userName"
    userName=$(get_json_value $value $key)
    #
    mac=`ip address show ${ifname} | grep link/ether | awk -F ' ' '{print $2}'`
    [ -z "${mac}" ] && return 0
    #
    time=`date +"%Y-%m-%d %H:%M:%S"`
    #
    guid=`echo -n ''${mac}'merlinrouterxunyou2020!@#$' | md5sum | awk -F ' ' '{print $1}'`
    #
    publicIp_json=$(curl https://router.xunyou.com/index.php/Info/getClientIp) >/dev/null 2>&1
    key="ip"
    publicIp=$(get_json_value $publicIp_json $key)
    #
    data='{"id":1003,"user":"'${userName}'","mac":"'${mac}'","data":{"type":8,"account":"'${userName}'","model":"'${product_model}'","guid":"'${guid}'","mac":"'${mac}'","publicIp":"'${publicIp}'","source":0,"reporttime":"'${time}'"}}'
    echo ${data} > ${tmpfile}
    #
    ${BasePath}/xunyou/bin/${UdpPostProc} -d "acceldata.xunyou.com" -p 9240 -f ${tmpfile} >/dev/null 2>&1 &
}

send_unbind_msg

xunyou_post_uninstall_log &

sh ${BasePath}/xunyou/scripts/xunyou_config.sh stop

if [ "${action}" == "upgrade" ]; then
    [ -e ${BasePath}/xunyou/configs/xunyou-user ] && cp -af ${BasePath}/xunyou/configs/xunyou-user /tmp/
    [ -e ${BasePath}/xunyou/configs/xunyou-device_v2 ] && cp -af ${BasePath}/xunyou/configs/xunyou-device_v2 /tmp/
    [ -e ${BasePath}/xunyou/configs/xunyou-game ] && cp -af ${BasePath}/xunyou/configs/xunyou-game /tmp/
else
    rm -f /tmp/xunyou-user*
    rm -f /tmp/xunyou-device*
    rm -f /tmp/xunyou-game*
fi

rm -rf ${BasePath}/xunyou/
rm -rf /tmp/xunyou_*
