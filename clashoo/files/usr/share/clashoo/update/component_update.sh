#!/bin/sh

LOG_FILE="/tmp/clashoo_component_update.log"
RUN_FILE="/var/run/clashoo_component_update"
STATE_FILE="/tmp/clashoo_component_update_state"
TMP_DIR="/tmp/clashoo-component-update"
FEED_BASE_URL="https://down.dllkids.xyz/openwrt-feed/clashoo"
GITHUB_API_URL="https://api.github.com/repos/kenzok8/openwrt-clashoo/releases/latest"
GITHUB_PROXY_PREFIX="${GITHUB_PROXY_PREFIX:-https://ghfast.top/}"

log() {
  mkdir -p "$(dirname "$LOG_FILE")" "$(dirname "$STATE_FILE")" >/dev/null 2>&1
  printf '%s - %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >>"$LOG_FILE"
  printf 'component=%s\nstatus=%s\nmessage=%s\n' "${COMPONENT:-}" "${STATUS:-running}" "$*" >"$STATE_FILE"
}

finish() {
  rc="$1"
  msg="$2"
  STATUS="success"
  [ "$rc" -eq 0 ] || STATUS="failed"
  log "$msg"
  rm -f "$RUN_FILE"
  exit "$rc"
}

# In kernel-only mode there is no transparent proxy, so component downloads
# would go out direct and stall behind the GFW. Route them through the running
# core (shared logic in proxy_lib.sh). Normal mode returns empty -> TPROXY.
# Guard the source: on a stale install missing proxy_lib.sh, an unguarded `.`
# under `set -e` kills the whole update silently (empty log, nothing happens).
# Fall back to no proxy detection (direct / TPROXY) instead of dying.
if [ -f /usr/share/clashoo/update/proxy_lib.sh ]; then
  . /usr/share/clashoo/update/proxy_lib.sh
else
  clashoo_detect_proxy() { :; }
fi
detect_proxy() { clashoo_detect_proxy; }

fetch_text() {
  url="$1"
  proxy="$(detect_proxy)"
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL ${proxy:+--proxy "$proxy"} "$url"
    return $?
  fi
  if command -v wget >/dev/null 2>&1; then
    [ -n "$proxy" ] && { http_proxy="$proxy" https_proxy="$proxy" wget -qO- "$url"; return $?; }
    wget -qO- "$url"
    return $?
  fi
  return 127
}

download_file() {
  url="$1"
  out="$2"
  proxy="$(detect_proxy)"
  if command -v curl >/dev/null 2>&1; then
    curl -fL ${proxy:+--proxy "$proxy"} "$url" -o "$out"
    return $?
  fi
  if [ -n "$proxy" ]; then
    http_proxy="$proxy" https_proxy="$proxy" wget -qO "$out" "$url"
    return $?
  fi
  wget -qO "$out" "$url"
}

download_url() {
  url="$1"
  case "$url" in
    https://github.com/*)
      printf '%s%s\n' "$GITHUB_PROXY_PREFIX" "$url"
      ;;
    *)
      printf '%s\n' "$url"
      ;;
  esac
}

root_free_kb() {
  df -k / 2>/dev/null | awk 'NR==2 {print $4}'
}

kb_to_mib() {
  awk "BEGIN {printf \"%.0f\", (${1:-0}) / 1024}"
}

ensure_root_space() {
  need_kb="$1"
  free_kb="$(root_free_kb)"
  [ -n "$free_kb" ] || return 0
  [ "$free_kb" -ge "$need_kb" ] && return 0
  finish 1 "根分区空间不足：可用 $(kb_to_mib "$free_kb") MiB，至少需要 $(kb_to_mib "$need_kb") MiB"
}

log_install_error() {
  file="$1"
  [ -s "$file" ] || return 0
  tail -8 "$file" 2>/dev/null | while IFS= read -r line; do
    [ -n "$line" ] && log "$line"
  done
}

detect_manager() {
  if command -v opkg >/dev/null 2>&1; then
    echo opkg
    return
  fi
  if command -v apk >/dev/null 2>&1; then
    echo apk
    return
  fi
  echo unsupported
}

