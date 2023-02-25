#!/bin/sh
#
# 用于阿里云域名解析的DNS更新脚本
# 2017-2021 Sense <sensec at gmail dot com>
# 阿里云域名解析API文档 https://help.aliyun.com/document_detail/29739.html
#
# 本脚本由 dynamic_dns_functions.sh 内的函数 send_update() 调用
#
# 需要在 /etc/config/ddns 中设置的选项
# option username - 阿里云API访问账号 Access Key ID。可通过 aliyun.com 帐号管理的 accesskeys 获取, 或者访问 https://ak-console.aliyun.com
# option password - 阿里云API访问密钥 Access Key Secret
# option domain   - 完整的域名。建议主机与域名之间使用 @符号 分隔，否则将以第一个 .符号 之前的内容作为主机名
#

# 检查传入参数
[ -z "$username" ] && write_log 14 "配置错误！保存阿里云API访问账号的'用户名'不能为空"
[ -z "$password" ] && write_log 14 "配置错误！保存阿里云API访问密钥的'密码'不能为空"
[ $USE_CURL -eq 0 ] && USE_CURL=1	# 强制使用 cURL
[ $use_https -eq 1 -a -z "$cacert" ] && cacert="IGNORE"	# 使用 HTTPS 时 CA 证书为空则不检查服务器证书

# 检查外部调用工具
local CURL=$(command -v curl)
local CURL_SSL=$($CURL -V 2>/dev/null | grep -F "https")
local CURL_PROXY=$(find /lib /usr/lib -name libcurl.so* -exec strings {} 2>/dev/null \; | grep -im1 "all_proxy")
[ -z "$CURL" ] && write_log 13 "与阿里云服务器通信需要 cURL 支持, 请先安装"
command -v sed >/dev/null 2>&1 || write_log 13 "使用阿里云API需要 sed 支持, 请先安装"
command -v openssl >/dev/null 2>&1 || write_log 13 "使用阿里云API需要 openssl-util 支持, 请先安装"

# 包含用于解析 JSON 格式返回值的函数
. /usr/share/libubox/jshn.sh

# 变量声明
local __HOST __DOMAIN __FQDN __TYPE __PROG __URLBASE __DATA __TTL __SEPARATOR __RECID
__URLBASE="http://alidns.aliyuncs.com"
[ $use_https -eq 1 ] && __URLBASE=$(echo $__URLBASE | sed -e 's#^http:#https:#')
__TTL=
__SEPARATOR="&"

# 从 $domain 分离主机和域名
[ "${domain:0:2}" == "@." ] && domain="${domain/./}" # 主域名处理
[ "$domain" == "${domain/@/}" ] && domain="${domain/./@}" # 未找到分隔符，兼容常用域名格式
__HOST="${domain%%@*}"
__DOMAIN="${domain#*@}"
if [ -z "$__HOST" -o "$__HOST" == "$__DOMAIN" ]; then
	__HOST="@"
	__FQDN=${__DOMAIN}
else
	__FQDN=${__HOST}.${__DOMAIN}
fi

# 设置记录类型
[ $use_ipv6 -eq 0 ] && __TYPE="A" || __TYPE="AAAA"

