#!/bin/bash

text="$1"
chat_id="${NOTIFY_TELEGRAM_BOT_CHAT_ID}"
token="${NOTIFY_TELEGRAM_BOT_TOKEN}"
title="natmap - ${GENERAL_NAT_NAME} 更新"

function curl_proxy() {
    if [ -z "$NOTIFY_TELEGRAM_BOT_PROXY" ]; then
        curl "$@"
    else
        curl -x $NOTIFY_TELEGRAM_BOT_PROXY "$@"
    fi
}

# 获取最大重试次数和间隔时间
max_retries=$2
sleep_time=$3
retry_count=0

while (true); do

    curl_proxy -4 -Ss -o /dev/null -X POST \
        -H 'Content-Type: application/json' \
        -d '{"chat_id": "'"${chat_id}"'", "text": "'"${title}\n\n${text}"'", "parse_mode": "HTML", "disable_notification": "false"}' \
        "https://api.telegram.org/bot${token}/sendMessage"
    status=$?
    if [ $status -eq 0 ]; then
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
