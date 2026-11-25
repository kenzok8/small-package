#!/bin/sh
# OpenClawMgr CLI Config Helper (for ttyd)

set -eu

export TERM="${TERM:-xterm-256color}"

ESC="$(printf '\033')"
RED="${ESC}[0;31m"; GREEN="${ESC}[0;32m"; YELLOW="${ESC}[1;33m"
CYAN="${ESC}[0;36m"; BOLD="${ESC}[1m"; DIM="${ESC}[2m"; NC="${ESC}[0m"

err() { printf '%s\n' "${RED}ERROR: $*${NC}"; }
warn() { printf '%s\n' "${YELLOW}$*${NC}"; }
info() { printf '%s\n' "${CYAN}$*${NC}"; }
ok() { printf '%s\n' "${GREEN}$*${NC}"; }

pause_enter() {
	printf "\n%s按回车继续...%s" "$DIM" "$NC"
	IFS= read -r _ || true
}

prompt_default() {
	local prompt="$1" def="${2:-}" v=""
	if [ -n "$def" ]; then
		printf "%s%s[%s]%s: " "$prompt" "$DIM" "$def" "$NC" >&2
	else
		printf "%s: " "$prompt" >&2
	fi
	IFS= read -r v || v=""
	[ -z "$v" ] && v="$def"
	printf "%s" "$v"
}

uci_get() { uci -q get "openclawmgr.main.$1" 2>/dev/null || true; }

is_musl() {
	local loader
	ldd --version 2>&1 | grep -qi musl && return 0
	for loader in /lib/ld-musl-*.so.1; do [ ! -e "$loader" ] || return 0; done
	return 1
}

# Same process-local npm policy as the installer; no persistent Git rewrites.
. /usr/share/openclawmgr/npm-env.sh

init_npm_env() {
	INSTALL_ACCELERATED="${INSTALL_ACCELERATED:-$(uci_get install_accelerated)}"
	[ -n "$INSTALL_ACCELERATED" ] || INSTALL_ACCELERATED=1
	case "$INSTALL_ACCELERATED" in 1|true|yes|on) INSTALL_ACCELERATED=1 ;; *) INSTALL_ACCELERATED=0 ;; esac
	oc_npm_environment
	export npm_config_prefix="$GLOBAL_DIR"
	NPM_CACHE_DIR="$BASE_DIR/npm-cache"
}

init_paths() {
	BASE_DIR="${BASE_DIR:-$(uci_get base_dir)}"
	if [ -z "$BASE_DIR" ]; then
		err "base_dir 未配置。请先在 OpenClaw 启动器页面设置数据目录并保存应用。"
		exit 1
	fi

	NODE_DIR="${BASE_DIR}/node"
	GLOBAL_DIR="${BASE_DIR}/global"
	DATA_DIR="${BASE_DIR}/data"

	NODE_BIN="${NODE_DIR}/bin/node"
	OPENCLAW_BIN="${GLOBAL_DIR}/bin/openclaw"
	CONFIG_FILE="${DATA_DIR}/.openclaw/openclaw.json"
	BACKUP_DIR="${DATA_DIR}/.openclaw/backups"

	export HOME="$DATA_DIR"
	export OPENCLAW_HOME="$DATA_DIR"
	export OPENCLAW_STATE_DIR="${DATA_DIR}/.openclaw"
	export OPENCLAW_CONFIG_PATH="$CONFIG_FILE"
	export PATH="${NODE_DIR}/bin:${GLOBAL_DIR}/bin:/usr/sbin:/usr/bin:/sbin:/bin"
	init_npm_env
	export OPENCLAWMGR_NPM="$NODE_DIR/bin/npm" OPENCLAWMGR_ACCELERATED="$INSTALL_ACCELERATED"
	export PATH="/usr/share/openclawmgr/cli-bin:$PATH"
}