detect_arch() {
  pm="$1"
  if [ "$pm" = "opkg" ]; then
    opkg print-architecture 2>/dev/null | awk '/^arch / {print $2}' | tail -n 1
    return
  fi
  # apk: DISTRIB_ARCH is authoritative (e.g. aarch64_cortex-a53); apk --print-arch
  # only gives the generic "aarch64" which won't match the .apk package suffix.
  if [ -r /etc/openwrt_release ]; then
    a="$(sed -n "s/^DISTRIB_ARCH=['\"]\\([^'\"]*\\)['\"]$/\\1/p" /etc/openwrt_release | head -n 1)"
    [ -n "$a" ] && { printf '%s\n' "$a"; return; }
  fi
  apk --print-arch 2>/dev/null
}

detect_sdk() {
  [ -r /etc/openwrt_release ] || return 1
  release="$(sed -n "s/^DISTRIB_RELEASE=['\"]\\([^'\"]*\\)['\"]$/\\1/p" /etc/openwrt_release | head -n 1)"
  [ -n "$release" ] || return 1
  printf '%s\n' "$release" | grep -Eo '[0-9]+\.[0-9]+' | head -n 1
}

append_unique_word() {
  value="$1"
  list="$2"
  [ -n "$value" ] || {
    printf '%s\n' "$list"
    return
  }
  case " $list " in
    *" $value "*) ;;
    *) list="${list}${list:+ }${value}" ;;
  esac
  printf '%s\n' "$list"
}

build_sdk_candidates() {
  pm="$1"
  candidates=""
  detected_sdk="$(detect_sdk || true)"
  candidates="$(append_unique_word "$detected_sdk" "$candidates")"

  if [ "$pm" = "opkg" ]; then
    for sdk in 24.10 23.05 22.03 21.02; do
      candidates="$(append_unique_word "$sdk" "$candidates")"
    done
  else
    for sdk in 25.12 24.10; do
      candidates="$(append_unique_word "$sdk" "$candidates")"
    done
  fi

  printf '%s\n' "$candidates"
}

find_manifest_value() {
  key="$1"
  manifest_text="$2"
  printf '%s\n' "$manifest_text" | sed -n "s/^${key}=//p" | head -n 1
}

load_manifest_urls() {
  sdk="$1"
  arch="$2"
  manifest_url="${FEED_BASE_URL}/${sdk}/${arch}/manifest-clashoo.txt"
  manifest_text="$(fetch_text "$manifest_url" || true)"
  [ -n "$manifest_text" ] || return 1

  core_file="$(find_manifest_value "core" "$manifest_text")"
  luci_file="$(find_manifest_value "luci" "$manifest_text")"
  i18n_file="$(find_manifest_value "i18n" "$manifest_text")"
  [ -n "$core_file" ] || return 1
  [ -n "$luci_file" ] || return 1

  CORE_URL="${FEED_BASE_URL}/${sdk}/${arch}/${core_file}"
  LUCI_URL="${FEED_BASE_URL}/${sdk}/${arch}/${luci_file}"
  I18N_URL=""
  [ -n "$i18n_file" ] && I18N_URL="${FEED_BASE_URL}/${sdk}/${arch}/${i18n_file}"
  SOURCE_LABEL="R2 feed ${sdk}/${arch}"
  return 0
}

