#!/bin/sh

source /etc/profile

BasePath=""

ifname=$(
    . /lib/functions/network.sh

    network_is_up "lan" || exit 1
    network_get_device device "lan"
    printf "%s" "${device:-br-lan}"
)
[ -z "$ifname" ] && ifname="br-lan"

XunyouPath="${BasePath}/xunyou"
LibPath="${XunyouPath}/lib"
kernelKoPath="${XunyouPath}/modules"

RouteCfg="${XunyouPath}/configs/RouteCfg.conf"
ProxyCfg="${XunyouPath}/configs/ProxyCfg.conf"
IpsetCfg="${XunyouPath}/configs/IpsetCfg.conf"
UserInfo="${XunyouPath}/configs/xunyou-user"
GameInfo="${XunyouPath}/configs/xunyou-game"
DeviceInfo="${XunyouPath}/configs/xunyou-device_v2"
IpsetEnableCfg="${XunyouPath}/configs/ipset_enable"
CertificateFile="${XunyouPath}/configs/server.crt"
PrivateKeyFile="${XunyouPath}/configs/server.key"

logPath="${XunyouPath}/log/xunyou-running.log"
RouteLog="${XunyouPath}/log/xunyou-ctrl.log"
ProxyLog="${XunyouPath}/log/xunyou-proxy.log"
IpsetLog="${XunyouPath}/log/xunyou-ipset.log"

ProxyScript="${XunyouPath}/scripts/xunyou_rule.sh"
UpdateScript="${XunyouPath}/scripts/xunyou_upgrade.sh"
CfgScript="${XunyouPath}/scripts/xunyou_config.sh"

CtrlProc="xy-ctrl"
ProxyProc="xy-proxy"
IpsetProc="xy-ipset"
UdpPostProc="udp-post"

DnsmasqCfgFile="/var/etc/dnsmasq.conf.cfg01411c"
ChainName="XUNYOU"
AccChainName="XUNYOUACC"
rtName="95"

LocalDomain="router-lan.xyrouterqpm3v2bi.cc"
LocalDomainHex="|0a|router-lan|10|xyrouterqpm3v2bi|02|cc"

product_vendor="LINKEASE"
product_model="ARS2"
product_version=`cat /etc/openwrt_version`
kernel_version="uname -r"
INSTALL_CONFIG_URL=""
INSTALL_CONFIG="/tmp/xunyou_install.json"
INSTALL_TAR_URL="https://partnerdownload.xunyou.com/routeplugin/install.tar.gz"
INSTALL_TAR="/tmp/xunyou_install.tar.gz"
INSTALL_SHELL="/tmp/xunyou/install.sh"
ROUTE_INFO_URL="https://router.xunyou.com/index.php/vendor/get-info"

IpsetEnable="0"

gateway=`ip address show ${ifname} | grep "\<inet\>" | awk -F ' ' '{print $2}' | awk -F '/' '{print $1}'`
[ -z "${gateway}" ] && exit 1

[ ! -f ${XunyouPath}/version ] && exit 1

VERSION=`cat ${XunyouPath}/version`
[ -z "${VERSION}" ] && exit 1

log()
{
    echo [`date +"%Y-%m-%d %H:%M:%S"`] "${1}" >> ${logPath}
}

get_json_value()
{
    local json=${1}
    local key=${2}
    local num=1
    local value=$(echo "${json}" | awk -F"[,:}]" '{for(i=1;i<=NF;i++){if($i~/'${key}'\042/){print $(i+1)}}}' | tr -d '"' | sed -n ${num}p)
    echo ${value}
}

