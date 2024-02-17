#!/bin/bash

# NATMap
outter_ip=$1
outter_port=$2

function get_current_rule() {
  curl --request GET \
    --url https://api.cloudflare.com/client/v4/zones/$LINK_CLOUDFLARE_ZONE_ID/rulesets/phases/http_request_dynamic_redirect/entrypoint \
    --header "Authorization: Bearer $LINK_CLOUDFLARE_TOKEN" \
    --header 'Content-Type: application/json'
}

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
# currrent_rule=""
retry_count=0
# cloudflare_ruleset_id=""

for ((retry_count = 0; retry_count < max_retries; retry_count++)); do
  local currrent_rule=$(get_current_rule)
  local cloudflare_ruleset_id=$(echo "$currrent_rule" | jq '.result.id' | sed 's/"//g')

  if [ -z "$cloudflare_ruleset_id" ]; then
    # echo "$LINK_MODE 登录失败,休眠$sleep_time秒"
    sleep $sleep_time
  else
    echo "$GENERAL_NAT_NAME - $LINK_MODE 登录成功"

    LINK_CLOUDFLARE_REDIRECT_RULE_NAME="\"$LINK_CLOUDFLARE_REDIRECT_RULE_NAME\""
    # replace NEW_PORT with outter_port
    LINK_CLOUDFLARE_REDIRECT_RULE_TARGET_URL=$(echo $LINK_CLOUDFLARE_REDIRECT_RULE_TARGET_URL | sed 's/NEW_PORT/'"$outter_port"'/g')
    local new_rule=$(echo "$currrent_rule" | jq '.result.rules| to_entries | map(select(.value.description == '"$LINK_CLOUDFLARE_REDIRECT_RULE_NAME"')) | .[].key')
    new_rule=$(echo "$currrent_rule" | jq '.result.rules['"$new_rule"'].action_parameters.from_value.target_url.value = "'"$LINK_CLOUDFLARE_REDIRECT_RULE_TARGET_URL"'"')

    local body=$(echo "$new_rule" | jq '.result')

    # delete last_updated
    body=$(echo "$body" | jq 'del(.last_updated)')
    curl --request PUT \
      --url https://api.cloudflare.com/client/v4/zones/$LINK_CLOUDFLARE_ZONE_ID/rulesets/$cloudflare_ruleset_id \
      --header "Authorization: Bearer $LINK_CLOUDFLARE_TOKEN" \
      --header 'Content-Type: application/json' \
      --data "$body"

    break
  fi
done

# Check if maximum retries reached
if [ $retry_count -eq $max_retries ]; then
  echo "$GENERAL_NAT_NAME - $LINK_MODE 达到最大重试次数，无法修改"
  exit 1
fi