# 构造基本通信命令, 从 dynamic_dns_functions.sh 函数 do_transfer() 复制
build_command() {
	__PROG="$CURL -qLsS -o $DATFILE --stderr $ERRFILE"
	# check HTTPS support
	[ -z "$CURL_SSL" -a $use_https -eq 1 ] && \
		write_log 13 "cURL: libcurl 编译时缺少 https 支持"
	# force network/interface-device to use for communication
	if [ -n "$bind_network" ]; then
		local __DEVICE
		network_get_device __DEVICE $bind_network || \
			write_log 13 "无法使用 'network_get_device $bind_network' 检测到本地设备 - 错误代码: '$?'"
		write_log 7 "强制通过设备 '$__DEVICE' 进行通信"
		__PROG="$__PROG --interface $__DEVICE"
	fi
	# force ip version to use
	if [ $force_ipversion -eq 1 ]; then
		[ $use_ipv6 -eq 0 ] && __PROG="$__PROG -4" || __PROG="$__PROG -6"	# force IPv4/IPv6
	fi
	# set certificate parameters
	if [ $use_https -eq 1 ]; then
		if [ "$cacert" = "IGNORE" ]; then	# idea from Ticket #15327 to ignore server cert
			__PROG="$__PROG --insecure"	# but not empty better to use "IGNORE"
		elif [ -f "$cacert" ]; then
			__PROG="$__PROG --cacert $cacert"
		elif [ -d "$cacert" ]; then
			__PROG="$__PROG --capath $cacert"
		elif [ -n "$cacert" ]; then		# it's not a file and not a directory but given
			write_log 14 "在 '$cacert' 中未发现用于 HTTPS 通信的有效证书"
		fi
	fi
	# disable proxy if no set (there might be .wgetrc or .curlrc or wrong environment set)
	# or check if libcurl compiled with proxy support
	if [ -z "$proxy" ]; then
		__PROG="$__PROG --noproxy '*'"
	elif [ -z "$CURL_PROXY" ]; then
		# if libcurl has no proxy support and proxy should be used then force ERROR
		write_log 13 "cURL: libcurl 编译时缺少代理支持"
	fi
}

