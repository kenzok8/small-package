#!/bin/sh

ACTION=${1}
shift 1

# 获取当前型号对应的平台版本
auto_arch() {
  case $(uname -m) in
    x86_64|amd64) echo "linux-amd64" ;;
    armv7l|armhf) echo "linux-arm" ;;
    aarch64|arm64) echo "linux-arm64" ;;
    *) echo "$(uname -m)" ;;
  esac
}

# 创建文件夹
create_folder() {
  local config_path="$1"
  [ ! -d "$config_path/logs" ] && mkdir -p "$config_path/logs"
  [ ! -d "$config_path/database" ] && mkdir -p "$config_path/database"
  [ ! -d "$config_path/configuration" ] && mkdir -p "$config_path/configuration" 
  # 设置文件夹权限
  chmod -R 777 "$config_path"
}

# 创建docker可以执行的接口命令
do_create_command() {
    local content="$1"
    local config=$(uci get zdinnav.@main[0].config_path 2>/dev/null)
    local file_path="$config/configuration/command.txt"
    local dir_path=$(dirname "$file_path")
    
    # 检查目录是否存在，不存在则创建
    if [ ! -d "$dir_path" ]; then
        mkdir -p "$dir_path"
    fi

    # 添加内容
    echo "$content" >> "$file_path"
    # 设置777权限
    chmod 777 "$file_path"
}

# 重置http访问
do_reset_http() {
  local config=$(uci get zdinnav.@main[0].config_path 2>/dev/null)
  # 设置权限
  chmod -R 777 "$config"
  # 删除文件
  if [ -f "${config}/configuration/SSLSettings.json" ]; then
    rm -f "${config}/configuration/SSLSettings.json" && echo 1 || echo 0
  else
    echo 1
  fi
   # 创建重置http命令
  do_create_command "RESETHTTP"
  # 重启docker
  cd $config && docker-compose restart
}

# 重置超级管理员密码
do_reset_administrator_password() {
  # 创建重置密码命令
  do_create_command "RESETPASSWORD"
  # 重启docker
  local config=$(uci get zdinnav.@main[0].config_path 2>/dev/null)
  cd $config && docker-compose restart
  echo 1
}

# 检查安离线装包是否存在
do_check_package() {
  local latest_tar=$(ls -t "$1/downloads/"*.tar 2>/dev/null | head -n 1)
  if [ -n "$latest_tar" ]; then
    echo 1
  else
    echo 0
  fi
}

# 获取访问类型：http、https
do_protocol() {
  local config=$(uci get zdinnav.@main[0].config_path 2>/dev/null)
  if [ -f "${config}/configuration/SSLSettings.json" ]; then
    echo "https"
  else
    echo "http"
  fi
}

