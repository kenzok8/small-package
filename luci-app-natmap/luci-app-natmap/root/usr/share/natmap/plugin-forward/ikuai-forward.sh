#!/bin/bash
# ikuai_version=3.7.6

# natmap
outter_ip=$1
outter_port=$2
ip4p=$3
inner_port=$4
protocol=$5

# 默认重试次数为1，休眠时间为3s
max_retries=1
sleep_time=3
retry_count=0

# 判断是否开启高级功能
if [ "${FORWARD_ADVANCED_ENABLE}" == 1 ] && [ -n "$FORWARD_ADVANCED_MAX_RETRIES" ] && [ -n "$FORWARD_ADVANCED_SLEEP_TIME" ]; then
  # 获取最大重试次数
  max_retries=$((FORWARD_ADVANCED_MAX_RETRIES == "0" ? 1 : FORWARD_ADVANCED_MAX_RETRIES))
  # 获取休眠时间
  sleep_time=$((FORWARD_ADVANCED_SLEEP_TIME == "0" ? 3 : FORWARD_ADVANCED_SLEEP_TIME))
fi

# lan_port
mapping_lan_port=""
# 如果$FORWARD_TARGET_PORT为空或者$FORWARD_TARGET_PORT为0则退出
if [ -z "${FORWARD_TARGET_PORT}" ] || [ "${FORWARD_TARGET_PORT}" -eq 0 ]; then
  echo "FORWARD_TARGET_PORT is empty,set to outter_port" >>/var/log/natmap/natmap.log
  mapping_lan_port=$outter_port
else
  mapping_lan_port=${FORWARD_TARGET_PORT}
fi

# login api and call api
ikuai_login_api="/Action/login"
ikuai_call_api="/Action/call"
call_url="$(echo $FORWARD_IKUAI_WEB_URL | sed 's/\/$//')${ikuai_call_api}"
login_url="$(echo $FORWARD_IKUAI_WEB_URL | sed 's/\/$//')${ikuai_login_api}"

# 端口映射备注，区分不同的端口映射，查询时使用，唯一，不可重复
comment="natmap-${GENERAL_NAT_NAME}"
# 浏览器headers
headers='{"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/117.0.0.0 Safari/537.36",
    "Accept": "application/json",
    "Content-type": "application/json;charset=utf-8",
    "Accept-Language": "zh-CN"}'

# 创建payload数据
# 根据不同的操作类型创建不同的payload
#  @param $1 操作类型
#  @param $2 端口映射id
#  @return payload数据
function create_payload() {
  local local_action_type="$1"
  local local_mapping_record_id="$2"

  # 根据不同的操作类型创建不同的payload
  local local_payload=""
  case $local_action_type in
  "login")
    # Calculate the MD5 hash value of the password and convert it to hexadecimal
    local local_passwd=$(echo -n "$FORWARD_IKUAI_PASSWORD" | openssl dgst -md5 -hex | awk '{print $2}')
    # Concatenate 'salt_11' and the password, and encode it using base64
    local local_pass=$(echo -n "salt_11$local_passwd" | openssl enc -base64)
    # echo "FORWARD_IKUAI_PASSWORD: $FORWARD_IKUAI_PASSWORD"

    local_payload='{
          "username": "'"$FORWARD_IKUAI_USERNAME"'",
          "passwd": "'"$local_passwd"'",
          "pass": "'"$local_pass"'",
          "remember_password": ""
        }'
    ;;
  "show")
    local_payload='{
            "func_name": "dnat",
            "action": "show",
            "param": {
              "FINDS": "lan_addr,lan_port,wan_port,comment",
              "KEYWORDS": "'"$comment"'",
              "TYPE": "total,data",
              "limit": "0,20",
              "ORDER_BY": "",
              "ORDER": ""
            }
          }'
    ;;
  "add")
    local_payload='{
          "func_name": "dnat",
          "action": "add",
          "param": {
            "enabled": "yes",
            "comment": "'"$comment"'",
            "interface": "'"$FORWARD_IKUAI_MAPPING_WAN_INTERFACE"'",
            "lan_addr": "'"$FORWARD_TARGET_IP"'",
            "protocol": "'"$FORWARD_IKUAI_MAPPING_PROTOCOL"'",
            "wan_port": "'"$GENERAL_BIND_PORT"'",
            "lan_port": "'"$mapping_lan_port"'",
            "src_addr": ""
          }
        }'

    ;;
  "del")
    local_payload='{
            "func_name": "dnat",
            "action": "del",
            "param": {
              "id": "'"$local_mapping_record_id"'"
            }
          }'
    ;;
  *) ;;
  esac
  echo "$local_payload"
}

# 调用api接口
# This function calls the API action
# Parameters:
#   - local_cookie: authentication cookie
#   - local_payload: payload for the API action
# Returns:
#   - The response from the API
function call_action() {
  # The authentication cookie for the API
  local local_cookie="$1"
  # The payload for the API action
  local local_payload="$2"

  # Call the API with the specified cookie and payload
  # The response from the API is stored in local_response variable
  local local_response=$(curl -s -X POST -H "$headers" -b "$local_cookie" -d "$local_payload" "$call_url")

  # Return the response from the API
  echo "$local_response"
}

