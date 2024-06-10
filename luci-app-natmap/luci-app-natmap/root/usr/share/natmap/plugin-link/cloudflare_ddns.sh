#!/bin/bash

# NATMap
outter_ip=$1
outter_port=$2
ip4p=$3

# 默认重试次数为1，休眠时间为3s
max_retries=1
sleep_time=3

# 判断是否开启高级功能
if [ "$LINK_ADVANCED_ENABLE" == 1 ] && [ -n "$LINK_ADVANCED_MAX_RETRIES" ] && [ -n "$LINK_ADVANCED_SLEEP_TIME" ]; then
  # 获取最大重试次数
  max_retries=$((LINK_ADVANCED_MAX_RETRIES == "0" ? 1 : LINK_ADVANCED_MAX_RETRIES))
  # 获取休眠时间
  sleep_time=$((LINK_ADVANCED_SLEEP_TIME == "0" ? 3 : LINK_ADVANCED_SLEEP_TIME))
fi

# 初始化参数
retry_count=0
dns_type=$LINK_CLOUDFLARE_DDNS_TYPE
dns_record_id=""

# 获取dns_record_id
# @param {string} local_ddns_domain - The domain name
# @param {string} local_dns_types - The DNS record type
# @return {string} The DNS record ID
function get_dns_record_id() {
  local local_ddns_domain="$1"
  local local_dns_types="$2"

  # 获取cloudflare dns记录的dns_record
  for (( ; retry_count < max_retries; retry_count++)); do
    # 发送GET请求
    local local_dns_record=$(curl --request GET \
      --url "https://api.cloudflare.com/client/v4/zones/$LINK_CLOUDFLARE_ZONE_ID/dns_records?name=$local_ddns_domain&type=$local_dns_types" \
      --header "Authorization: Bearer $LINK_CLOUDFLARE_TOKEN" \
      --header "Content-Type: application/json")

    # 判断是否成功获取响应
    if [ "$(echo "$local_dns_record" | jq '.success' | sed 's/"//g')" == "true" ]; then
      # 获取与dns_type匹配的dns_record_id
      echo "$(date +'%Y-%m-%d %H:%M:%S') : $GENERAL_NAT_NAME - $LINK_MODE 登录成功" >>/var/log/natmap/natmap.log
      local local_dns_record_id=$(echo "$local_dns_record" | jq ".result[0].id" | sed 's/"//g')
      break
    else
      echo "$(date +'%Y-%m-%d %H:%M:%S') : $GENERAL_NAT_NAME - $LINK_MODE 登录失败,休眠$sleep_time秒" >>/var/log/natmap/natmap.log
      sleep $sleep_time
    fi
  done

  # 返回dns记录的id
  echo "$local_dns_record_id"
}

# 创建请求数据
# @param {string} local_dns_type - dns记录类型
# @return {string} - 请求数据
function create_request_data() {
  local local_dns_type="$1"

  # 构建请求数据
  local local_request_data=""
  case $local_dns_type in
  "AAAA")
    # 创建 AAAA 记录
    local_request_data="{
                \"type\": \"$local_dns_type\",
                \"name\": \"$LINK_CLOUDFLARE_DDNS_DOMAIN\",
                \"content\": \"$ip4p\",
                \"ttl\": $LINK_CLOUDFLARE_DDNS_TTL,
                \"proxied\": false
            }"
    ;;
  "HTTPS")
    # 创建 HTTPS 记录
    local_request_data="{
                \"name\": \"$LINK_CLOUDFLARE_DDNS_DOMAIN\",
                \"type\": \"$local_dns_type\",
                \"proxied\": false,
                \"ttl\": $LINK_CLOUDFLARE_DDNS_TTL,
                \"data\":{
                    \"priority\": $LINK_CLOUDFLARE_DDNS_HTTPS_PRIORITY,
                    \"target\": \".\",
                    \"value\": \"ipv4hint=\\\"$outter_ip\\\" port=\\\"$outter_port\\\"\"
                }}"
    ;;
  "SRV")
    # 创建 SRV 记录
    local_request_data="{
                \"name\": \"$LINK_CLOUDFLARE_DDNS_DOMAIN\",
                \"type\": \"$local_dns_type\",
                \"ttl\": $LINK_CLOUDFLARE_DDNS_TTL,
                \"data\":{
                    \"port\": $outter_port,
                    \"priority\": $LINK_CLOUDFLARE_DDNS_SRV_PRIORITY,
                    \"target\": \"$LINK_CLOUDFLARE_DDNS_SRV_TARGET_DOMAIN\",
                    \"weight\": $LINK_CLOUDFLARE_DDNS_SRV_WEIGHT
                }}"
    ;;
  "A")
    # 创建 A 记录
    local_request_data="{
                \"type\": \"$local_dns_type\",
                \"name\": \"$LINK_CLOUDFLARE_DDNS_SRV_TARGET_DOMAIN\",
                \"content\": \"$outter_ip\",
                \"ttl\": $LINK_CLOUDFLARE_DDNS_TTL,
                \"proxied\": false
            }"
    ;;
  *)
    # 未知类型
    local_request_data=""
    ;;
  esac
  echo "$local_request_data"
}

