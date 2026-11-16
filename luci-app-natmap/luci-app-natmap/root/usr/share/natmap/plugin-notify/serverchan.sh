#!/bin/bash

title="natmap - ${GENERAL_NAT_NAME} 更新"
desp="$1"

# 拼装post数据
postdata="title=$title&desp=$desp"
message=(
    "--header" "Content-type: application/x-www-form-urlencoded"
    "--data" "$postdata"
)

# 获取url
url=""
if [ "${NOTIFY_SERVERCHAN_ADVANCED_ENABLE}" == 1 ] && [ -n "$NOTIFY_SERVERCHAN_ADVANCED_URL" ]; then
    url="$NOTIFY_SERVERCHAN_ADVANCED_URL/${NOTIFY_SERVERCHAN_SENDKEY}.send"
else
    url="https://sctapi.ftqq.com/${NOTIFY_SERVERCHAN_SENDKEY}.send"
fi

# 获取最大重试次数和间隔时间
max_retries=$2
sleep_time=$3
retry_count=0

while (true); do

    result=$(curl -X POST -s -o /dev/null -w "%{http_code}" "$url" "${message[@]}")
    if [ $result -eq 200 ]; then
        echo "$(date +'%Y-%m-%d %H:%M:%S') : $GENERAL_NAT_NAME - $NOTIFY_MODE 发送成功" >>/var/log/natmap/natmap.log
        echo "$(date +'%Y-%m-%d %H:%M:%S') : $GENERAL_NAT_NAME - $NOTIFY_MODE 发送成功"
        break
    fi

    # 检测剩余重试次数
    let retry_count++
    if [ $retry_count -lt $max_retries ] || [ $max_retries -eq 0 ]; then
        echo "$NOTIFY_MODE 登录失败,休眠$sleep_time秒" >>/var/log/natmap/natmap.log
        sleep $sleep_time
    else
        echo "$(date +'%Y-%m-%d %H:%M:%S') : $GENERAL_NAT_NAME - $NOTIFY_MODE 达到最大重试次数，无法通知" >>/var/log/natmap/natmap.log
        echo "$(date +'%Y-%m-%d %H:%M:%S') : $GENERAL_NAT_NAME - $NOTIFY_MODE 达到最大重试次数，无法通知"
        break
    fi
done