xunyou_post_start_log()
{
    [ ! -e "${XunyouPath}/bin/${UdpPostProc}" ] && return 0
    #
    tmpfile="/tmp/.xy-post.log"
    value=`cat ${UserInfo}` >/dev/null 2>&1
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
    start_status=0
    ctrlPid=`ps | grep -v grep | grep -w ${CtrlProc} | awk -F ' ' '{print $1}'`
    proxyPid=`ps | grep -v grep | grep -w ${ProxyProc} | awk -F ' ' '{print $1}'`
    ipsetPid=`ps | grep -v grep | grep -w ${IpsetProc} | awk -F ' ' '{print $1}'`

    if [ ${IpsetEnable} == "1" ]; then
        [ -n "${ctrlPid}" -a -n "${proxyPid}" -a -n "${ipsetPid}" ] && start_status=1
    else
        [ -n "${ctrlPid}" -a -n "${proxyPid}" ] && start_status=1
    fi
    #
    data='{"id":1003,"user":"'${userName}'","mac":"'${mac}'","data":{"type":6,"account":"'${userName}'","model":"'${product_model}'","guid":"'${guid}'","mac":"'${mac}'","publicIp":"'${publicIp}'","source":0,"success":'${start_status}',"reporttime":"'${time}'"}}'
    echo ${data} > ${tmpfile}
    #
    ${XunyouPath}/bin/${UdpPostProc} -d "acceldata.xunyou.com" -p 9240 -f ${tmpfile} >/dev/null 2>&1 &
}

xunyou_post_stop_log()
{
    [ ! -e "${XunyouPath}/bin/${UdpPostProc}" ] && return 0
    #
    tmpfile="/tmp/.xy-post.log"
    value=`cat ${UserInfo}` >/dev/null 2>&1
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
    data='{"id":1003,"user":"'${userName}'","mac":"'${mac}'","data":{"type":9,"account":"'${userName}'","model":"'${product_model}'","guid":"'${guid}'","mac":"'${mac}'","publicIp":"'${publicIp}'","source":0,"reporttime":"'${time}'"}}'
    echo ${data} > ${tmpfile}
    #
    ${XunyouPath}/bin/${UdpPostProc} -d "acceldata.xunyou.com" -p 9240 -f ${tmpfile} >/dev/null 2>&1 &
}

xunyou_post_crash_log()
{
    [ ! -e "${XunyouPath}/bin/${UdpPostProc}" ] && return 0
    #
    process=${1}
    tmpfile="/tmp/.xy-post.log"
    value=`cat ${UserInfo}` >/dev/null 2>&1
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
    data='{"id":1003,"user":"'${userName}'","mac":"'${mac}'","data":{"type":5,"account":"'${userName}'","model":"'${product_model}'","guid":"'${guid}'","mac":"'${mac}'","publicIp":"'${publicIp}'","crashdll":"'${process}'","reporttime":"'${time}'"}}'
    echo ${data} > ${tmpfile}
    #
    ${XunyouPath}/bin/${UdpPostProc} -d "acceldata.xunyou.com" -p 9240 -f ${tmpfile} >/dev/null 2>&1 &
}

iptables_rule_cfg()
{
    #添加mangle表规则
    iptables -t mangle -n -L ${ChainName} >/dev/null 2>&1 || iptables -t mangle -N ${ChainName}
    iptables -t mangle -n -L ${AccChainName} >/dev/null 2>&1 || iptables -t mangle -N ${AccChainName}
    iptables -t mangle -C PREROUTING -i ${ifname} -p udp -j ${ChainName} >/dev/null 2>&1 || iptables -t mangle -I PREROUTING -i ${ifname} -p udp -j ${ChainName}
    iptables -t mangle -F ${ChainName}
    iptables -t mangle -A ${ChainName} -p udp -j ${AccChainName}
    iptables -t mangle -A ${ChainName} -d ${gateway} -j ACCEPT
    iptables -t mangle -A ${ChainName} -i ${ifname} -p udp --dport 53 -m string --hex-string "${LocalDomainHex}" --algo kmp -j ACCEPT

    #添加nat表规则
    iptables -t nat -n -L ${ChainName} >/dev/null 2>&1 || iptables -t nat -N ${ChainName}
    iptables -t nat -n -L ${AccChainName} >/dev/null 2>&1 || iptables -t nat -N ${AccChainName}
    iptables -t nat -C PREROUTING -i ${ifname} -j ${ChainName} >/dev/null 2>&1 || iptables -t nat -I PREROUTING -i ${ifname} -j ${ChainName}
    iptables -t nat -F ${ChainName}
    iptables -t nat -A ${ChainName} -p tcp -j ${AccChainName}
    iptables -t nat -A ${ChainName} -d ${gateway} -j ACCEPT
    iptables -t nat -A ${ChainName} -i ${ifname} -p udp --dport 53 -m string --hex-string "${LocalDomainHex}" --algo kmp -j DNAT --to-destination ${gateway}
}

