#!/bin/bash

# NATMap
outter_ip=$1
outter_port=$2
LINK_EMBY_URL=$(echo $LINK_EMBY_URL | sed 's/\/$//')

# 默认重试次数为1，休眠时间为3s
max_retries=$6
sleep_time=$7
retry_count=0

# 初始化参数
current_cfg=""

while (true); do
    current_cfg=$(curl -v $LINK_EMBY_URL/emby/System/Configuration?api_key=$LINK_EMBY_API_KEY)

    if [ -n "$current_cfg" ]; then
        echo "$(date +'%Y-%m-%d %H:%M:%S') : $GENERAL_NAT_NAME - $LINK_MODE 登录成功" >>/var/log/natmap/natmap.log
        new_cfg=$current_cfg
        if [ ! -z $LINK_EMBY_USE_HTTPS ] && [ $LINK_EMBY_USE_HTTPS = '1' ]; then
            new_cfg=$(echo $current_cfg | jq ".PublicHttpsPort = $outter_port")
        else
            new_cfg=$(echo $current_cfg | jq ".PublicPort = $outter_port")
        fi

        if [ ! -z $LINK_EMBY_UPDATE_HOST_WITH_IP ] && [ $LINK_EMBY_UPDATE_HOST_WITH_IP = '1' ]; then
            new_cfg=$(echo $new_cfg | jq ".WanDdns = \"$outter_ip\"")
        fi

        response=$(curl -X POST "$LINK_EMBY_URL/emby/System/Configuration?api_key=$LINK_EMBY_API_KEY" -H "accept: */*" -H "Content-Type: application/json" -d "$new_cfg" -w "%{http_code}")

        if [ "$response" -eq 200 ]; then
            echo "$(date +'%Y-%m-%d %H:%M:%S') : $GENERAL_NAT_NAME - $LINK_MODE 修改成功"
            echo "$(date +'%Y-%m-%d %H:%M:%S') : $GENERAL_NAT_NAME - $LINK_MODE 修改成功" >>/var/log/natmap/natmap.log
            break
        else
            echo "$LINK_MODE 修改失败,休眠$sleep_time秒" >>/var/log/natmap/natmap.log
        fi
    else
        echo "$LINK_MODE 登录失败,休眠$sleep_time秒" >>/var/log/natmap/natmap.log
    fi

    # 检测剩余重试次数
    let retry_count++
    if [ $retry_count -lt $max_retries ] || [ $max_retries -eq 0 ]; then
        sleep $sleep_time
    else
        echo "$(date +'%Y-%m-%d %H:%M:%S') : $GENERAL_NAT_NAME - $LINK_MODE 达到最大重试次数，无法修改" >>/var/log/natmap/natmap.log
        echo "$(date +'%Y-%m-%d %H:%M:%S') : $GENERAL_NAT_NAME - $LINK_MODE 达到最大重试次数，无法修改"
        break
    fi
done
