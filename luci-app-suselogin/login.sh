#!/bin/sh

# Copyright 2020 BlackYau <blackyau426@gmail.com>
# GNU General Public License v3.0

dir="/tmp/log/suselogin/" && mkdir -p ${dir}
logfile="${dir}suselogin.log"
pidpath=${dir}run.pid
count=0
ua="User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/84.0.4147.89 Safari/537.36"
enable=$(uci get suselogin.@login[0].enable)
[ $enable -eq 0 ] && echo "$(date "+%Y-%m-%d %H:%M:%S"): 未启用,停止运行..." > ${logfile} && exit 0
interval=$(($(uci get suselogin.@login[0].interval)*60)) # 把时间换算成秒
username=$(uci get suselogin.@login[0].username)
password=$(uci get suselogin.@login[0].password)
isp=$(uci get suselogin.@login[0].isp)
auto_offline=$(uci get suselogin.@login[0].auto_offline)


# 获取已连接设备数
function check(){
	local count=`cat /proc/net/arp|grep "0x2\|0x6"|awk '{print $1}'|grep -v "^169.254."|grep -v "^172.21."|grep -v "^$"|sort -u|wc -l $1`
	echo $count
}

# 控制log文件大小
function reducelog(){
	[ -f ${logfile} ] && local logrow=$(grep -c "" ${logfile}) || local logrow="0"
	[ $logrow -gt 500 ] && sed -i '1,100d' ${logfile} && echo "`date "+%Y-%m-%d %H:%M:%S"`  日志超出上限(500行)，删除前 100 条" >> ${logfile}
}

# 如果在线返回真 关于返回值的问题:https://stackoverflow.com/a/43840545
function isonline(){
	local captiveReturnCode=`curl -s -I -m 10 -o /dev/null -s -w %{http_code} http://www.google.cn/generate_204`
	if [ "$captiveReturnCode" = "204" ]; then
		return
	fi
	false
}

function up(){
	if isonline; then
		echo "$(date "+%Y-%m-%d %H:%M:%S"): 您已连接到网络!" >> ${logfile}
		sleep 1 && return
	fi

	# Get referer page
	local refererPage=`curl -s "http://www.google.cn/generate_204" | awk -F \' '{print $2}'`

	# Structure loginURL
	local loginURL=`echo $refererPage | awk -F \? '{print $1}'`
	local loginURL="${loginURL/index.jsp/InterFace.do?method=login}"

	# Structure queryString
	local queryString=`echo $refererPage | awk -F \? '{print $2}'`
	local queryString="${queryString//&/%2526}"
	local queryString="${queryString//=/%253D}"

	# Login
	if [ -n "$loginURL" ]; then
		curl -s -A "${ua}" \
			-e "$refererPage" \
			-b "EPORTAL_COOKIE_OPERATORPWD=; EPORTAL_AUTO_LAND=; EPORTAL_COOKIE_USERNAME=; EPORTAL_COOKIE_PASSWORD=; EPORTAL_COOKIE_SERVER=; EPORTAL_COOKIE_SERVER_NAME=; EPORTAL_COOKIE_DOMAIN=; EPORTAL_COOKIE_SAVEPASSWORD=false; EPORTAL_COOKIE_DOMAIN=false;" \
			-d "userId=$username&password=$password&service=$isp&queryString=$queryString&operatorPwd=&operatorUserId=&validcode=&passwordEncrypt=false" \
			-H "Accept: */*" \
			-H "Content-Type: application/x-www-form-urlencoded; charset=UTF-8" \
			-m 5 \
			"$loginURL" > ${dir}login.log
		wait
	else
		echo "$(date "+%Y-%m-%d %H:%M:%S"): 获取登录地址失败" >> ${logfile} && return
	fi

	if isonline; then
		ntpd -n -q -p ntp1.aliyun.com  # 登录成功后校准时间
		wait # 等待校准时间完毕
		echo "$(date "+%Y-%m-%d %H:%M:%S"): 登录成功!" >> ${logfile} && sleep 2 && return
	else
		echo -n "$(date "+%Y-%m-%d %H:%M:%S"): 登录失败,错误信息: " >> ${logfile}
		echo "$(cat /tmp/log/suselogin/login.log)" >> ${logfile}
	fi
}

function logout(){
	local resultCode=$(curl -o /dev/null -s -m 5 -w %{http_code} -A "${ua}" -d "method=logout" http://10.23.2.4/eportal/InterFace.do)
	if [ "$resultCode" = "200" ]; then
		echo "$(date "+%Y-%m-%d %H:%M:%S"): 成功下线！" >> ${logfile}
		sleep 2 && up
	else
		echo $resultCode
		echo -n "$(date "+%Y-%m-%d %H:%M:%S"): 下线失败" >> ${logfile}
		echo "$(curl -m 5 -A "${ua}" -d "method=logout" "http://10.23.2.4/eportal/InterFace.do")" >> ${logfile}
	fi
}

if [ -f ${pidpath} ]; then
    echo "终止之前的进程: $(cat $pidpath)"
    kill -9 $(cat $pidpath)>/dev/null 2>&1
    rm -rf $pidpath
    sleep 1
fi
echo $$ > $pidpath

echo "$(date "+%Y-%m-%d %H:%M:%S"): 进程已启动 pid:$(cat $pidpath)" > ${logfile}

while [ $enable -eq 1 ]; do  # 已启用脚本
	tmp_count=$(check)
	if [ $tmp_count -gt 0 ]; then  # 已连接的设备>0才会进行下面的操作
		up
		wait
		if [ $auto_offline -eq 1 ]; then
			if [ $tmp_count -gt $count ]; then  # 如果当前已连接设备数，超过了上一次判断时的已连接设备数，就开始自动退出登录
				echo "$(date "+%Y-%m-%d %H:%M:%S"): 当前已连接$tmp_count个设备, 上次检测时有$count个设备，开始退出登录" >> ${logfile} && logout
			fi
			count=$tmp_count  # 连接设备变少了也要记录
		fi
	fi
	reducelog
	sleep $interval
done