set_dnsmasq_config()
{
    if [ -f ${DnsmasqCfgFile} ]; then
        DnsConfDir=`awk -F "=" '$1=="conf-dir" {print $2}' ${DnsmasqCfgFile}`
        AddnHostsDir=`awk -F "=" '$1=="addn-hosts" {print $2}' ${DnsmasqCfgFile}`

        if [ -n "${DnsConfDir}" -a -d ${DnsConfDir} ]; then
            echo "address=/${LocalDomain}/${gateway}" > ${DnsConfDir}/xunyou.conf
            echo "local-ttl=120" >> ${DnsConfDir}/xunyou.conf
            /etc/init.d/dnsmasq restart >/dev/null 2>&1
            return 0
        elif [ -n "${AddnHostsDir}" -a -d ${AddnHostsDir} ]; then
            echo "${gateway} ${LocalDomain}" > ${AddnHostsDir%*/}/${LocalDomain}
            /etc/init.d/dnsmasq restart >/dev/null 2>&1
            return 0
        fi
    fi

    ret=`cat /etc/hosts | grep "${LocalDomain}"`
    [ -n "${ret}" ] && return 0

    /etc/init.d/dnsmasq restart >/dev/null 2>&1
}

ipset_check()
{
    if [ -f ${IpsetEnableCfg} ]; then
        IpsetEnable=`cat ${IpsetEnableCfg}`
        return
    fi

    ipset_cmd=`type -p ipset`
    if [ -z "${ipset_cmd}" ]; then
        if [ -f ${kernelKoPath}/${kernel_version}/bin/ipset ]; then
            ipset_cmd="${kernelKoPath}/${kernel_version}/bin/ipset"
        else
            IpsetEnable="1"
            echo -n ${IpsetEnable} > ${IpsetEnableCfg}
            return
        fi
    fi

    ${ipset_cmd} -! create test_net hash:net || IpsetEnable="1"
    ${ipset_cmd} destroy test_net || IpsetEnable="1"
    ${ipset_cmd} -! create test_netport hash:net,port || IpsetEnable="1"
    ${ipset_cmd} destroy test_netport || IpsetEnable="1"

    echo -n ${IpsetEnable} > ${IpsetEnableCfg}
}