# ------------------------------------------------------------------------
# ------------------------------------------------------------------------
# 端口映射处理开始
for (( ; retry_count < max_retries; retry_count++)); do
  #
  # 登录
  login_payload="$(create_payload "login")"
  # echo "login_payload: $login_payload"
  cookie=$(curl -s -D - -H "$headers" -X POST -d "$login_payload" "$login_url" | awk -F' ' '/Set-Cookie:/ {print $2}')
  # echo "cookie: $cookie"

  # Check if the login was successful
  if [ -n "$cookie" ]; then
    # 查询端口映射id
    show_payload="$(create_payload "show")"
    show_response="$(call_action "$cookie" "$show_payload")"
    # 获取dnat_id
    mapping_record_ids=()
    [ "$(echo "$show_response" | jq -r '.ErrMsg')" = "Success" ] && mapping_record_ids=($(echo "$show_response" | jq -r '.Data.data[].id'))
    # echo "mapping_record_ids: ${mapping_record_ids[@]}"

    #
    # 如果存在record_id，则删除所有端口映射
    [ ${#mapping_record_ids[@]} -gt 0 ] &&
      for id in "${mapping_record_ids[@]}"; do
        # echo "mapping_record_id: $id"
        del_payload="$(create_payload "del" "$id")"
        del_response="$(call_action "$cookie" "$del_payload")"
        if [ "$(echo "$del_response" | jq -r '.ErrMsg')" = "Success" ]; then
          echo "$(date +'%Y-%m-%d %H:%M:%S') : $GENERAL_NAT_NAME - $FORWARD_MODE Port mapping deleted successfully" >>/var/log/natmap/natmap.log
          # echo "delete successfully"
        else
          echo "$(date +'%Y-%m-%d %H:%M:%S') : $GENERAL_NAT_NAME - $FORWARD_MODE Failed to delete the port mapping" >>/var/log/natmap/natmap.log
          # echo "delete failed"
        fi
      done

    #
    # 再次查询端口映射id
    show_response="$(call_action "$cookie" "$show_payload")"
    # 预设值mapping_record_ids数组变量，用于后续判断
    mapping_record_ids=(1 2)
    # echo "mapping_record_ids: ${mapping_record_ids[@]}"
    [ "$(echo "$show_response" | jq -r '.ErrMsg')" = "Success" ] && mapping_record_ids=($(echo "$show_response" | jq -r '.Data.data[].id'))
    # 验证对应端口映射是否存在
    if [ ${#mapping_record_ids[@]} -eq 0 ]; then
      echo "$(date +'%Y-%m-%d %H:%M:%S') : $GENERAL_NAT_NAME - $FORWARD_MODE all Port mapping deleted successfully" >>/var/log/natmap/natmap.log
      #
      # 添加端口映射
      # echo "adding mapping record..."
      add_payload="$(create_payload "add")"
      # echo "add_payload: $add_payload"
      add_response="$(call_action "$cookie" "$add_payload")"
      # echo "add_response: $add_response"
      #
      # Check if the modification was successful
      if [ "$(echo "$add_response" | jq -r '.ErrMsg')" = "Success" ]; then
        echo "$(date +'%Y-%m-%d %H:%M:%S') : $GENERAL_NAT_NAME - $FORWARD_MODE Port mapping add successfully" >>/var/log/natmap/natmap.log
        # echo "add successfully"
        break
      else
        echo "$(date +'%Y-%m-%d %H:%M:%S') : $GENERAL_NAT_NAME - $FORWARD_MODE Failed to add" >>/var/log/natmap/natmap.log
        # echo "add failed"
      fi
    else
      echo "$(date +'%Y-%m-%d %H:%M:%S') : $GENERAL_NAT_NAME - $FORWARD_MODE Failed to delete all of old record" >>/var/log/natmap/natmap.log
    fi
  else
    echo "$(date +'%Y-%m-%d %H:%M:%S') : $GENERAL_NAT_NAME - $FORWARD_MODE 修改失败,休眠$sleep_time秒" >>/var/log/natmap/natmap.log
    sleep $sleep_time
  fi
done

# Check if maximum retries reached
if [ $retry_count -eq $max_retries ]; then
  echo "$(date +'%Y-%m-%d %H:%M:%S') : $GENERAL_NAT_NAME - $FORWARD_MODE 达到最大重试次数，无法修改,请检测是否设置正确" >>/var/log/natmap/natmap.log
  echo "$(date +'%Y-%m-%d %H:%M:%S') : $GENERAL_NAT_NAME - $FORWARD_MODE 达到最大重试次数，无法修改,请检测是否设置正确"
  exit 1
else
  echo "$(date +'%Y-%m-%d %H:%M:%S') : $GENERAL_NAT_NAME - $FORWARD_MODE 修改成功" >>/var/log/natmap/natmap.log
  echo "$(date +'%Y-%m-%d %H:%M:%S') : $GENERAL_NAT_NAME - $FORWARD_MODE 修改成功"
  exit 0
fi