find_openclaw_entry() {
	local d="${GLOBAL_DIR}/lib/node_modules/openclaw"
	[ -f "${d}/openclaw.mjs" ] && { echo "${d}/openclaw.mjs"; return 0; }
	[ -f "${d}/dist/cli.js" ] && { echo "${d}/dist/cli.js"; return 0; }
	return 1
}

openclaw_cmd() {
	if [ -f "$NODE_DIR/.mise-runtime" ]; then
		/usr/bin/lua /usr/share/openclawmgr/shared-runtime.lua as-app "$BASE_DIR" cli "$@"
		return $?
	fi
	if [ -x "$OPENCLAW_BIN" ]; then
		"$OPENCLAW_BIN" "$@"
		return $?
	fi

	local entry=""
	entry="$(find_openclaw_entry 2>/dev/null || true)"
	if [ -x "$NODE_BIN" ] && [ -n "$entry" ]; then
		"$NODE_BIN" "$entry" "$@"
		return $?
	fi

	err "OpenClaw 未安装或运行时不完整。"
	printf '%s\n' "HINT: 在 OpenClaw 启动器页面执行安装/升级。"
	return 127
}

openclaw() {
	openclaw_cmd "$@"
}

first_line_or_empty() {
	sed -n '1p' 2>/dev/null || true
}

detect_openclaw_version() {
	local v=""
	v="$(openclaw_cmd --version 2>/dev/null | first_line_or_empty)"
	if [ -z "$v" ]; then
		v="$(openclaw_cmd version 2>/dev/null | first_line_or_empty)"
	fi
	printf '%s' "$v"
}

print_cli_env_summary() {
	local node_v npm_v openclaw_v npm_registry musl_state ignore_scripts node_libc
	node_v="$(node -v 2>/dev/null | first_line_or_empty)"
	npm_v="$(npm -v 2>/dev/null | first_line_or_empty)"
	openclaw_v="$(detect_openclaw_version)"
	npm_registry="$(npm config get registry 2>/dev/null | tr -d '\r' | first_line_or_empty)"
	musl_state="no"
	ignore_scripts="${npm_config_ignore_scripts:-false}"
	is_musl && musl_state="yes"
	node_libc="$(node -p 'process.report.getReport().header.glibcVersionRuntime || "musl"' 2>/dev/null | first_line_or_empty)"

	[ -n "$node_v" ] || node_v="未安装"
	[ -n "$npm_v" ] || npm_v="未安装"
	[ -n "$openclaw_v" ] || openclaw_v="未安装"
	[ -n "$npm_registry" ] || npm_registry="unknown"

	printf '%s\n' "${BOLD}环境摘要${NC}"
	printf '%s\n' "  base_dir      ${BASE_DIR}"
	printf '%s\n' "  config        ${CONFIG_FILE}"
	printf '%s\n' "  node          ${node_v}"
	printf '%s\n' "  npm           ${npm_v}"
	printf '%s\n' "  npm prefix    ${npm_config_prefix:-${GLOBAL_DIR}}"
	printf '%s\n' "  npm cache     ${npm_config_cache:-${NPM_CACHE_DIR:-}}"
	printf '%s\n' "  npm registry  ${npm_registry}"
	printf '%s\n' "  host musl     ${musl_state}"
	printf '%s\n' "  node glibc    ${node_libc:-unknown}"
	printf '%s\n' "  ignore scripts ${ignore_scripts}"
	printf '%s\n' "  openclaw      ${openclaw_v}"
}

action_backup_config() {
	mkdir -p "$BACKUP_DIR" 2>/dev/null || true
	if [ ! -f "$CONFIG_FILE" ]; then
		warn "配置文件不存在，无法备份。"
		return 1
	fi
	local ts dst
	ts="$(date -u +%Y-%m-%dT%H-%M-%SZ 2>/dev/null || date +%s)"
	dst="${BACKUP_DIR}/${ts}-openclaw.json"
	cp -f "$CONFIG_FILE" "$dst"
	ok "已备份到: ${dst}"
}