create_config_file()
{
    mac=`ip address show ${ifname} | grep link/ether | awk -F ' ' '{print $2}'`
    [ -z "${mac}" ] && return 1

    builtin="false"
    #
    sed -i 's/\("version":"\).*/\1'${VERSION}'",/g' ${RouteCfg}
    sed -i 's#\("built-in":\).*#\1'${builtin}',#g'    ${RouteCfg}
    sed -i 's/\("httpd-svr":"\).*/\1'${gateway}'",/g' ${RouteCfg}
    sed -i 's/\("route-mac":"\).*/\1'${mac}'",/g'     ${RouteCfg}
    sed -i 's#\("log":"\).*#\1'${RouteLog}'",#g'      ${RouteCfg}
    sed -i 's/\("net-device":"\).*/\1'${ifname}'",/g'              ${RouteCfg}
    sed -i 's#\("upgrade-shell":"\).*#\1'${UpdateScript}'",#g'     ${RouteCfg}
    sed -i 's#\("user-info":"\).*#\1'${UserInfo}'",#g'             ${RouteCfg}
    sed -i 's#\("device-info":"\).*#\1'${DeviceInfo}'",#g'         ${RouteCfg}
    sed -i 's#\("game-info":"\).*#\1'${GameInfo}'",#g'             ${RouteCfg}
    sed -i 's#\("ipset-enable":\).*#\1'${IpsetEnable}',#g'         ${RouteCfg}
    sed -i 's#\("product-vendor":"\).*#\1'"${product_vendor}"'",#g'  ${RouteCfg}
    sed -i 's#\("product-model":"\).*#\1'${product_model}'",#g'      ${RouteCfg}
    sed -i 's#\("product-version":"\).*#\1'${product_version}'",#g'  ${RouteCfg}
    #
    sed -i 's/\("local-ip":"\).*/\1'${gateway}'",/g'             ${ProxyCfg}
    sed -i 's#\("local-domain":"\).*#\1'${LocalDomain}'",#g'     ${ProxyCfg}
    sed -i 's#\("log":"\).*#\1'${ProxyLog}'",#g'                 ${ProxyCfg}
    sed -i 's#\("script-cfg":"\).*#\1'${ProxyScript}'",#g'       ${ProxyCfg}
    sed -i 's#\("ipset-enable":\).*#\1'${IpsetEnable}',#g'       ${ProxyCfg}
    sed -i 's#\("certificate-file":"\).*#\1'${CertificateFile}'",#g' ${ProxyCfg}
    sed -i 's#\("private-key-file":"\).*#\1'${PrivateKeyFile}'",#g'       ${ProxyCfg}
    #
    sed -i 's/\("local-ip":"\).*/\1'${gateway}'",/g'        ${IpsetCfg}
    sed -i 's#\("log":"\).*#\1'${IpsetLog}'",#g'            ${IpsetCfg}
}

rule_init()
{
    ko_path=`find /lib/modules/ -name nf_defrag_ipv6.ko`
    if [ -n "${ko_path}" ]; then
        insmod ${ko_path} >/dev/null 2>&1
    elif [ -f ${kernelKoPath}/${kernel_version}/kernel/nf_defrag_ipv6.ko ]; then
        insmod ${kernelKoPath}/${kernel_version}/kernel/nf_defrag_ipv6.ko >/dev/null 2>&1
    fi

    ko_path=`find /lib/modules/ -name xt_TPROXY.ko`
    if [ -n "${ko_path}" ]; then
        insmod ${ko_path} >/dev/null 2>&1
    elif [ -f ${kernelKoPath}/${kernel_version}/kernel/xt_TPROXY.ko ]; then
        insmod ${kernelKoPath}/${kernel_version}/kernel/xt_TPROXY.ko >/dev/null 2>&1
    fi
}