# 服务器通信函数, 从 dynamic_dns_functions.sh 函数 do_transfer() 复制
server_transfer() {
	local __URL="$@"
	local __ERR=0
	local __CNT=0	# error counter
	local __RUNPROG

	[ $# -eq 0 ] && write_log 12 "'server_transfer()' 出错 - 参数数量错误"

	while : ; do
		build_Request $__URL
		__RUNPROG="$__PROG -X POST '$__URLBASE' -d '$__DATA'"	# build final command

		write_log 7 "#> $__RUNPROG"
		eval $__RUNPROG			# DO transfer
		__ERR=$?			# save error code
		[ $__ERR -eq 0 ] && return 0	# no error leave
		[ -n "$LUCI_HELPER" ] && return 1	# no retry if called by LuCI helper script

		write_log 3 "cURL Error: '$__ERR'"
		write_log 7 "$(cat $ERRFILE)"		# report error

		[ $VERBOSE -gt 1 ] && {
			# VERBOSE > 1 then NO retry
			write_log 4 "Transfer failed - Verbose Mode: $VERBOSE - NO retry on error"
			return 1
		}

		__CNT=$(( $__CNT + 1 ))	# increment error counter
		# if error count > retry_count leave here
		[ $retry_count -gt 0 -a $__CNT -gt $retry_count ] && \
			write_log 14 "Transfer failed after $retry_count retries"

		write_log 4 "Transfer failed - retry $__CNT/$retry_count in $RETRY_SECONDS seconds"
		sleep $RETRY_SECONDS &
		PID_SLEEP=$!
		wait $PID_SLEEP	# enable trap-handler
		PID_SLEEP=0
	done
	# we should never come here there must be a programming error
	write_log 12 "'server_transfer()' 出错 - 程序代码错误"
}

# 百分号编码
percentEncode() {
	if [ -z "${1//[A-Za-z0-9_.~-]/}" ]; then
		echo -n "$1"
	else
		local string=$1 i=0 ret chr
		while [ $i -lt ${#string} ]; do
			chr=${string:$i:1}
			[ -z "${chr#[^A-Za-z0-9_.~-]}" ] && chr=$(printf '%%%02X' "'$chr")
			ret="$ret$chr"
			let i++
		done
		echo -n "$ret"
	fi
}

# 构造阿里云域名解析请求参数
build_Request() {
	local args="$@" HTTP_METHOD="POST" string signature

	# 添加请求参数
	__DATA=
	for string in $args; do
		case "${string%%=*}" in
			Format|Version|AccessKeyId|SignatureMethod|Timestamp|SignatureVersion|SignatureNonce|Signature) ;; # 过滤公共参数
			*) __DATA="$__DATA${__SEPARATOR}"$(percentEncode "${string%%=*}")"="$(percentEncode "${string#*=}");;
		esac
	done
	__DATA="${__DATA:1}"

	# 附加公共参数
	string="Format=JSON"; __DATA="$__DATA${__SEPARATOR}"$(percentEncode "${string%%=*}")"="$(percentEncode "${string#*=}")
	string="Version=2015-01-09"; __DATA="$__DATA${__SEPARATOR}"$(percentEncode "${string%%=*}")"="$(percentEncode "${string#*=}")
	string="AccessKeyId=$username"; __DATA="$__DATA${__SEPARATOR}"$(percentEncode "${string%%=*}")"="$(percentEncode "${string#*=}")
	string="SignatureMethod=HMAC-SHA1"; __DATA="$__DATA${__SEPARATOR}"$(percentEncode "${string%%=*}")"="$(percentEncode "${string#*=}")
	string="Timestamp="$(date -u '+%Y-%m-%dT%H:%M:%SZ'); __DATA="$__DATA${__SEPARATOR}"$(percentEncode "${string%%=*}")"="$(percentEncode "${string#*=}")
	string="SignatureVersion=1.0"; __DATA="$__DATA${__SEPARATOR}"$(percentEncode "${string%%=*}")"="$(percentEncode "${string#*=}")
	string="SignatureNonce="$(cat '/proc/sys/kernel/random/uuid'); __DATA="$__DATA${__SEPARATOR}"$(percentEncode "${string%%=*}")"="$(percentEncode "${string#*=}")

	# 对请求参数进行排序，用于生成签名
	string=$(echo -n "$__DATA" | sed 's/\'"${__SEPARATOR}"'/\n/g' | sort | sed ':label; N; s/\n/\'"${__SEPARATOR}"'/g; b label')
	# 构造用于计算签名的字符串
	string="${HTTP_METHOD}${__SEPARATOR}"$(percentEncode "/")"${__SEPARATOR}"$(percentEncode "$string")
	# 字符串计算签名HMAC值
	signature=$(echo -n "$string" | openssl dgst -sha1 -hmac "${password}&" -binary)
	# HMAC值编码成字符串，得到签名值
	signature=$(echo -n "$signature" | openssl base64)

	# 附加签名参数
	string="Signature=$signature"; __DATA="$__DATA${__SEPARATOR}"$(percentEncode "${string%%=*}")"="$(percentEncode "${string#*=}")
}

# 获取解析记录列表
describe_domain() {
	local __URL count value ipaddr i=1 ret=0
	__URL="Action=DescribeDomainRecords DomainName=${__DOMAIN} RRKeyWord=${__HOST} Type=${__TYPE}"
	server_transfer "$__URL" || return 1
	json_cleanup; json_load "$(cat "$DATFILE" 2>/dev/null)" >/dev/null 2>&1
	json_get_var count "TotalCount"
	if [ -z "$count" ]; then
		json_get_var value "Message"
		write_log 4 "Aliyun.com 响应失败, 错误原因: $value"
		return 127
	else
		json_select "DomainRecords" >/dev/null 2>&1
		json_select "Record" >/dev/null 2>&1
		while [ $i -le $count ]; do
			json_select $i >/dev/null 2>&1
			json_get_var value "RR"
			if [ "$value" == "$__HOST" ]; then
				json_get_var __RECID "RecordId"
#				write_log 7 "获得 ${__FQDN} ${__TYPE}记录ID: ${__RECID}"
				json_get_var value "Locked"
				[ $value -ne 0 ] && write_log 13 "Aliyun.com 上的 ${__FQDN} ${__TYPE}记录已被锁定, 无法更新"
				json_get_var value "Status"
				[ "$value" != "ENABLE" ] && ret=$(( $ret | 4 )) && write_log 7 "Aliyun.com 上的 ${__FQDN} ${__TYPE}记录已被禁用"
				json_get_var value "Value"
				# 展开 IPv6 地址用于比较
				if [ $use_ipv6 -eq 0 ]; then
					ipaddr="$__IP"
				else
					expand_ipv6 $__IP ipaddr
					expand_ipv6 $value value
				fi
				if [ "$value" == "$ipaddr" ]; then
					write_log 7 "Aliyun.com 上的 ${__FQDN} ${__TYPE}记录无需更新"
				else
					write_log 7 "Aliyun.com 上的 ${__FQDN} ${__TYPE}记录需要更新"
					ret=$(( $ret | 2 ))
				fi
				break
			fi
			json_select ..
			let i++
		done
		if [ -z "$__RECID" ]; then
			write_log 7 "Aliyun.com 上的 ${__FQDN} ${__TYPE}记录不存在"
			ret=8
		fi
	fi
	return $ret
}

# 添加解析记录
add_domain() {
	local __URL value
	__URL="Action=AddDomainRecord DomainName=${__DOMAIN} RR=${__HOST} Type=${__TYPE} Value=${__IP}"
	[ -n "${__TTL}" ] && __URL="${__URL} TTL=${__TTL}"
	server_transfer "$__URL" || return 1
	json_cleanup; json_load "$(cat "$DATFILE" 2>/dev/null)" >/dev/null 2>&1
	json_get_var value "RecordId"
	if [ -z "$value" ]; then
		json_get_var value "Message"
		write_log 4 "Aliyun.com 响应失败, 错误原因: $value"
		return 127
	else
		write_log 7 "Aliyun.com 上的 ${__FQDN} ${__TYPE}记录已添加"
	fi
	return 0
}

# 更新解析记录
update_domain() {
	local __URL value
	__URL="Action=UpdateDomainRecord RR=${__HOST} RecordId=${__RECID} Type=${__TYPE} Value=${__IP}"
	[ -n "${__TTL}" ] && __URL="${__URL} TTL=${__TTL}"
	server_transfer "$__URL" || return 1
	json_cleanup; json_load "$(cat "$DATFILE" 2>/dev/null)" >/dev/null 2>&1
	json_get_var value "RecordId"
	if [ -z "$value" ]; then
		json_get_var value "Message"
		write_log 4 "Aliyun.com 响应失败, 错误原因: $value"
		return 127
	else
		write_log 7 "Aliyun.com 上的 ${__FQDN} ${__TYPE}记录已更新为: ${__IP}"
	fi
	return 0
}

# 启用解析记录
enable_domain() {
	local __URL value
	__URL="Action=SetDomainRecordStatus RecordId=${__RECID} Status=Enable"
	server_transfer "$__URL" || return 1
	json_cleanup; json_load "$(cat "$DATFILE" 2>/dev/null)" >/dev/null 2>&1
	json_get_var value "RecordId"
	if [ -z "$value" ]; then
		json_get_var value "Message"
		write_log 4 "Aliyun.com 响应失败, 错误原因: $value"
		return 127
	else
		write_log 7 "Aliyun.com 上的 ${__FQDN} ${__TYPE}记录已启用"
	fi
	return 0
}

build_command
describe_domain
ret=$?
if [ $(( $ret & 1 )) -ne 0 ]; then
	return $ret
elif [ $ret -eq 8 ]; then
	sleep 3 && { add_domain; [ $? -ne 0 ] && return $?; }
else
	[ $(( $ret & 4 )) -ne 0 ] && sleep 3 && { enable_domain; [ $? -ne 0 ] && return $?; }
	[ $(( $ret & 2 )) -ne 0 ] && sleep 3 && { update_domain; [ $? -ne 0 ] && return $?; }
fi
return 0
