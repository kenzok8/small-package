#!/bin/bash

# NATMap
outter_ip=$1
outter_port=$2
inner_port=$4
protocol=$5

LINK_TR_RPC_URL=$(echo $LINK_TR_RPC_URL | sed 's/\/$//')
url="$LINK_TR_RPC_URL/transmission/rpc"
# update port
trauth="-u $LINK_TR_USERNAME:$LINK_TR_PASSWORD"

# 默认重试次数为1，休眠时间为3s
max_retries=$6
sleep_time=$7
retry_count=0

# 初始化参数
# # 获取trsid，直至重试次数用尽
trsid=""

while (true); do
    trsid=$(curl -s $trauth $url | sed 's/.*<code>//g;s/<\/code>.*//g')

    # Check if the provided session ID contains the header "X-Transmission-Session-Id"
    if [[ $trsid == *"X-Transmission-Session-Id"* ]]; then
        echo "$(date +'%Y-%m-%d %H:%M:%S') : $GENERAL_NAT_NAME - $LINK_MODE 登录成功" >>/var/log/natmap/natmap.log

        # Modify the port using the Transmission API
        tr_result=$(curl -s -X POST \
            -H "$trsid" $trauth \
            -d '{"method":"session-set","arguments":{"peer-port":'$outter_port'}}' \
            "$url")

        # Check if the port modification was successful
        if [[ $(echo "$tr_result" | jq -r '.result') == "success" ]]; then
            echo "$(date +'%Y-%m-%d %H:%M:%S') : $GENERAL_NAT_NAME - $LINK_MODE 修改成功" >>/var/log/natmap/natmap.log
            echo "$(date +'%Y-%m-%d %H:%M:%S') : $GENERAL_NAT_NAME - $LINK_MODE 修改成功"
            break
        fi
    fi

    # Sleep for a specified amount of time
    sleep $sleep_time

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