check_upgrade()
{
    resp_info_json=$(curl -k -X POST -H "Content-Type: application/json" -d '{"alias":"'"${product_vendor}"'","model":"'"${product_model}"'","version":"'"${product_version}"'"}' "${ROUTE_INFO_URL}") > /dev/null 2>&1
    if [ $? -ne 0 ] ;then
        log "curl get info failed!"
        return 0
    fi

    resp_info_json=`echo ${resp_info_json} | sed "s/https://"`
    #判断网站返回的info信息是否正确
    msg_id="id"
    id_value=$(get_json_value $resp_info_json $msg_id)

    if [ -z "${id_value}" ];then
        log "cannot find the msgid"
        return 0
    fi

    if [ ${id_value} -ne 1 ];then
        log "the msgid is error: $id_value"
        return 0
    fi

    #获取install.json的下载路径
    key="url"
    url_value=$(get_json_value $resp_info_json $key)
    if [ -z "${url_value}" ];then
        log "cannet find the install config file url"
        return 0
    fi

    INSTALL_CONFIG_URL="https:"${url_value}
    INSTALL_CONFIG_URL=$(echo ${INSTALL_CONFIG_URL} | sed 's/\\//g')

    #下载install.json
    rm -f ${INSTALL_CONFIG}

    wget --no-check-certificate -O ${INSTALL_CONFIG} ${INSTALL_CONFIG_URL} > /dev/null 2>&1
    if [ $? -ne 0 ];then
        log "wget install config file failed"
        return 0
    fi

    #比较版本号
    json=$(sed ':a;N;s/\n//g;ta' ${INSTALL_CONFIG})
    versionString=$(echo $json | awk -F"," '{print $3}' | sed s/\"//g)
    versionString=${versionString#*:}

    major_number=$(echo $versionString | cut -d. -f1)
    minor_number=$(echo $versionString | cut -d. -f2)
    revision_number=$(echo $versionString | cut -d. -f3)
    build_number=$(echo $versionString | cut -d. -f4)

    cur_major_number=$(echo $VERSION | cut -d. -f1)
    cur_minor_number=$(echo $VERSION | cut -d. -f2)
    cur_revision_number=$(echo $VERSION | cut -d. -f3)
    cur_build_number=$(echo $VERSION | cut -d. -f4)

    rm -f ${INSTALL_CONFIG}

    if [ ${major_number} -gt ${cur_major_number} ]; then
        return 1
    elif [ ${major_number} -eq ${cur_major_number} ]; then
        if [ ${minor_number} -gt ${cur_minor_number} ]; then
            return 1
        elif [ ${minor_number} -eq ${cur_minor_number} ]; then
            if [ ${revision_number} -gt ${cur_revision_number} ]; then
                return 1
            elif [ ${revision_number} -eq ${cur_revision_number} ]; then
                if [ ${build_number} -gt ${cur_build_number} ]; then
                    return 1
                fi
            fi
        fi
    fi

    return 0
}

execute_upgrade()
{
    #下载安装包
    wget --no-check-certificate -O ${INSTALL_TAR} ${INSTALL_TAR_URL} > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        log "wget install tar file failed!"
        return 1
    fi

    #解压缩安装包
    tar -C /tmp -xzf ${INSTALL_TAR}

    #执行安装更新程序
    sh ${INSTALL_SHELL} &

    return 0
}

xunyou_acc_start()
{
    set_dnsmasq_config
    #
    iptables_rule_cfg
    #
    create_config_file
    #
    ret=`echo $LD_LIBRARY_PATH | grep ${LibPath}`
    [ -z "${ret}" ] && export LD_LIBRARY_PATH=${LibPath}:$LD_LIBRARY_PATH
    ulimit -n 2048
    #
    #ulimit -c unlimited
    #echo "/tmp/core-%e-%p" > /proc/sys/kernel/core_pattern

    #echo 1 > /proc/sys/vm/overcommit_memory
    sleep 3

    nohup ${XunyouPath}/bin/${CtrlProc}  --config ${RouteCfg} >/dev/null 2>&1 &
    nohup ${XunyouPath}/bin/${ProxyProc} --config ${ProxyCfg} >/dev/null 2>&1 &
    if [ ${IpsetEnable} == "1" ]; then
        nohup ${XunyouPath}/bin/${IpsetProc} --config ${IpsetCfg} >/dev/null 2>&1 &
    fi
}

xunyou_clear_rule()
{
    ip route del table ${rtName} >/dev/null 2>&1
    ip rule del table ${rtName} >/dev/null 2>&1

    iptables -t mangle -F ${ChainName} >/dev/null 2>&1
    iptables -t mangle -F ${AccChainName} >/dev/null 2>&1
    iptables -t mangle -D PREROUTING -i ${ifname} -p udp -j ${ChainName} >/dev/null 2>&1
    iptables -t mangle -X ${ChainName} >/dev/null 2>&1
    iptables -t mangle -X ${AccChainName} >/dev/null 2>&1

    iptables -t nat -F ${ChainName} >/dev/null 2>&1
    iptables -t nat -F ${AccChainName} >/dev/null 2>&1
    iptables -t nat -D PREROUTING -i ${ifname} -j ${ChainName} >/dev/null 2>&1
    iptables -t nat -X ${ChainName} >/dev/null 2>&1
    iptables -t nat -X ${AccChainName} >/dev/null 2>&1
}

xunyou_acc_stop()
{
    ctrlPid=$(echo -n `ps | grep -v grep | grep -w ${CtrlProc} | awk -F ' ' '{print $1}'`)
    [ -n "${ctrlPid}" ] && kill -9 ${ctrlPid}
    proxyPid=$(echo -n `ps | grep -v grep | grep -w ${ProxyProc} | awk -F ' ' '{print $1}'`)
    [ -n "${proxyPid}" ] && kill -9 ${proxyPid}
    ipsetPid=$(echo -n `ps | grep -v grep | grep -w ${IpsetProc} | awk -F ' ' '{print $1}'`)
    [ -n "${ipsetPid}" ] && kill -9 ${ipsetPid}
    #
    xunyou_clear_rule
}

xunyou_acc_init()
{
    rule_init
    ipset_check
}

xunyou_acc_uninstall()
{
    check_deamon_status
    if [ $? -eq 0 ]; then
        xunyou_acc_stop
    else
        stop_daemon
        xunyou_acc_stop
        xunyou_post_stop_log &
    fi
    ##
    rm -rf ${RouteLog}*
    rm -rf ${ProxyLog}*
    rm -rf ${IpsetLog}*
}

xunyou_acc_restart()
{
    xunyou_acc_stop
    xunyou_post_stop_log &
    xunyou_acc_start
    xunyou_post_start_log &
}

xunyou_acc_check()
{
    ctrlPid=`ps | grep -v grep | grep -w ${CtrlProc} | awk -F ' ' '{print $1}'`
    proxyPid=`ps | grep -v grep | grep -w ${ProxyProc} | awk -F ' ' '{print $1}'`
    ipsetPid=`ps | grep -v grep | grep -w ${IpsetProc} | awk -F ' ' '{print $1}'`
    #
    if [ ${IpsetEnable} == "1" ]; then
        [ -n "${ctrlPid}" -a -n "${proxyPid}" -a -n "${ipsetPid}" ] && return 0
    else
        [ -n "${ctrlPid}" -a -n "${proxyPid}" ] && return 0
    fi
    #
    [ -z "${ctrlPid}" ] && log "ctrl process is not running, now restart it." && xunyou_post_crash_log ${CtrlProc}
    [ -z "${proxyPid}" ] && log "proxy process is not running, now restart it." && xunyou_post_crash_log ${ProxyProc}
    if [ ${IpsetEnable} == "1" ]; then
        [ -z "${ipsetPid}" ] && log "ipset process is not running, now restart it." && xunyou_post_crash_log ${IpsetProc}
    fi
    #
    xunyou_acc_restart
}

iptables_check()
{
    iptables -t mangle -n -L ${ChainName} >/dev/null 2>&1
    if [ $? -ne 0 ];then
        log "iptables mangle chain ${ChainName} does not exist"
        xunyou_acc_restart
        xunyou_post_crash_log iptables
        return 0
    fi

    iptables -t mangle -n -L ${AccChainName} >/dev/null 2>&1
    if [ $? -ne 0 ];then
        log "iptables mangle chain ${AccChainName} does not exist"
        xunyou_acc_restart
        xunyou_post_crash_log iptables
        return 0
    fi

    iptables -t mangle -C PREROUTING -i ${ifname} -p udp -j ${ChainName} >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        log "iptables mangle rule does not exist"
        xunyou_acc_restart
        xunyou_post_crash_log iptables
        return 0
    fi

    iptables -t nat -n -L ${ChainName} >/dev/null 2>&1
    if [ $? -ne 0 ];then
        log "iptables nat chain ${ChainName} does not exist"
        xunyou_acc_restart
        xunyou_post_crash_log iptables
        return 0
    fi

    iptables -t nat -n -L ${AccChainName} >/dev/null 2>&1
    if [ $? -ne 0 ];then
        log "iptables nat chain ${AccChainName} does not exist"
        xunyou_acc_restart
        xunyou_post_crash_log iptables
        return 0
    fi

    iptables -t nat -C PREROUTING -i ${ifname} -j ${ChainName} >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        log "iptables nat rule does not exist"
        xunyou_acc_restart
        xunyou_post_crash_log iptables
        return 0
    fi
}

start_daemon()
{
    while [ 1 ]
    do
        xunyou_acc_check
        iptables_check
        sleep 60
    done
}

#检查守护进程是否运行，0为未运行，1为已运行
check_deamon_status()
{
    cnt_config=`ps | grep -v grep | grep -c -w 'xunyou_config'`
    
    if [ $cnt_config -le 2 ]; then
        return 0
    else
        return 1
    fi
}

#kill之前的常驻脚本
stop_daemon()
{
    CurrentPid="$$"
    killPid=`ps | grep -v grep | grep -w 'xunyou_config' | awk -F ' ' '{print $1}'`
    for LINE in ${killPid}
    do
        if [ ${LINE} != ${CurrentPid} ]; then
            kill -9 ${LINE} >/dev/null 2>&1
        fi
    done

    killPid=`ps | grep -v grep | grep -w 'xunyou_status'|  awk -F ' ' '{print $1}'`
    for LINE in ${killPid}
    do
        if [ ${LINE} != ${CurrentPid} ]; then
            kill -9 ${LINE} >/dev/null 2>&1
        fi
    done

    killPid=`ps | grep -v grep | grep -w 'S90XunYouAcc'|  awk -F ' ' '{print $1}'`
    for LINE in ${killPid}
    do
        if [ ${LINE} != ${CurrentPid} ]; then
            kill -9 ${LINE} >/dev/null 2>&1
        fi
    done
}

rm -f ${logPath}

case $1 in
    start)
        log "[start]: 启动迅游模块！"
        xunyou_acc_init

        check_deamon_status
        if [ $? -eq 1 ]; then
            log "daemon is already in running."
            exit 0
        else
            xunyou_acc_stop

            check_upgrade
            if [ $? -eq 1 ]; then
                log "need to execute upgrade"
                execute_upgrade
                exit 0
            fi

            xunyou_acc_start
            xunyou_post_start_log &
            start_daemon &
        fi
        ;;

    stop)
        log "[stop] 停止加速进程"

        xunyou_acc_init

        check_deamon_status
        if [ $? -eq 0 ]; then
            log "daemon is already stopped."
            xunyou_acc_stop
        else
            stop_daemon
            xunyou_acc_stop
            xunyou_post_stop_log &
        fi
        ;;

    app)
        log "[app]: 启动迅游模块！"

        xunyou_acc_init

        check_deamon_status
        if [ $? -eq 0 ]; then
            xunyou_acc_stop
        else
            stop_daemon
            xunyou_acc_stop
            xunyou_post_stop_log &
        fi

        check_upgrade
        if [ $? -eq 1 ]; then
            log "need to execute upgrade"
            execute_upgrade
            exit 0
        fi

        xunyou_acc_start
        xunyou_post_start_log &
        start_daemon &
        ;;

    simple)
        log "[simple]: 启动迅游模块！"

        xunyou_acc_init

        check_deamon_status
        if [ $? -eq 0 ]; then
            xunyou_acc_stop
        else
            stop_daemon
            xunyou_acc_stop
            xunyou_post_stop_log &
        fi

        xunyou_acc_start
        xunyou_post_start_log &
        start_daemon &
        ;;
esac

exit 0