action_restore_config() {
	mkdir -p "$BACKUP_DIR" 2>/dev/null || true
	printf '\n'
	info "=== 可用备份 ==="
	ls -lt "$BACKUP_DIR"/*.json 2>/dev/null | head -10 | awk '{print "  " $NF}' || warn "(无备份)"
	printf '\n'
	local fp=""
	fp="$(prompt_default "请输入要恢复的备份文件路径" "")"
	[ -n "$fp" ] || return 0
	if [ ! -f "$fp" ]; then
		warn "文件不存在：${fp}"
		return 1
	fi
	cp -f "$fp" "$CONFIG_FILE"
	ok "已恢复配置到: ${CONFIG_FILE}"
}

action_configure() {
	printf '\n'
	info "=== openclaw configure ==="
	openclaw_cmd configure || true
}

action_cli_env() {
	printf '\n'
	info "=== OpenClaw CLI 环境 ==="
	printf '%s\n' "${DIM}已注入 BASE_DIR / NODE_DIR / GLOBAL_DIR / DATA_DIR / OPENCLAW_* / PATH / npm_config_*${NC}"
	printf '%s\n' "${DIM}可直接执行 openclaw doctor / openclaw configure / node -v / npm -v 等命令${NC}"
	printf '%s\n' "${DIM}此环境下 npm -g 默认安装到 ${GLOBAL_DIR}，并复用 OpenClawMgr 的缓存/镜像配置${NC}"
	printf '%s\n' "${DIM}开启安装加速时 npm 通过 ks-cli 执行；Git 与安装脚本的其他下载需单独配置${NC}"
	printf '%s\n' "${DIM}输入 exit 可退出终端${NC}"
	printf '\n'
	print_cli_env_summary
	if cd "$DATA_DIR" 2>/dev/null; then
		printf '%s\n' "${DIM}当前目录: ${DATA_DIR}${NC}"
	else
		warn "无法切换到数据目录，保持当前目录不变。"
	fi
	printf '\n'
	exec sh -i
}

main_menu() {
	while true; do
		printf '\n'
		printf '%s\n' "${BOLD}OpenClaw AI Gateway — CLI 配置入口（OpenClawMgr）${NC}"
		printf '%s\n' "${DIM}base_dir: ${BASE_DIR}${NC}"
		printf '\n'
		printf '%s\n' "  ${CYAN}1)${NC} 💻 CLI环境  ${DIM}(仅注入环境，不执行 configure)${NC}"
		printf '%s\n' "  ${CYAN}2)${NC} 🧭 官方配置向导  ${DIM}(openclaw configure)${NC}"
		printf '%s\n' "  ${CYAN}3)${NC} 💾 备份配置"
		printf '%s\n' "  ${CYAN}4)${NC} 📥 恢复配置"
		printf '\n'
		printf '%s\n' "  ${CYAN}0)${NC} 退出"
		printf '\n'

		local c=""
		c="$(prompt_default "请选择" "1")"
		case "$c" in
			1) action_cli_env ;;
			2) action_configure; pause_enter ;;
			3) action_backup_config || true; pause_enter ;;
			4) action_restore_config || true; pause_enter ;;
			0) ok "再见！"; exit 0 ;;
			*) warn "无效选择" ;;
		esac
	done
}

init_paths

case "${1:-}" in
	--help|-h)
		echo "Usage: openclawmgr-cli.sh [configure|cli-env|backup|restore]"
		;;
	*)
		case "${1:-menu}" in
			menu) main_menu ;;
			configure) action_configure; pause_enter ;;
			cli-env) action_cli_env ;;
			backup) action_backup_config || true; pause_enter ;;
			restore) action_restore_config || true; pause_enter ;;
			*) echo "Unknown command: ${1:-}" >&2; exit 2 ;;
		esac
		;;
esac
