#!/bin/bash

# NATMap
outter_ip=$1
outter_port=$2

function get_current_rule() {
  # Function to get the current rule
  #
  # Returns:
  #  string: The current rule
  curl --request GET \
    --url "https://api.cloudflare.com/client/v4/zones/$LINK_CLOUDFLARE_ZONE_ID/rulesets/phases/http_request_origin/entrypoint" \
    --header "Authorization: Bearer $LINK_CLOUDFLARE_TOKEN" \
    --header "Content-Type: application/json"
}

# 默认重试次数为1，休眠时间为3s
max_retries=$6
sleep_time=$7
retry_count=0

# 初始化参数
currrent_rule=""
cloudflare_ruleset_id=""

# 获取cloudflare origin rule id
while (true); do
  currrent_rule=$(get_current_rule)
  cloudflare_ruleset_id=$(echo "$currrent_rule" | jq '.result.id' | sed 's/"//g')

  if [ -n "$cloudflare_ruleset_id" ]; then
    echo "$(date +'%Y-%m-%d %H:%M:%S') : $GENERAL_NAT_NAME - $LINK_MODE 登录成功" >>/var/log/natmap/natmap.log

    # 修改 origin rule
    origin_rule_name="\"$LINK_CLOUDFLARE_ORIGIN_RULE_NAME\""
    new_rule=$(echo "$currrent_rule" | jq '.result.rules| to_entries | map(select(.value.description == '"$origin_rule_name"')) | .[].key')
    new_rule=$(echo "$currrent_rule" | jq '.result.rules['"$new_rule"'].action_parameters.origin.port = '"$outter_port"'')

    # delete last_updated
    request_data=$(echo "$new_rule" | jq '.result | del(.last_updated)')
    result=$(curl --request PUT \
      --url "https://api.cloudflare.com/client/v4/zones/$LINK_CLOUDFLARE_ZONE_ID/rulesets/$cloudflare_ruleset_id" \
      --header "Authorization: Bearer $LINK_CLOUDFLARE_TOKEN" \
      --header "Content-Type: application/json" \
      --data "$request_data")

    if [ "$(echo "$result" | jq '.success' | sed 's/"//g')" == "true" ]; then
      # echo "$(date +'%Y-%m-%d %H:%M:%S') : $GENERAL_NAT_NAME - $LINK_MODE 更新成功" >>/var/log/natmap/natmap.log4
      echo "$(date +'%Y-%m-%d %H:%M:%S') : $GENERAL_NAT_NAME - $LINK_MODE 修改成功" >>/var/log/natmap/natmap.log
      echo "$(date +'%Y-%m-%d %H:%M:%S') : $GENERAL_NAT_NAME - $LINK_MODE 修改成功"
      break
    else
      echo "$(date +'%Y-%m-%d %H:%M:%S') : $GENERAL_NAT_NAME - $LINK_MODE 修改失败,休眠$sleep_time秒" >>/var/log/natmap/natmap.log
    fi
  else
    echo "$(date +'%Y-%m-%d %H:%M:%S') : $GENERAL_NAT_NAME - $LINK_MODE 登录失败,休眠$sleep_time秒" >>/var/log/natmap/natmap.log
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

# Check if maximum retries reached
if [ $retry_count -eq $max_retries ]; then
  echo "$(date +'%Y-%m-%d %H:%M:%S') : $GENERAL_NAT_NAME - $LINK_MODE 达到最大重试次数，无法修改" >>/var/log/natmap/natmap.log
  echo "$(date +'%Y-%m-%d %H:%M:%S') : $GENERAL_NAT_NAME - $LINK_MODE 达到最大重试次数，无法修改"
  exit 1
else
  echo "$(date +'%Y-%m-%d %H:%M:%S') : $GENERAL_NAT_NAME - $LINK_MODE 修改成功" >>/var/log/natmap/natmap.log
  echo "$(date +'%Y-%m-%d %H:%M:%S') : $GENERAL_NAT_NAME - $LINK_MODE 修改成功"
  exit 0
fi