# 更新dns记录
# @param {string} local_dns_record_id - dns记录的id
# @param {string} local_request_data - 请求数据
# @return {string} - 更新结果
function update_dns_record() {
  local local_dns_record_id="$1"
  local local_request_data="$2"
  local local_result=""
  for (( ; retry_count < max_retries; retry_count++)); do
    local_result=$(
      curl --request PUT \
        --url "https://api.cloudflare.com/client/v4/zones/$LINK_CLOUDFLARE_ZONE_ID/dns_records/$local_dns_record_id" \
        --header "Authorization: Bearer $LINK_CLOUDFLARE_TOKEN" \
        --header "Content-Type: application/json" \
        --data "$local_request_data"
    )

    # 判断api是否调用成功,返回参数success是否为true
    if [ "$(echo "$local_result" | jq '.success' | sed 's/"//g')" == "true" ]; then
      echo "$(date +'%Y-%m-%d %H:%M:%S') : $GENERAL_NAT_NAME - $LINK_MODE 更新成功" >>/var/log/natmap/natmap.log
      break
    else
      echo "$(date +'%Y-%m-%d %H:%M:%S') : $GENERAL_NAT_NAME - $LINK_MODE 修改失败,休眠$sleep_time秒" >>/var/log/natmap/natmap.log
      sleep $sleep_time
    fi
  done

  # 返回值
  if [ "$(echo "$local_result" | jq '.success' | sed 's/"//g')" == "true" ]; then
    echo "true"
  else
    echo "false"
  fi
}

# 开始运行
# 更新cloudflare的dns记录
case $dns_type in
"AAAA")
  # 更新 AAAA 记录
  dns_record_id=$(get_dns_record_id "$LINK_CLOUDFLARE_DDNS_DOMAIN" "$dns_type")
  request_data="$(create_request_data "$dns_type")"
  result=$(update_dns_record "$dns_record_id" "$request_data")
  ;;
"HTTPS")
  dns_record_id=$(get_dns_record_id "$LINK_CLOUDFLARE_DDNS_DOMAIN" "$dns_type")
  request_data="$(create_request_data "$dns_type")"
  result=$(update_dns_record "$dns_record_id" "$request_data")
  ;;
"SRV")
  # 更新target_domain的A记录
  dns_type="A"
  dns_record_id=$(get_dns_record_id "$LINK_CLOUDFLARE_DDNS_SRV_TARGET_DOMAIN" "$dns_type")
  request_data="$(create_request_data "$dns_type")"
  result=$(update_dns_record "$dns_record_id" "$request_data")

  # 更新SRV记录
  dns_type="SRV"
  dns_record_id=$(get_dns_record_id "$LINK_CLOUDFLARE_DDNS_DOMAIN" "$dns_type")
  request_data="$(create_request_data "$dns_type")"
  result=$(update_dns_record "$dns_record_id" "$request_data")
  ;;
*) ;;
esac

# Check if maximum retries reached
if [ $retry_count -ge $max_retries ]; then
  echo "$(date +'%Y-%m-%d %H:%M:%S') : $GENERAL_NAT_NAME - $LINK_MODE 达到最大重试次数，无法修改" >>/var/log/natmap/natmap.log
  echo "$(date +'%Y-%m-%d %H:%M:%S') : $GENERAL_NAT_NAME - $LINK_MODE 达到最大重试次数，无法修改"
  exit 1
else
  echo "$(date +'%Y-%m-%d %H:%M:%S') : $GENERAL_NAT_NAME - $LINK_MODE 更新成功" >>/var/log/natmap/natmap.log
  echo "$(date +'%Y-%m-%d %H:%M:%S') : $GENERAL_NAT_NAME - $LINK_MODE 更新成功"
  exit 0
fi