load_github_urls() {
  arch="$1"
  ext="$2"
  payload="$(fetch_text "$GITHUB_API_URL" || true)"
  [ -n "$payload" ] || return 1

  urls="$(printf '%s\n' "$payload" | sed -n 's/.*"browser_download_url":[[:space:]]*"\([^"]*\)".*/\1/p')"
  [ -n "$urls" ] || return 1

  if [ "$ext" = "apk" ]; then
    CORE_URL="$(printf '%s\n' "$urls" | grep -E '/clashoo-[^-]+.*-r[0-9]+-'"$arch"'\.apk$' | head -n 1)"
    LUCI_URL="$(printf '%s\n' "$urls" | grep -E '/luci-app-clashoo-[^-]+.*-r[0-9]+-('"$arch"'|all)\.apk$' | head -n 1)"
    I18N_URL="$(printf '%s\n' "$urls" | grep -E '/luci-i18n-clashoo-zh-cn-[^-]+.*-r[0-9]+-('"$arch"'|all)\.apk$' | head -n 1)"
  else
    CORE_URL="$(printf '%s\n' "$urls" | grep -E '/clashoo_.*_'"$arch"'\.ipk$' | head -n 1)"
    LUCI_URL="$(printf '%s\n' "$urls" | grep -E '/luci-app-clashoo_.*_all\.ipk$' | head -n 1)"
    I18N_URL="$(printf '%s\n' "$urls" | grep -E '/luci-i18n-clashoo-zh-cn_.*_all\.ipk$' | head -n 1)"
  fi

  [ -n "$CORE_URL" ] || return 1
  [ -n "$LUCI_URL" ] || return 1
  SOURCE_LABEL="GitHub latest"
  return 0
}

package_version_from_url() {
  file="${1##*/}"
  case "$file" in
    clashoo_*.ipk) printf '%s\n' "$file" | sed -n 's/^clashoo_\(.*\)_.*\.ipk$/\1/p' ;;
    luci-app-clashoo_*.ipk) printf '%s\n' "$file" | sed -n 's/^luci-app-clashoo_\(.*\)_all\.ipk$/\1/p' ;;
    luci-i18n-clashoo-zh-cn_*.ipk) printf '%s\n' "$file" | sed -n 's/^luci-i18n-clashoo-zh-cn_\(.*\)_all\.ipk$/\1/p' ;;
    clashoo-*.apk) printf '%s\n' "$file" | sed -n 's/^clashoo-\(.*-r[0-9][0-9]*\)-.*\.apk$/\1/p' ;;
    luci-app-clashoo-*.apk) printf '%s\n' "$file" | sed -n 's/^luci-app-clashoo-\(.*-r[0-9][0-9]*\)-.*\.apk$/\1/p' ;;
    luci-i18n-clashoo-zh-cn-*.apk) printf '%s\n' "$file" | sed -n 's/^luci-i18n-clashoo-zh-cn-\(.*-r[0-9][0-9]*\)-.*\.apk$/\1/p' ;;
    *) printf '%s\n' "$file" ;;
  esac
}

resolve_bundle_urls() {
  PM="$(detect_manager)"
  [ "$PM" != "unsupported" ] || return 1
  ARCH="$(detect_arch "$PM")"
  [ -n "$ARCH" ] || return 1
  EXT="ipk"
  [ "$PM" = "apk" ] && EXT="apk"

  CORE_URL=""
  LUCI_URL=""
  I18N_URL=""
  SOURCE_LABEL=""

  SDK_CANDIDATES="$(build_sdk_candidates "$PM")"
  for sdk in $SDK_CANDIDATES; do
    if load_manifest_urls "$sdk" "$ARCH"; then
      return 0
    fi
  done

  load_github_urls "$ARCH" "$EXT"
}

