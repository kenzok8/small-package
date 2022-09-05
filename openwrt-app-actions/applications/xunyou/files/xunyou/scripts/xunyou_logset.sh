#!/bin/sh
#参数1 =setlog 设置迅游log的级别 ;参数2:log级别
#参数1 =putlog 将日志文件上传给ftp服务器;参数2:文件名称 例123.tar.gz

unix_domain_path_ctrl="/tmp/xunyou_ctrl_fd"
unix_domain_path_proxy="/tmp/xunyou_proxy_fd"
unix_domain_path_ipset="/tmp/xunyou_ipset_fd"
local_file_name="/tmp/xy_log.tar.gz"
log_level_value=""

BasePath=""
XunyouPath=${BasePath}/xunyou
[ ! -d ${XunyouPath} ] && exit 1

ipset_enable_file=${XunyouPath}/configs/ipset_enable
ipset_enable="0"

XunyouLogPath=${BasePath}/xunyou/log
FILE=${XunyouLogPath}/xunyou-system.log

if [ -e ${ipset_enable_file} ]; then
    ipset_enable=`cat ${ipset_enable_file}`
fi

get_json_value()
{
    local json=${1}
    local key=${2}
    local num=1
    local value=$(echo "${json}" | awk -F"[,:}]" '{for(i=1;i<=NF;i++){if($i~/'${key}'\042/){print $(i+1)}}}' | tr -d '"' | sed -n ${num}p)
    echo ${value}
}

get_ftp_file_name()
{
    if [ -e ${BasePath}/xunyou/configs/xunyou-user ]; then
        value=`cat ${BasePath}/xunyou/configs/xunyou-user`
        key="userName"
        userName=$(get_json_value $value $key)
        [ -z "${userName}" ] && userName=noname

        key="useripv4"
        useripv4=$(get_json_value $value $key)
        [ -z "${useripv4}" ] && useripv4=noipv4

        datetime=$(date '+%Y%m%d')

        file_name="${userName}_${useripv4}_${datetime}"
        echo ${file_name}
    else
        datetime=$(date '+%Y%m%d')
        echo ${datetime}
    fi
}

create_system_log()
{
    if [ -e "${FILE}" ]; then
        rm ${FILE} -f
    fi

    datetime=$(date '+%Y-%m-%d %H:%M:%S')

    echo ${datetime} > ${FILE}
    uname_cmd=`uname -a`
    echo "/shell#uname -a" >> ${FILE}
    echo "${uname_cmd}" >> ${FILE}
    echo "----------------------------------------------------------------------------------------------------" >> ${FILE}

    iptables_nat_cmd=`iptables -t nat -nvL`
    echo "/shell#iptables -t nat -nvL" >> ${FILE}
    echo "${iptables_nat_cmd}" >> ${FILE}
    echo "----------------------------------------------------------------------------------------------------" >> ${FILE}

    iptables_filter_cmd=`iptables -t filter -nvL`
    echo "/shell#iptables -t filter -nvL" >> ${FILE}
    echo "${iptables_filter_cmd}" >> ${FILE}
    echo "----------------------------------------------------------------------------------------------------" >> ${FILE}

    iptables_mangle_cmd=`iptables -t mangle -nvL`
    echo "/shell#iptables -t mangle -nvL" >> ${FILE}
    echo "${iptables_mangle_cmd}" >> ${FILE}
    echo "----------------------------------------------------------------------------------------------------" >> ${FILE}

    ipset_cmd=`ipset list > /dev/null 2>&1`
    echo "/shell#ipset list" >> ${FILE}
    echo "${ipset_cmd}" >> ${FILE}
    echo "----------------------------------------------------------------------------------------------------" >> ${FILE}

    ps_cmd=`ps -T`
    echo "/shell#ps -T" >> ${FILE}
    echo "${ps_cmd}" >> ${FILE}
    echo "----------------------------------------------------------------------------------------------------" >> ${FILE}
}

set_log_level()
{
    case ${log_level_value} in
        "ASSERT")
            log_level_num=0
            ;;

        "ERROR")
            log_level_num=1
            ;;

        "WARN")
            log_level_num=2
            ;;

        "INFO")
            log_level_num=3
            ;;

        "DEBUG")
            log_level_num=4
            ;;

        "VERBOSE")
            log_level_num=5
            ;;
    esac
    ${XunyouPath}/bin/udp-post -u ${unix_domain_path_ctrl} -v "{\"Cmd\":7,\"Subcmd\":10, \"loglevel\":${log_level_num}}"
    ${XunyouPath}/bin/udp-post -u ${unix_domain_path_proxy} -v "{\"Cmd\":7,\"Subcmd\":10, \"loglevel\":${log_level_num}}"
    [ ${ipset_enable} == "1" ] && ${XunyouPath}/bin/udp-post -u ${unix_domain_path_ipset} -v "{\"Cmd\":7,\"Subcmd\":10, \"loglevel\":${log_level_num}}"
}

ftp_put_log()
{
    create_system_log
    filename=$(get_ftp_file_name)
    tarname="${filename}.tar.gz"

    log_level_value=ASSERT
    set_log_level

    cd ${XunyouPath} && tar czvf ${local_file_name} log/ > /dev/null 2>&1
    ${XunyouPath}/bin/xy-ftp ${tarname} ${local_file_name}

    log_level_value=INFO
    set_log_level

    if [ -e "${local_file_name}" ]; then
        rm ${local_file_name} -f
    fi

    if [ -e "${FILE}" ]; then
        rm ${FILE} -f
    fi
}

case ${1} in
    "setlog")
        log_level_value=${2}
        set_log_level
        ;;

    "putlog")
        ftp_put_log
        ;;
esac
