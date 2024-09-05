#!/bin/bash

# NATMap
protocol=$5
inner_port=$4
outter_ip=$1
outter_port=$2
ip4p=$3

LINK_QB_WEB_URL=$(echo $LINK_QB_WEB_URL | sed 's/\/$//')

# 默认重试次数为1，休眠时间为3s
max_retries=$6
sleep_time=$7
retry_count=0

# 初始化参数
# 获取qbcookie，直至重试次数用尽
qbcookie=""

while (true); do
    # 获取qbcookie
    qbcookie=$(
        curl -Ssi -X POST \
            -d "username=$LINK_QB_USERNAME&password=$LINK_QB_PASSWORD" \
            "$LINK_QB_WEB_URL/api/v2/auth/login" |
            sed -n 's/.*\(SID=.\{32\}\);.*/\1/p'
    )

    # 如果qbcookie为空，则重试
    if [ -n "$qbcookie" ]; then
        # 修改端口
        response=$(curl -s -X POST \
            -b "$qbcookie" \
            -d 'json={"listen_port":"'$outter_port'"}' \
            "$LINK_QB_WEB_URL/api/v2/app/setPreferences" -w "%{http_code}")

        if [ "$response" -eq 200 ]; then
            echo "$(date +'%Y-%m-%d %H:%M:%S') : $GENERAL_NAT_NAME - $LINK_MODE 修改成功" >>/var/log/natmap/natmap.log
            echo "$(date +'%Y-%m-%d %H:%M:%S') : $GENERAL_NAT_NAME - $LINK_MODE 修改成功"
            break
        fi
    fi

    # 检测剩余重试次数
    let retry_count++
    if [ $retry_count -lt $max_retries ] || [ $max_retries -eq 0 ]; then
        echo "$(date +'%Y-%m-%d %H:%M:%S') : $GENERAL_NAT_NAME - $LINK_MODE 登录失败,正在重试..." >>/var/log/natmap/natmap.log
        sleep $sleep_time
    else
        echo "$(date +'%Y-%m-%d %H:%M:%S') : $GENERAL_NAT_NAME - $LINK_MODE 达到最大重试次数，无法修改" >>/var/log/natmap/natmap.log
        echo "$(date +'%Y-%m-%d %H:%M:%S') : $GENERAL_NAT_NAME - $LINK_MODE 达到最大重试次数，无法修改"
        break
    fi
done