backup_config() {
  ts="$(date '+%Y%m%d-%H%M%S')"
  BACKUP_DIR="/etc/clashoo/backup/component-upgrade-${ts}"
  mkdir -p "$BACKUP_DIR/etc-config" "$BACKUP_DIR/etc-clashoo" >/dev/null 2>&1 || return 1
  [ -r /etc/config/clashoo ] && cp -a /etc/config/clashoo "$BACKUP_DIR/etc-config/clashoo"
  # 只备份用户配置；Model.bin 等可重新下载的大文件不入备份，避免每次更新
  # 复制 ~5MB 的同一模型，把备份目录撑大、堆满本就紧张的根分区。
  for path in \
    /etc/clashoo/config.yaml \
    /etc/clashoo/config.json \
    /etc/clashoo/*.yaml \
    /etc/clashoo/*.yml \
    /etc/clashoo/*.json
  do
    [ -e "$path" ] || continue
    cp -a "$path" "$BACKUP_DIR/etc-clashoo/" 2>/dev/null || true
  done
  log "已备份配置：${BACKUP_DIR}"

  # 只保留最近 1 个备份，删除更早的，避免无限堆积占满磁盘。
  ls -dt /etc/clashoo/backup/component-upgrade-* 2>/dev/null | tail -n +2 | while read -r _old; do
    [ -n "$_old" ] && rm -rf "$_old" 2>/dev/null
  done
}

restore_config_backup() {
  [ -n "${BACKUP_DIR:-}" ] || return 0
  [ -r "$BACKUP_DIR/etc-config/clashoo" ] && cp -a "$BACKUP_DIR/etc-config/clashoo" /etc/config/clashoo
  if [ -d "$BACKUP_DIR/etc-clashoo" ]; then
    mkdir -p /etc/clashoo
    cp -a "$BACKUP_DIR/etc-clashoo/." /etc/clashoo/ 2>/dev/null || true
  fi
  uci commit clashoo >/dev/null 2>&1 || true
}

clashoo_was_running() {
  /etc/init.d/clashoo status >/dev/null 2>&1 && return 0
  /etc/init.d/sing-box status >/dev/null 2>&1 && return 0
  return 1
}

restart_web_stack() {
  # reload (not restart) rpcd so the LuCI login session survives a plugin
  # update — rpcd restart drops every ubus session and forces a re-login
  # (issue #12). reload still picks up the new ucode RPC backend. uhttpd needs
  # nothing: updated static assets are served on the next request.
  /etc/init.d/rpcd reload >/dev/null 2>&1 || true
}

# which: clashoo（仅核心）/ luci（luci-app + 语言包）。两者拆开，clashoo
# 核心更新频率高于 LuCI，分别更新便于定位失败。
run_pkg_update() {
  which="$1"
  log "正在检查组件包"
  if ! resolve_bundle_urls; then
    finish 1 "未找到适配当前设备的组件包"
  fi
  log "更新来源：${SOURCE_LABEL}"

  rm -rf "$TMP_DIR"
  mkdir -p "$TMP_DIR" || finish 1 "创建临时目录失败"

  was_running=0
  clashoo_was_running && was_running=1
  backup_config || finish 1 "备份配置失败"

  # apk 默认会对 world 做一致性求解，若系统上别的包（如 daed 缺 kmod-sched-bpf）
  # 处于 broken 状态，会让 apk add 整个失败，连本次升级都装不上。这里通过
  # --force-broken-world 让 apk 忽略不相关的 world 失败，只完成本次升级。
  APK_FLAGS="--allow-untrusted --force-broken-world"

  if [ "$which" = "clashoo" ]; then
    core_ver="$(package_version_from_url "$CORE_URL")"
    log "目标版本：Clashoo 核心 ${core_ver}"
    log "正在下载 Clashoo 核心"
    download_file "$(download_url "$CORE_URL")" "$TMP_DIR/core.${EXT}" || finish 1 "下载 clashoo 失败"
    ensure_root_space 98304
    log "正在安装 Clashoo 核心"
    if [ "$PM" = "opkg" ]; then
      opkg install --force-downgrade "$TMP_DIR/core.${EXT}" >"$TMP_DIR/install.log" 2>&1; rc=$?
    else
      apk add $APK_FLAGS "$TMP_DIR/core.${EXT}" >"$TMP_DIR/install.log" 2>&1; rc=$?
    fi
  else
    luci_ver="$(package_version_from_url "$LUCI_URL")"
    log "目标版本：客户端 ${luci_ver}"
    log "正在下载客户端（LuCI + 语言包）"
    download_file "$(download_url "$LUCI_URL")" "$TMP_DIR/luci.${EXT}" || finish 1 "下载 luci-app-clashoo 失败"
    if [ -n "$I18N_URL" ]; then
      download_file "$(download_url "$I18N_URL")" "$TMP_DIR/i18n.${EXT}" || finish 1 "下载语言包失败"
    fi
    log "正在安装客户端"
    if [ "$PM" = "opkg" ]; then
      opkg install --force-downgrade "$TMP_DIR/luci.${EXT}" ${I18N_URL:+"$TMP_DIR/i18n.${EXT}"} >"$TMP_DIR/install.log" 2>&1; rc=$?
    else
      apk add $APK_FLAGS "$TMP_DIR/luci.${EXT}" ${I18N_URL:+"$TMP_DIR/i18n.${EXT}"} >"$TMP_DIR/install.log" 2>&1; rc=$?
    fi
  fi

  if [ "$rc" -ne 0 ]; then
    # apk exits non-zero when ANY package in the world is broken — e.g. file
    # conflicts between unrelated apps (argon-config, momo, ...) — even though
    # our package installed fine. Only treat it as a real failure when an apk
    # ERROR line actually names a clashoo package; otherwise it is unrelated
    # broken-world noise and we continue (--force-broken-world already applied).
    if grep -E '^ERROR:' "$TMP_DIR/install.log" 2>/dev/null | grep -qi 'clashoo'; then
      log_install_error "$TMP_DIR/install.log"
      log "安装失败，正在恢复配置备份"
      restore_config_backup
      finish "$rc" "组件更新失败"
    fi
    log "apk 报告了无关软件包的错误（broken world），clashoo 自身已安装成功，继续"
  fi

  # Only a luci-app update touches /www and the rpcd backend, so only then
  # refresh the web stack. The clashoo core package ships no web files — a
  # web-stack refresh there is pointless churn that just disturbs the UI.
  if [ "$which" = "luci" ]; then
    log "正在刷新 LuCI 服务"
    restart_web_stack
  fi
  # 仅核心更新且原本运行中才重启 Clashoo；纯客户端更新不动服务
  if [ "$which" = "clashoo" ] && [ "$was_running" -eq 1 ]; then
    log "Clashoo 原本运行中，正在重启服务"
    sh /usr/share/clashoo/rpc/rpc_async.sh restart >/dev/null 2>&1 || /etc/init.d/clashoo restart >/dev/null 2>&1 || true
  elif [ "$which" = "clashoo" ]; then
    log "Clashoo 原本未运行，保持停止状态"
  fi

  finish 0 "组件更新完成"
}

run_core_update() {
  dcore="$1"
  label="$2"
  log "正在更新 ${label}"
  # Pass the target as an arg so core_download refreshes only that binary
  # without switching the active kernel. It restarts only if the target is the
  # currently-running core (see core_download.sh finalize). Switching kernels
  # stays a separate, explicit user action.
  touch /var/run/core_update
  sh /usr/share/clashoo/update/core_download.sh "$dcore" >>/tmp/clash_update.txt 2>&1
  rc=$?
  rm -f /var/run/core_update
  [ "$rc" -eq 0 ] || finish "$rc" "${label} 更新失败"
  finish 0 "${label} 更新完成"
}

run_lgbm_update() {
  log "正在更新 Smart LightGBM 模型"
  sh /usr/share/clashoo/update/lgbm_update.sh >/tmp/lgbm_update.log 2>&1
  rc=$?
  tail -5 /tmp/lgbm_update.log 2>/dev/null | while IFS= read -r line; do
    [ -n "$line" ] && log "$line"
  done
  [ "$rc" -eq 0 ] || finish "$rc" "LightGBM 模型更新失败"
  finish 0 "LightGBM 模型更新完成"
}

run_china_update() {
  log "正在更新大陆白名单"
  sh /usr/share/clashoo/update/update_china_ip.sh >>/tmp/clash_update.txt 2>&1
  rc=$?
  tail -6 /tmp/clash_update.txt 2>/dev/null | while IFS= read -r line; do
    [ -n "$line" ] && printf '%s\n' "$line" | grep -q '白名单' && log "$line"
  done
  [ "$rc" -eq 0 ] || finish "$rc" "大陆白名单更新失败"
  finish 0 "大陆白名单更新完成"
}

run_geoip_update() {
  log "正在更新 GeoIP / GeoSite"
  touch /var/run/geoip_update
  sh /usr/share/clashoo/update/geoip.sh >/tmp/geoip_update.txt 2>&1
  rc=$?
  rm -f /var/run/geoip_update
  tail -8 /tmp/geoip_update.txt 2>/dev/null | while IFS= read -r line; do
    [ -n "$line" ] && log "$line"
  done
  [ "$rc" -eq 0 ] || finish "$rc" "GeoIP / GeoSite 更新失败"
  finish 0 "GeoIP / GeoSite 更新完成"
}

COMPONENT="${1:-}"
VARIANT="${2:-}"   # mihomo/singbox: stable | alpha
[ -n "$COMPONENT" ] || {
  echo "usage: $0 <clashoo|luci|mihomo|singbox|smart|lgbm|china|geoip> [stable|alpha]"
  exit 2
}

mkdir -p "$(dirname "$RUN_FILE")" >/dev/null 2>&1
printf '%s\n' "$COMPONENT" >"$RUN_FILE"
STATUS="running"
log "组件更新任务启动：${COMPONENT}${VARIANT:+ ($VARIANT)}"

case "$COMPONENT" in
  clashoo) run_pkg_update clashoo ;;
  luci)    run_pkg_update luci ;;
  mihomo)
    if [ "$VARIANT" = "alpha" ]; then run_core_update 3 "mihomo Alpha 版"
    else run_core_update 2 "mihomo 稳定版"; fi ;;
  singbox)
    if [ "$VARIANT" = "alpha" ]; then run_core_update 5 "sing-box Alpha 版"
    else run_core_update 4 "sing-box 稳定版"; fi ;;
  smart)   run_core_update 1 "mihomo Smart 版" ;;
  lgbm)    run_lgbm_update ;;
  china)   run_china_update ;;
  geoip)   run_geoip_update ;;
  *) finish 2 "未知组件：${COMPONENT}" ;;
esac
