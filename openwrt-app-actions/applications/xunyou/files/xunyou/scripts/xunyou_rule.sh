#!/bin/bash

server=$2
gateway=${3}
port=${4}
device=${5}
rtName="95"
AccChainName="XUNYOUACC"

#
node_ip=`echo ${server} | awk -F '=' '{print $2}'`
device1=`echo ${device} | awk -F '&' '{print $1}' | awk -F '=' '{print $2}'`
device2=`echo ${device} | awk -F '&' '{print $2}' | awk -F '=' '{print $2}'`
gateway=`echo ${gateway} | awk -F '=' '{print $2}'`
port=`echo ${port} | awk -F '=' '{print $2}'`

[ -z "${device1}" -a -z "${device2}" ] && exit 1
[ "${device1}" == "0.0.0.0" -a "${device2}" == "0.0.0.0" ] && exit 1

#
check_depend_env()
{
    local ret=`lsmod | grep xt_TPROXY`
    [ -n "${ret}" ] && echo 0 && return 0
    #
    modprobe xt_TPROXY
}

acc_rule_config()
{
    #配置mangle表
    local ret=`iptables -t mangle -S | grep ${AccChainName}`
    [ -z "${ret}" ] && iptables -t mangle -N ${AccChainName}
    iptables -t mangle -F ${AccChainName}

    #配置nat表
    ret=`iptables -t nat -S | grep ${AccChainName}`
    [ -z "${ret}" ] && iptables -t nat -N ${AccChainName}
    iptables -t nat -F ${AccChainName}

    #
    if [ -n "${device1}" -a "${device1}" != "0.0.0.0" ]; then
        #
        markNum=`echo ${device1} | awk -F '.' '{printf "0x%02x%02x%02x%02x",$1,$2,$3,$4}'`
        #
        ret=`ip rule | grep "${device1}"`
        [ -z "${ret}" ] && ip rule add fwmark ${markNum} pref 98 table ${rtName}
        #
        iptables -t nat -A ${AccChainName} -s ${device1} -p tcp -j DNAT --to-destination ${gateway}:${port}

        iptables -t mangle -A ${AccChainName} -s ${device1} -p udp -j TPROXY --tproxy-mark ${markNum} --on-ip 127.0.0.1 --on-port ${port}
        iptables -t mangle -A ${AccChainName} -p udp --dport 53 -j TPROXY --tproxy-mark ${markNum} --on-ip 127.0.0.1 --on-port ${port}
    fi

    if [ -n "${device2}" -a "${device2}" != "0.0.0.0" ]; then
        #
        markNum=`echo ${device2} | awk -F '.' '{printf "0x%02x%02x%02x%02x",$1,$2,$3,$4}'`
        #
        ret=`ip rule | grep "${device2}"`
        [ -z "${ret}" ] && ip rule add fwmark ${markNum} pref 99 table ${rtName}
        #
        iptables -t nat -A ${AccChainName} -s ${device2} -p tcp -j DNAT --to-destination ${gateway}:${port}

        iptables -t mangle -A ${AccChainName} -s ${device2} -p udp -j TPROXY --tproxy-mark ${markNum} --on-ip 127.0.0.1 --on-port ${port}
        iptables -t mangle -A ${AccChainName} -p udp --dport 53 -j TPROXY --tproxy-mark ${markNum} --on-ip 127.0.0.1 --on-port ${port}
    fi

    ret=`ip rule | grep "lookup ${rtName}"`
    [ -n "${ret}" ] && ip route flush table ${rtName} && ip route add local default dev lo table ${rtName}
}

del_iptables_rule()
{
    iptables -t mangle -n -L ${AccChainName} >/dev/null 2>&1 && iptables -t mangle -F ${AccChainName}
    iptables -t nat -n -L ${AccChainName} >/dev/null 2>&1 && iptables -t nat -F ${AccChainName}
}

del_ip_rule()
{
    #
    ret=`ip rule | grep "lookup ${rtName}"`
    [ -n "${ret}" ] && ip route flush table ${rtName}
    #
    if [ -n "${device1}" -a "${device1}" != "0.0.0.0" ]; then
        ret=`ip rule | grep "${device1}"`
        [ -n "${ret}" ] && ip rule del table ${rtName}
    fi
    #
    if [ -n "${device2}" -a "${device2}" != "0.0.0.0" ]; then
        ret=`ip rule | grep "${device2}"`
        [ -n "${ret}" ] && ip rule del table ${rtName}
    fi
    #
    ret=`ip rule | grep "lookup ${rtName}"`
    [ -n "${ret}" ] && ip rule del table ${rtName}
}

clear_rule_config()
{
    #
    del_ip_rule
    #
    del_iptables_rule
}

proc_client_online()
{
    #echo $node_ip, ${gateway}, ${port}, ${device1}, ${device2}
    #
    local ret=$(check_depend_env)
    [ ${ret} != 0 ] && return 1
    #
    clear_rule_config
    acc_rule_config
}

proc_client_offline()
{
    #echo $node_ip, ${gateway}, ${port}, ${device1}, ${device2}
    #
    clear_rule_config
}

case $1 in
    "client-online")
        proc_client_online
        ;;

    "client-offline")
        proc_client_offline
        ;;
esac