# 版本号比较：1=发现新版本、0=不需要更新
compare_versions() {
  # 服务器版本号
  local server_ver=$(echo "$1" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
  # 当前版本号
  local current_ver=$(echo "$2" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
  # 提取数字部分
  local server_digits=$(echo "$server_ver" | sed 's/[^0-9]/ /g' | tr ' ' '\n' | grep -v '^$' | tr '\n' ' ')
  local current_digits=$(echo "$current_ver" | sed 's/[^0-9]/ /g' | tr ' ' '\n' | grep -v '^$' | tr '\n' ' ')
  # 比较主版本号
  local server_major=$(echo "$server_digits" | cut -d' ' -f1)
  local current_major=$(echo "$current_digits" | cut -d' ' -f1)
  if [ "$server_major" -gt "$current_major" ]; then
   echo 1
   return
  elif [ "$server_major" -lt "$current_major" ]; then
   echo 0
   return
  fi
    
  # 比较次版本号
  server_minor=$(echo "$server_digits" | cut -d' ' -f2)
  current_minor=$(echo "$current_digits" | cut -d' ' -f2)
  server_minor=${server_minor:-0}
  current_minor=${current_minor:-0}
  if [ "$server_minor" -gt "$current_minor" ]; then
    echo 1
    return
  elif [ "$server_minor" -lt "$current_minor" ]; then
    echo 0
    return
  fi
    
  # 比较修订版本号
  server_patch=$(echo "$server_digits" | cut -d' ' -f3)
  current_patch=$(echo "$current_digits" | cut -d' ' -f3)
  server_patch=${server_patch:-0}
  current_patch=${current_patch:-0}
  if [ "$server_patch" -gt "$current_patch" ]; then
      echo 1
      return
    else
      echo 0
      return
    fi
}

# 获取最新版号
get_version() {
  local platform="$1"
  local version_url=`uci get zdinnav.@zdinnav_config[0].version_url 2>/dev/null`
  local content=""
    
  if [ -z "$platform" ]; then
    echo "无法获取当前支持的平台类型无法安装。Unable to determine the supported platform type. Installation cannot proceed." >&2
    return 1
  fi
    
  if command -v wget >/dev/null 2>&1; then
    content=$(wget -q -O - "$version_url" 2>/dev/null)
  elif command -v curl >/dev/null 2>&1; then
    content=$(curl -s -f "$version_url" 2>/dev/null)
  else
    echo "获更新失败: 需要 wget 或 curl 工具。Update failed: wget or curl tools are required." >&2
    return 1
  fi
    
  if [ $? -ne 0 ] || [ -z "$content" ]; then
    echo "URL请求失败，网络不稳定，目前无法访问。URL request failed: Unstable network connection, currently inaccessible." >&2
    return 1
  fi
    
  # 匹配指定的型号版本
  local version_line=$(echo "$content" | grep -i "[[:space:]]*$platform[[:space:]]*:[[:space:]]*")
  # 调试输出获取到的内容
  # echo "内容预览:" >&2
  # echo "$content" | head -5 >&2
  if [ -z "$version_line" ]; then
    echo "当前可能不支持 '$platform' 平台的安装，更多信息访问git。Installation on '$platform' platform may not be supported at this time. For more information, visit git." >&2
    return 1
  fi
 
  # 字符串截取：aaa:bbb 只获取bbb
  local version=$(echo "$version_line" | sed 's/.*://' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
  if [ -z "$version" ]; then
    echo "更新失败，无法获取最新版本号。Update failed: unable to retrieve the latest version number." >&2
    return 1
  fi
  echo "$version"
}

do_install() {
  local port=`uci get zdinnav.@main[0].port 2>/dev/null`
  local config=`uci get zdinnav.@main[0].config_path 2>/dev/null`
  local docker_url=`uci get zdinnav.@zdinnav_config[0].docker_url 2>/dev/null`
  local version=`uci get zdinnav.@zdinnav_config[0].version 2>/dev/null`
  local offline_installation=`uci get zdinnav.@main[0].enable_offline_installation 2>/dev/null`
  local zdinnav_account=`uci get zdinnav.@main[0].administrator_account 2>/dev/null`
  local zdinnav_password=`uci get zdinnav.@main[0].administrator_password 2>/dev/null`
  local zdinnav_database=`uci get zdinnav.@main[0].database_type 2>/dev/null`
  local zdinnav_connection=`uci get zdinnav.@main[0].connection_settings 2>/dev/null`
  local latest_tar=""

  if [ -z "$config" ]; then
    echo "config path is empty!"
    exit 1
  fi

  mkdir -p $config
  RET=$?
  if [ ! "$RET" = "0" ]; then
    echo "mkdir config path failed"
    exit 1
  fi

  # 离线安装检查安装包是否存在，不存在抛出提示
  if [ "$offline_installation" = "1" ]; then
      latest_tar=$(ls -t "$config/downloads/"*.tar 2>/dev/null | head -n 1)
      if [ -n "$latest_tar" ]; then
      local basename="${latest_tar%.tar}"
      # 获取版本号:zdinnav_linux-amd64-1.0.0.tar 返回：linux-amd64-1.0.0
      local version_local="${basename#*_}"
      if [ -z "$version_local" ]; then
        echo "无法解析安装包，请不要修改安装包文件名。Unable to parse the installation package. Do not modify its file name."
        exit 1
      fi
      # 停止并删除并旧版本
      local docker_state=$(docker ps --all -f 'name=^/zdinnav' --format '{{.State}}')
      if [ -n "$docker_state" ]; then
        if [ "$docker_state" = "running" ]; then
          docker stop zdinnav
        fi
        docker rm zdinnav
      fi
      if [[ "$(docker images -q $docker_url:$version 2> /dev/null)" != "" ]]; then
        docker rmi "$docker_url:$version"
      fi
      # 安装docker离线文件
      docker load -i "$latest_tar"
      if [ ! "$?" = "0" ]; then
        echo "docker load 执行失败，请检查*.tar安装包是否正确。The 'docker load' command failed. Please verify the integrity of the *.tar file."
        exit 1
      fi
      version=$version_local
      # 离线安装版本检查
      local zdinnav_tag=$(docker images --format "{{.Repository}} {{.Tag}} {{.CreatedAt}}" | grep -E ".*/zdinnav" | sort -r | head -n 1 | awk '{print $2}')
      if [ "$zdinnav_tag" != "$version"]; then
        echo "安装失败，请重新下载安装包，下载后勿修改，放至指定位置后重装。Installation failed. Redownload the package unmodified, move it to the specified location, and retry installation."
        exit 1
      fi
      else
        echo "无法找到安装包。Cannot find the installation package."
        exit 1
      fi
  fi

  [ -z $port ] && port=9200
  sed -e "s|PORT_VAR|${port}|g" \
    -e "s|CONFIG_PATH_VAR|${config}|g" \
    -e "s|DOCKER_URL_VAR|${docker_url}|g" \
    -e "s|VERSION_VAR|${version}|g" \
    "/usr/share/zdinnav/docker-compose.template.yaml" > "${config}/docker-compose.yaml"
  RET=$?
  if [ ! "$RET" = "0" ]; then
    echo "convert docker-compose.yaml failed"
    exit 1
  fi

  # 创建文件夹
  $(create_folder "$config")

  # 数据库初始化配置
  sed -e "s|ACCOUNT_VAR|${zdinnav_account}|g" \
    -e "s|PASSWORD_VAR|${zdinnav_password}|g" \
    "/usr/share/zdinnav/initializeData.json" > "${config}/configuration/initializeData.json"
  sed -e "s|DBTYPE_VAR|${zdinnav_database}|g" \
    -e "s|CONNECTIONSTRING_VAR|${zdinnav_connection}|g" \
    "/usr/share/zdinnav/zdinNavSettings.json" > "${config}/configuration/zdinNavSettings.json"

  cd $config

  docker-compose down || true
  docker-compose up -d

  # 离线安装时，校验
  if [ "$offline_installation" = "1" ]; then
    # 休眠3秒后，校验是否正常运行
    sleep 3
    local zdinnav_State=$(docker ps --all -f 'name=^/zdinnav' --format '{{.State}}')
    if [[ -z "$zdinnav_State" || "$zdinnav_State" != "running" ]]; then
      echo "智淀导航运行失败，请检查*.tar安装包是否支持该平台。The zdinnav application failed to start. Ensure the *.tar package is compatible with the current platform."
      # 移除错误docker数据
      docker stop zdinnav
      docker rm zdinnav
      docker rmi "$docker_url:$version"
      exit 1
    fi
  fi

  # 更新版本记录
  uci set zdinnav.@zdinnav_config[0].version=$version
  uci commit zdinnav

  if [[ -n "$latest_tar" && -f "$latest_tar" ]]; then
    rm -f "$latest_tar"
  fi
}

# 升级/应用
do_upgrade() {
  local port=`uci get zdinnav.@main[0].port 2>/dev/null`
  local config=`uci get zdinnav.@main[0].config_path 2>/dev/null`
  local docker_url=`uci get zdinnav.@zdinnav_config[0].docker_url 2>/dev/null`
  local version=`uci get zdinnav.@zdinnav_config[0].version 2>/dev/null`
  if [ -z "$config" ]; then
    echo "config path is empty!"
    exit 1
  fi

  mkdir -p $config
  RET=$?
  if [ ! "$RET" = "0" ]; then
    echo "mkdir config path failed"
    exit 1
  fi

  # 获取最新版
  local latest_version=$(get_version "$(auto_arch)")
  local is_update=$(compare_versions "$latest_version" "$version")

  # 检查是否需要升级应用
  if  [ "$is_update" = "1" ]; then
    echo "发现新版本：$latest_version。New version found: $latest_version."
    local docker_state=$(docker ps --all -f 'name=^/zdinnav' --format '{{.State}}')
    if [ -n "$docker_state" ]; then
      if [ "$docker_state" = "running" ]; then
        docker stop zdinnav
      fi
      docker rm zdinnav
    fi
    if [[ "$(docker images -q $docker_url:$version 2> /dev/null)" != "" ]]; then
      docker rmi "$docker_url:$version"
    fi
    # 更新版本
    version=$latest_version
    else
      if [[ -n "$latest_version" && "$latest_version" != "1" ]]; then
        echo "当前已经是最新版：$version。You're already on the latest version: $version."
      fi
    fi

  [ -z $port ] && port=9200
  sed -e "s|PORT_VAR|${port}|g" \
    -e "s|CONFIG_PATH_VAR|${config}|g" \
    -e "s|DOCKER_URL_VAR|${docker_url}|g" \
    -e "s|VERSION_VAR|${version}|g" \
    "/usr/share/zdinnav/docker-compose.template.yaml" > "${config}/docker-compose.yaml"
  RET=$?
  if [ ! "$RET" = "0" ]; then
    echo "convert docker-compose.yaml failed"
    exit 1
  fi

  cd $config
  # 创建文件夹
  $(create_folder "$config")
   
  docker-compose down || true
  docker-compose up -d

  # 更新版本记录
  uci set zdinnav.@zdinnav_config[0].version=$version
  uci commit zdinnav
}

# 移除应用
do_remove() {
  local docker_url=`uci get zdinnav.@zdinnav_config[0].docker_url 2>/dev/null`
  local version=`uci get zdinnav.@zdinnav_config[0].version 2>/dev/null`
  local docker_state=$(docker ps --all -f 'name=^/zdinnav' --format '{{.State}}')
  if [ -n "$docker_state" ]; then
    if [ "$docker_state" = "running" ]; then
      docker stop zdinnav
    fi
      docker rm zdinnav
  fi
  if [[ "$(docker images -q $docker_url:$version 2> /dev/null)" != "" ]]; then
      docker rmi "$docker_url:$version"
  fi
}

usage() {
  echo "usage: $0 sub-command"
  echo "where sub-command is one of:"
  echo "      install                Install the zdinnav"
  echo "      upgrade                Upgrade the zdinnav"
  echo "      rm/start/stop/restart  Remove/Start/Stop/Restart the zdinnav"
  echo "      status                 ZdinNav status"
  echo "      port                   ZdinNav port"
}

case ${ACTION} in
  "protocol")
    do_protocol
  ;;
   "auto_get_arch")
    auto_arch
  ;;
  "check_package")
    do_check_package "$1"
  ;;
  "reset_http")
    do_reset_http
  ;;
  "reset_password")
    do_reset_administrator_password
  ;;
  "install")
    do_install
  ;;
  "upgrade")
    do_upgrade
  ;;
  "rm")
    do_remove
  ;;
  "start" | "stop" | "restart")
    config=`uci get zdinnav.@main[0].config_path 2>/dev/null`
    cd $config && docker-compose ${ACTION}
  ;;
  "status")
    docker ps --all -f 'name=^/zdinnav' --format '{{.State}}'
  ;;
  "port")
    docker ps -all -f 'name=^/zdinnav' --format '{{.Ports}}' | grep -om1 '0.0.0.0:[0-9]*' | sed 's/0.0.0.0://'
  ;;
  *)
    usage
    exit 1
  ;;
esac
