#!/bin/sh

set -eu

APP="openclawmgr"
UCI_NS="openclawmgr"
LOCK_DIR="/tmp/openclawmgr-installer.lock"
DIAG_PREFIX="/tmp/openclawmgr-diag"
OPENCLAW_STABLE_NPM_TAG="openclaw@2026.10.34"
OPENCLAW_STABLE_VERSION="2026.10.34"
OPENCLAW_COMPAT_NPM_TAG="openclaw@2026.3.28"
OPENCLAW_COMPAT_VERSION="2026.3.28"
INSTALL_CHANNEL="${INSTALL_CHANNEL:-}"

log_ts() { date "+%Y-%m-%d %H:%M:%S"; }

uci_get() { uci -q get "${UCI_NS}.main.$1" 2>/dev/null || true; }

validate_base_dir() {
	local dir="$1"
	dir="$(printf "%s" "$dir" | sed 's/[[:space:]]*$//')"
	dir="${dir%/}"
	[ -n "$dir" ] || return 1
	case "$dir" in
		/*) ;;
		*) return 1 ;;
	esac
	[ "$dir" != "/" ] || return 1
	case "$dir" in
		/root|/root/*) return 1 ;;
	esac
	case "$dir" in
		*"/../"*|*"/.."|*"/./"*|*"/.") return 1 ;;
	esac
	case "$dir" in
		/bin|/bin/*|/sbin|/sbin/*|/lib|/lib/*|/usr|/usr/*|/etc|/etc/*|/proc|/proc/*|/sys|/sys/*|/dev|/dev/*|/run|/run/*|/tmp|/tmp/*|/var|/var/*|/overlay|/overlay/*|/rom|/rom/*)
			return 1
			;;
	esac
	return 0
}

uci_get_list() {
	local key="$1"
	uci -q show "${UCI_NS}.main.${key}" 2>/dev/null | \
		sed -n "s/^${UCI_NS}\\.main\\.${key}='\\(.*\\)'$/\\1/p"
}

json_get() {
	local file="$1" expr="$2"
	[ -f "$file" ] || return 0
	command -v jsonfilter >/dev/null 2>&1 || return 0
	jsonfilter -i "$file" -e "$expr" 2>/dev/null || true
}

load_gateway_runtime_from_json() {
	local cfg="${DATA_DIR}/.openclaw/openclaw.json"
	[ -f "$cfg" ] || return 0
	local json_port json_bind json_token
	json_port="$(json_get "$cfg" '@.gateway.port')"
	json_bind="$(json_get "$cfg" '@.gateway.bind')"
	json_token="$(json_get "$cfg" '@.gateway.auth.token')"
	[ -n "$json_port" ] && PORT="$json_port"
	[ -n "$json_bind" ] && BIND="$json_bind"
	[ -n "$json_token" ] && TOKEN="$json_token"
	# Optional runtime fields must not abort status/recovery under set -e.
	return 0
}

default_allowed_origins() {
	local port="$PORT" ip
	ip="$(uci -q get network.lan.ipaddr 2>/dev/null || true)"
	if [ -z "$ip" ]; then
		ip="$(ip -4 -o addr show br-lan 2>/dev/null | awk '{print $4}' | cut -d/ -f1 | head -n 1)"
	fi
	if [ -n "$ip" ]; then
		printf "http://%s:%s\n" "$ip" "$port"
	fi
}

build_allowed_origins_json() {
	local origins="${1:-}"
	printf "%s" "$origins" | awk '
		BEGIN { first=1; print "[" }
		{
			gsub(/^[ \t]+|[ \t]+$/, "", $0)
			if ($0 == "") next
			gsub(/\\/,"\\\\",$0); gsub(/"/,"\\\"",$0)
			if (first) { first=0; printf "      \"%s\"", $0 }
			else { printf ",\n      \"%s\"", $0 }
		}
		END {
			if (first) { print "]" } else { print "\n    ]" }
		}'
}

has_default_route() {
	ip route 2>/dev/null | grep -q '^default '
}

default_gateway() {
	ip route 2>/dev/null | awk '/^default/{print $3; exit}' 2>/dev/null || true
}

ensure_dirs() {
	mkdir -p "$BASE_DIR" "$NODE_DIR" "$GLOBAL_DIR" "$DATA_DIR/.openclaw/workspace" "$BASE_DIR/npm-cache" || return 1
	printf "%s\n" "managed-by=openclawmgr" >"${BASE_DIR}/.openclawmgr.managed" 2>/dev/null || true
	fix_data_permissions || true
}

fix_data_permissions() {
	# When running under procd as user "openclawmgr", OpenClaw needs write access to data/.openclaw/*
	if ! id openclawmgr >/dev/null 2>&1; then
		return 1
	fi
	chown -R openclawmgr:openclawmgr "$DATA_DIR" || return 1
	chmod -R u+rwX "$DATA_DIR" || return 1
}

check_space_mb() {
	local path="$1" need_mb="$2"
	local avail_kb
	avail_kb="$(df -kP "$path" 2>/dev/null | awk 'NR==2{print $4}' 2>/dev/null || echo 0)"
	[ -n "$avail_kb" ] || avail_kb=0
	if [ "$avail_kb" -lt $((need_mb * 1024)) ] 2>/dev/null; then
		write_installer_log "Insufficient disk space at $path: need ${need_mb}MB, available $((avail_kb / 1024))MB"
		return 1
	fi
	return 0
}

proc_ppid() {
	local pid="$1"
	[ -r "/proc/$pid/stat" ] || return 1
	awk '{print $4}' "/proc/$pid/stat" 2>/dev/null
}

pid_in_own_ancestry() {
	local target="$1" cur depth
	case "$target" in ''|*[!0-9]*) return 1 ;; esac

	cur="$$"
	depth=0
	while [ -n "$cur" ] && [ "$cur" -gt 1 ] 2>/dev/null && [ "$depth" -lt 64 ]; do
		[ "$cur" = "$target" ] && return 0
		cur="$(proc_ppid "$cur" 2>/dev/null || true)"
		depth=$((depth + 1))
	done

	return 1
}

acquire_lock() {
	if mkdir "$LOCK_DIR" 2>/dev/null; then
		echo "$$" >"$LOCK_DIR/pid" 2>/dev/null || true
		trap 'rm -rf "$LOCK_DIR" 2>/dev/null || true' EXIT
		return 0
	fi

	# Lock exists: check if it's stale (e.g. previous task killed or power loss).
	if [ -d "$LOCK_DIR" ]; then
		local pid running
		pid="$(cat "$LOCK_DIR/pid" 2>/dev/null || true)"
		if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
			write_installer_log "Another operation is running (lock: $LOCK_DIR, pid: $pid)"
			exit 2
		fi

		running="false"
		if [ -x /etc/init.d/tasks ] && command -v jsonfilter >/dev/null 2>&1; then
			local st tpid
			st="$(/etc/init.d/tasks task_status "$APP" 2>/dev/null || true)"
			running="$(printf "%s" "$st" | jsonfilter -e '@.running' 2>/dev/null || echo false)"
			tpid="$(printf "%s" "$st" | jsonfilter -e '@.pid' 2>/dev/null || true)"
			if [ "$running" = "true" ]; then
				if [ -n "${tpid:-}" ] && kill -0 "$tpid" 2>/dev/null; then
					if pid_in_own_ancestry "$tpid"; then
						write_installer_log "Stale lock detected for current task, recovering: $LOCK_DIR"
						running="false"
					else
						write_installer_log "Another operation is running (taskd: $APP, pid: $tpid)"
						exit 2
					fi
				fi
				if [ "$running" = "true" ]; then
					# task_status says running, but pid is gone -> stale task record
					write_installer_log "Stale task record detected, clearing: $APP"
					/etc/init.d/tasks task_del "$APP" >/dev/null 2>&1 || true
					running="false"
				fi
			fi
		fi
		if [ "$running" = "true" ]; then
			write_installer_log "Another operation is running (taskd: $APP)"
			exit 2
		fi

		write_installer_log "Stale lock detected, removing: $LOCK_DIR"
		rm -rf "$LOCK_DIR" 2>/dev/null || true
		if mkdir "$LOCK_DIR" 2>/dev/null; then
			echo "$$" >"$LOCK_DIR/pid" 2>/dev/null || true
			trap 'rm -rf "$LOCK_DIR" 2>/dev/null || true' EXIT
			return 0
		fi
	fi

	write_installer_log "Another operation is running (lock: $LOCK_DIR)"
	exit 2
}

gen_token() {
	(hexdump -n 24 -e '24/1 "%02x"' /dev/urandom 2>/dev/null) || \
	(openssl rand -hex 24 2>/dev/null) || \
	(date +%s | md5sum 2>/dev/null | awk '{print $1}')
}

ensure_token() {
	if [ -z "${TOKEN:-}" ]; then
		TOKEN="$(gen_token)"
	fi
}

is_musl() {
	local loader
	ldd --version 2>&1 | grep -qi musl && return 0
	for loader in /lib/ld-musl-*.so.1; do [ ! -e "$loader" ] || return 0; done
	return 1
}

detect_arch() {
	case "$(uname -m 2>/dev/null || echo unknown)" in
		x86_64) echo "linux-x64" ;;
		aarch64) echo "linux-arm64" ;;
		*) echo "unsupported" ;;
	esac
}

write_installer_log() {
	local msg="$1"
	local line
	line="$(printf "%s [%s] %s" "$(log_ts)" "$APP" "$msg")"
	printf "%s\n" "$line"
	if [ -n "${OC_LOG_FILE:-}" ]; then printf '%s\n' "$line" >> "$OC_LOG_FILE"; fi
}

write_operation_result() {
	local operation="$1" rc="$2" outcome="$3" dir file tmp
	case "$operation" in install|upgrade|rollback_previous) ;; *) return 1 ;; esac
	case "$rc" in ''|*[!0-9]*) return 1 ;; esac
	case "$outcome" in success|failed|preserved|rolled-back) ;; *) return 1 ;; esac
	dir="$BASE_DIR/log"; file="$dir/last-operation.json"; tmp="$file.$$"
	[ ! -L "$dir" ] && [ ! -L "$file" ] || return 1
	mkdir -p "$dir" || return 1
	chmod 700 "$dir" || return 1
	printf '{"operation":"%s","exit_code":%s,"outcome":"%s","timestamp":%s}\n' \
		"$operation" "$rc" "$outcome" "$(date +%s)" > "$tmp" || return 1
	chmod 600 "$tmp" || return 1
	mv -f "$tmp" "$file"
}

read_last_operation() {
	local file="$BASE_DIR/log/last-operation.json"
	[ -f "$file" ] && [ ! -L "$file" ] || return 1
	cat "$file"
}

openclaw_bin() {
	local b="${GLOBAL_DIR}/bin/openclaw"
	[ -x "$b" ] && { echo "$b"; return 0; }
	return 1
}

openclaw_cmd() {
	if [ -f "$NODE_DIR/.mise-runtime" ]; then
		/usr/bin/lua /usr/share/openclawmgr/shared-runtime.lua as-app "$BASE_DIR" cli "$@"
		return $?
	fi
	local b
	b="$(openclaw_bin 2>/dev/null || true)"
	[ -n "$b" ] || return 127
	HOME="$DATA_DIR" \
	OPENCLAW_HOME="$DATA_DIR" \
	OPENCLAW_STATE_DIR="${DATA_DIR}/.openclaw" \
	OPENCLAW_CONFIG_PATH="${DATA_DIR}/.openclaw/openclaw.json" \
	PATH="${NODE_DIR}/bin:${GLOBAL_DIR}/bin:/usr/sbin:/usr/bin:/sbin:/bin" \
	"$b" "$@"
}

find_entry() {
	local d="${GLOBAL_DIR}/lib/node_modules/openclaw"
	[ -f "${d}/openclaw.mjs" ] && { echo "${d}/openclaw.mjs"; return 0; }
	[ -f "${d}/dist/cli.js" ] && { echo "${d}/dist/cli.js"; return 0; }
	return 1
}

node_version() {
	[ -x "$NODE_BIN" ] || return 0
	"$NODE_BIN" --version 2>/dev/null || true
}

openclaw_version() {
	local pkg="${GLOBAL_DIR}/lib/node_modules/openclaw/package.json"
	[ -f "$pkg" ] || return 0
	sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$pkg" 2>/dev/null | head -n 1
}

local_openclaw_version() {
	[ -x "$NPM_BIN" ] || return 0
	HOME="$DATA_DIR" npm_config_cache="${BASE_DIR}/npm-cache" \
		PATH="${NODE_DIR}/bin:/usr/sbin:/usr/bin:/sbin:/bin" \
		"$NPM_BIN" list -g openclaw --prefix="$GLOBAL_DIR" --depth=0 --json 2>/dev/null \
		| "$NODE_BIN" -e 'let s="";process.stdin.on("data",d=>s+=d);process.stdin.on("end",()=>{try{let o=JSON.parse(s||"{}");let v=o&&o.dependencies&&o.dependencies.openclaw&&o.dependencies.openclaw.version;if(v)process.stdout.write(String(v));}catch(_){}})'
}

latest_openclaw_version() {
	case "${INSTALL_CHANNEL:-stable}" in
		stable) printf '%s\n' "$OPENCLAW_STABLE_VERSION"; return 0 ;;
		compat) printf '%s\n' "$OPENCLAW_COMPAT_VERSION"; return 0 ;;
		latest) ;;
		*) return 1 ;;
	esac
	[ -x "$NPM_BIN" ] || return 1
	if [ "$INSTALL_ACCELERATED" = 1 ] && [ ! -f "$NODE_DIR/.mise-runtime" ]; then set -- ks-cli npm; else set -- "$NPM_BIN"; fi
	HOME="$DATA_DIR" npm_config_cache="$BASE_DIR/npm-cache" npm_config_registry=https://registry.npmjs.org \
		PATH="${NODE_DIR}/bin:/usr/sbin:/usr/bin:/sbin:/bin" \
		timeout -k 5 30 "$@" view openclaw version
}

target_openclaw_package() {
	case "${INSTALL_CHANNEL:-stable}" in
		stable) printf '%s\n' "$OPENCLAW_STABLE_NPM_TAG" ;;
		compat) printf '%s\n' "$OPENCLAW_COMPAT_NPM_TAG" ;;
		latest) printf '%s\n' "openclaw@latest" ;;
		*) return 1 ;;
	esac
}

have_openclaw_runtime() {
	[ -x "$NODE_BIN" ] || return 1
	if [ -f "$NODE_DIR/.mise-runtime" ]; then
		/usr/bin/lua /usr/share/openclawmgr/shared-runtime.lua inspect "$BASE_DIR/current/runtime.json" >/dev/null 2>&1 || return 1
	fi
	find_entry >/dev/null 2>&1 || return 1
	return 0
}

agent_key_name() {
	case "${DEFAULT_AGENT:-anthropic}" in
		openai) echo "OPENAI_API_KEY" ;;
		anthropic) echo "ANTHROPIC_API_KEY" ;;
		minimax-cn) echo "MINIMAX_API_KEY" ;;
		moonshot) echo "MOONSHOT_API_KEY" ;;
		custom-provider) echo "" ;;
		*) echo "ANTHROPIC_API_KEY" ;;
	esac
}

existing_custom_provider_model() {
	local cfg="${DATA_DIR}/.openclaw/openclaw.json"
	[ -f "$cfg" ] || return 0
	OPENCLAW_CONFIG_PATH="$cfg" lua - <<'EOF'
local json = require "luci.jsonc"

local path = os.getenv("OPENCLAW_CONFIG_PATH")
local f = io.open(path, "r")
if not f then
	return
end
local raw = f:read("*a")
f:close()
local cfg = json.parse(raw or "") or {}

local primary = cfg.agents and cfg.agents.defaults and cfg.agents.defaults.model and cfg.agents.defaults.model.primary
if type(primary) == "string" and primary:match("^custom%-provider/.+") then
	io.write(primary)
	return
end

local providers = cfg.models and cfg.models.providers
local custom = providers and providers["custom-provider"]
local models = custom and custom.models
local first = type(models) == "table" and models[1] or nil
local id = first and first.id
if type(id) == "string" and id ~= "" then
	io.write("custom-provider/" .. id)
end
EOF
}

agent_default_model() {
	case "${DEFAULT_AGENT:-anthropic}" in
		openai)
			if [ -n "${DEFAULT_MODEL:-}" ]; then
				case "$DEFAULT_MODEL" in
					openai/*) echo "$DEFAULT_MODEL" ;;
					*/*) echo "openai/${DEFAULT_MODEL#*/}" ;;
					*) echo "openai/$DEFAULT_MODEL" ;;
				esac
			else
				echo "openai/gpt-5.2"
			fi
			;;
		anthropic)
			if [ -n "${DEFAULT_MODEL:-}" ]; then
				case "$DEFAULT_MODEL" in
					anthropic/*) echo "$DEFAULT_MODEL" ;;
					*/*) echo "anthropic/${DEFAULT_MODEL#*/}" ;;
					*) echo "anthropic/$DEFAULT_MODEL" ;;
				esac
			else
				echo "anthropic/claude-sonnet-4-6"
			fi
			;;
		minimax-cn)
			if [ -n "${DEFAULT_MODEL:-}" ]; then
				case "$DEFAULT_MODEL" in
					minimax-cn/*) echo "$DEFAULT_MODEL" ;;
					*/*) echo "minimax-cn/${DEFAULT_MODEL#*/}" ;;
					*) echo "minimax-cn/$DEFAULT_MODEL" ;;
				esac
			else
				echo "minimax-cn/MiniMax-M2.5"
			fi
			;;
		moonshot)
			if [ -n "${DEFAULT_MODEL:-}" ]; then
				case "$DEFAULT_MODEL" in
					moonshot/*) echo "$DEFAULT_MODEL" ;;
					*/*) echo "moonshot/${DEFAULT_MODEL#*/}" ;;
					*) echo "moonshot/$DEFAULT_MODEL" ;;
				esac
			else
				echo "moonshot/kimi-k2.5"
			fi
			;;
		custom-provider)
			if [ -n "${DEFAULT_MODEL:-}" ]; then
				case "$DEFAULT_MODEL" in
					custom-provider/*) echo "$DEFAULT_MODEL" ;;
					*/*) echo "custom-provider/${DEFAULT_MODEL#*/}" ;;
					*) echo "custom-provider/$DEFAULT_MODEL" ;;
				esac
			else
				local current_model
				current_model="$(existing_custom_provider_model)"
				if [ -n "$current_model" ]; then
					echo "$current_model"
				else
					echo "custom-provider/custom-model"
				fi
			fi
			;;
		*) echo "anthropic/claude-sonnet-4-6" ;;
	esac
}

agent_default_base_url() {
	case "${DEFAULT_AGENT:-anthropic}" in
		openai) echo "https://api.openai.com/v1" ;;
		anthropic) echo "https://api.anthropic.com" ;;
		minimax-cn) echo "https://api.minimaxi.com/anthropic" ;;
		moonshot) echo "https://api.moonshot.cn/v1" ;;
		custom-provider) echo "" ;;
		*) echo "https://api.anthropic.com" ;;
	esac
}

is_valid_http_url() {
	case "${1:-}" in
		http://*|https://*) return 0 ;;
		*) return 1 ;;
	esac
}

ensure_gateway_config() {
	local cfg="${DATA_DIR}/.openclaw/openclaw.json"
	[ -n "${TOKEN:-}" ] || return 1

	if [ -f "$cfg" ]; then
		# Only overwrite configs that look managed by OpenClawMgr (backward compatible).
		if ! grep -Eq '"controlUi"[[:space:]]*:' "$cfg" 2>/dev/null && \
		   ! grep -Eq '"basePath"[[:space:]]*:[[:space:]]*"\\?/openclawmgr"' "$cfg" 2>/dev/null; then
			write_installer_log "Skipping config update because ${cfg} does not look managed by OpenClawMgr"
			return 0
		fi
	fi

	local host_header_fallback="false"
	if [ "$BIND" != "loopback" ]; then
		host_header_fallback="true"
	fi

	local allow_insecure=""
	if [ -n "${ALLOW_INSECURE_AUTH:-}" ]; then
		if [ "$ALLOW_INSECURE_AUTH" = "1" ]; then
			allow_insecure="true"
		else
			allow_insecure="false"
		fi
	fi

	local disable_device_auth=""
	if [ -n "${DISABLE_DEVICE_AUTH:-}" ]; then
		if [ "$DISABLE_DEVICE_AUTH" = "1" ]; then
			disable_device_auth="true"
		else
			disable_device_auth="false"
		fi
	fi

	local allowed_origins="$ALLOWED_ORIGINS"
	local selected_key selected_model selected_base_url override_base_url base_url_mode
	selected_key=""
	selected_model=""
	selected_base_url=""
	override_base_url=""
	base_url_mode=""
	if [ -n "${DEFAULT_AGENT:-}" ]; then
		selected_key="$(agent_key_name)"
		selected_model="$(agent_default_model)"
		selected_base_url="$(agent_default_base_url)"
		base_url_mode="default"
		if [ -n "${PROVIDER_BASE_URL:-}" ]; then
			if is_valid_http_url "$PROVIDER_BASE_URL"; then
				override_base_url="$PROVIDER_BASE_URL"
				base_url_mode="override"
			else
				write_installer_log "Ignoring invalid relay URL for ${DEFAULT_AGENT}: ${PROVIDER_BASE_URL}"
				base_url_mode="preserve"
			fi
		fi
	fi

	mkdir -p "$(dirname "$cfg")" 2>/dev/null || true
	CFG_PATH="$cfg" \
	ALLOWED_ORIGINS_RAW="$allowed_origins" \
	DEFAULT_ALLOWED_ORIGINS_RAW="$(default_allowed_origins)" \
	GATEWAY_PORT="$PORT" \
	GATEWAY_BIND="$BIND" \
	GATEWAY_TOKEN="$TOKEN" \
	GATEWAY_ALLOW_INSECURE="$allow_insecure" \
	GATEWAY_DISABLE_DEVICE_AUTH="$disable_device_auth" \
	GATEWAY_HOST_HEADER_FALLBACK="$host_header_fallback" \
	DEFAULT_AGENT_NAME="${DEFAULT_AGENT:-}" \
	DEFAULT_AGENT_KEY="$selected_key" \
	DEFAULT_AGENT_MODEL="$selected_model" \
	DEFAULT_AGENT_BASE_URL="$selected_base_url" \
	DEFAULT_AGENT_OVERRIDE_BASE_URL="$override_base_url" \
	DEFAULT_AGENT_BASE_URL_MODE="$base_url_mode" \
	DEFAULT_AGENT_API_KEY="${PROVIDER_API_KEY:-}" \
	lua - <<'EOF'
local json = require "luci.jsonc"

local cfg_path = os.getenv("CFG_PATH")
local function slurp(path)
	local f = io.open(path, "r")
	if not f then return nil end
	local data = f:read("*a")
	f:close()
	return data
end

local function bool_env(name)
	return os.getenv(name) == "true"
end

local function optional_env(name)
	local value = os.getenv(name)
	if value == nil or value == "" then
		return nil
	end
	return value
end

local function optional_bool_env(name)
	local value = optional_env(name)
	if value == "true" then
		return true
	end
	if value == "false" then
		return false
	end
	return nil
end

local function split_lines(raw)
	local out = {}
	raw = raw or ""
	for line in raw:gmatch("([^\n]+)") do
		line = line:gsub("^%s+", ""):gsub("%s+$", "")
		if line ~= "" then
			table.insert(out, line)
		end
	end
	return out
end

local function ensure_table(parent, key)
	if type(parent[key]) ~= "table" then
		parent[key] = {}
	end
	return parent[key]
end

local function is_array(node)
	if type(node) ~= "table" then
		return false
	end
	local count = 0
	for k, _ in pairs(node) do
		if type(k) ~= "number" or k < 1 or k % 1 ~= 0 then
			return false
		end
		count = count + 1
	end
	for i = 1, count do
		if node[i] == nil then
			return false
		end
	end
	return true
end

local function prune_empty_tables(node)
	if type(node) ~= "table" then
		return false
	end

	if is_array(node) then
		local compact = {}
		for i = 1, #node do
			local value = node[i]
			if type(value) == "table" then
				if not prune_empty_tables(value) then
					compact[#compact + 1] = value
				end
			else
				compact[#compact + 1] = value
			end
		end
		for i = #node, 1, -1 do
			node[i] = nil
		end
		for i = 1, #compact do
			node[i] = compact[i]
		end
		return #node == 0
	end

	for k, v in pairs(node) do
		if type(v) == "table" and prune_empty_tables(v) then
			node[k] = nil
		end
	end

	return next(node) == nil
end

local function read_config(path)
	local raw = slurp(path)
	if not raw or raw == "" then
		return {}
	end
	return json.parse(raw) or {}
end

local cfg = read_config(cfg_path)

local gateway = ensure_table(cfg, "gateway")
gateway.mode = "local"
gateway.port = tonumber(os.getenv("GATEWAY_PORT")) or 18789
gateway.bind = os.getenv("GATEWAY_BIND") or "lan"
local auth = ensure_table(gateway, "auth")
auth.mode = "token"
auth.token = os.getenv("GATEWAY_TOKEN") or ""

local control = ensure_table(gateway, "controlUi")
control.enabled = true
local configured_origins = optional_env("ALLOWED_ORIGINS_RAW")
if configured_origins then
	control.allowedOrigins = split_lines(configured_origins)
elseif type(control.allowedOrigins) ~= "table" or next(control.allowedOrigins) == nil then
	control.allowedOrigins = split_lines(os.getenv("DEFAULT_ALLOWED_ORIGINS_RAW") or "")
end
local allow_insecure = optional_bool_env("GATEWAY_ALLOW_INSECURE")
if allow_insecure ~= nil then
	control.allowInsecureAuth = allow_insecure
elseif type(control.allowInsecureAuth) ~= "boolean" then
	control.allowInsecureAuth = true
end
local disable_device_auth = optional_bool_env("GATEWAY_DISABLE_DEVICE_AUTH")
if disable_device_auth ~= nil then
	control.dangerouslyDisableDeviceAuth = disable_device_auth
elseif type(control.dangerouslyDisableDeviceAuth) ~= "boolean" then
	control.dangerouslyDisableDeviceAuth = true
end
control.dangerouslyAllowHostHeaderOriginFallback = bool_env("GATEWAY_HOST_HEADER_FALLBACK")

local env = ensure_table(cfg, "env")
local selected_env_key = optional_env("DEFAULT_AGENT_KEY")
local selected_api_key = optional_env("DEFAULT_AGENT_API_KEY")
if selected_env_key and selected_api_key then
	env[selected_env_key] = selected_api_key
end
cfg.env = next(env) and env or nil

local function update_api_key(provider)
	if selected_api_key ~= nil then
		provider.apiKey = selected_api_key ~= "" and selected_api_key or nil
	end
end

local function env_key_for_provider(id)
	if id == "openai" then return "OPENAI_API_KEY" end
	if id == "anthropic" then return "ANTHROPIC_API_KEY" end
	if id == "minimax-cn" then return "MINIMAX_API_KEY" end
	if id == "moonshot" then return "MOONSHOT_API_KEY" end
	return nil
end

	local models = ensure_table(cfg, "models")
	if type(models.mode) ~= "string" or models.mode == "" then
		models.mode = "merge"
	end

	local current_provider_id = optional_env("DEFAULT_AGENT_NAME")
	local primary_model = optional_env("DEFAULT_AGENT_MODEL")
	local current_primary = cfg.agents and cfg.agents.defaults and cfg.agents.defaults.model and cfg.agents.defaults.model.primary
	if not primary_model and type(current_primary) == "string" and current_primary ~= "" then
		primary_model = current_primary
	end
	if not current_provider_id and type(primary_model) == "string" and primary_model:match("^[^/]+/.+") then
		current_provider_id = primary_model:match("^([^/]+)/")
	end
	if not current_provider_id or current_provider_id == "" then
		current_provider_id = "anthropic"
	end
	if not primary_model or primary_model == "" then
		if current_provider_id == "openai" then
			primary_model = "openai/gpt-5.2"
		elseif current_provider_id == "anthropic" then
			primary_model = "anthropic/claude-sonnet-4-6"
		elseif current_provider_id == "minimax-cn" then
			primary_model = "minimax-cn/MiniMax-M2.5"
		elseif current_provider_id == "moonshot" then
			primary_model = "moonshot/kimi-k2.5"
		elseif current_provider_id == "custom-provider" then
			primary_model = "custom-provider/custom-model"
			local custom = models.providers and models.providers["custom-provider"]
			local first = custom and custom.models and custom.models[1]
			if type(first) == "table" and type(first.id) == "string" and first.id ~= "" then
				primary_model = "custom-provider/" .. first.id
			end
		else
			primary_model = "anthropic/claude-sonnet-4-6"
		end
	end
	local current_model_id = primary_model:match("^[^/]+/(.+)$") or primary_model
	if current_model_id == "" then
		current_model_id = "claude-sonnet-4-6"
	end

	local old_providers = type(models.providers) == "table" and models.providers or {}
	local preserved_provider = type(old_providers[current_provider_id]) == "table" and old_providers[current_provider_id] or {}
	local providers = {}
	models.providers = providers
	local current_provider = preserved_provider
	providers[current_provider_id] = current_provider

if current_provider_id == "openai" then
	current_provider.api = "openai-completions"
	current_provider.baseUrl = "https://api.openai.com/v1"
	update_api_key(current_provider)
	current_provider.models = {
		{ id = current_model_id, name = current_model_id },
	}
elseif current_provider_id == "anthropic" then
	current_provider.api = "anthropic-messages"
	current_provider.baseUrl = "https://api.anthropic.com"
	update_api_key(current_provider)
	current_provider.models = {
		{ id = current_model_id, name = current_model_id },
	}
elseif current_provider_id == "minimax-cn" then
	current_provider.api = "anthropic-messages"
	current_provider.baseUrl = "https://api.minimaxi.com/anthropic"
	update_api_key(current_provider)
	current_provider.authHeader = true
	current_provider.models = {
		{ id = current_model_id, name = current_model_id },
	}
elseif current_provider_id == "moonshot" then
	current_provider.api = "openai-completions"
	current_provider.baseUrl = "https://api.moonshot.cn/v1"
	update_api_key(current_provider)
	current_provider.models = {
		{ id = current_model_id, name = current_model_id },
	}
elseif current_provider_id == "custom-provider" then
	if current_model_id == "" then
		current_model_id = "custom-model"
	end
	current_provider.api = "openai-completions"
	current_provider.baseUrl = optional_env("DEFAULT_AGENT_OVERRIDE_BASE_URL") or current_provider.baseUrl
	update_api_key(current_provider)
	current_provider.authHeader = nil
	current_provider.models = {
		{ id = current_model_id, name = current_model_id },
	}
end

	local override_base = optional_env("DEFAULT_AGENT_OVERRIDE_BASE_URL") or ""
	local base_url_mode = optional_env("DEFAULT_AGENT_BASE_URL_MODE") or ""
	if current_provider_id == "custom-provider" and override_base ~= "" then
		current_provider.baseUrl = override_base
	elseif base_url_mode == "override" and override_base ~= "" then
		current_provider.baseUrl = override_base
	elseif base_url_mode == "default" then
		current_provider.baseUrl = optional_env("DEFAULT_AGENT_BASE_URL") or current_provider.baseUrl
	end

local agents = ensure_table(cfg, "agents")
local defaults = ensure_table(agents, "defaults")
local model = ensure_table(defaults, "model")
model.primary = primary_model or "anthropic/claude-sonnet-4-6"

local current_env_key = env_key_for_provider(current_provider_id)
local next_env = {}
if current_env_key and type(current_provider.apiKey) == "string" and current_provider.apiKey ~= "" then
	next_env[current_env_key] = current_provider.apiKey
end
cfg.env = next(next_env) and next_env or nil

prune_empty_tables(cfg)

local encoded = json.stringify(cfg, true)
if encoded then
	encoded = encoded:gsub("\\/", "/")
end
local cfg_temp = cfg_path .. ".openclawmgr.tmp"
local f = assert(io.open(cfg_temp, "w"))
	f:write(encoded or "{}")
	f:write("\n")
f:close()
assert(os.rename(cfg_temp, cfg_path))

local env_path = cfg_path:gsub("openclaw%.json$", "openclaw.env")
local env_temp = env_path .. ".openclawmgr.tmp"
local envf = assert(io.open(env_temp, "w"))
if selected_env_key and selected_env_key ~= "" and selected_api_key and selected_api_key ~= "" then
	local val = tostring(selected_api_key)
	val = val:gsub("\\", "\\\\"):gsub("\n", "\\n"):gsub('"', '\\"')
	envf:write(selected_env_key .. '="' .. val .. '"\n')
end
envf:close()
assert(os.rename(env_temp, env_path))
EOF
	local config_rc=$?
	[ "$config_rc" = 0 ] || return "$config_rc"
	chmod 600 "$cfg" "${DATA_DIR}/.openclaw/openclaw.env"
}

get_running_pid() {
	local pid=""
	pid="$(ubus call service list "{\"name\":\"openclawmgr\"}" 2>/dev/null | jsonfilter -e '$.openclawmgr.instances.gateway.pid' 2>/dev/null || true)"
	case "$pid" in
		''|*[!0-9]*) return 0 ;;
	esac
	[ "$pid" -gt 1 ] 2>/dev/null && kill -0 "$pid" 2>/dev/null || return 0
	printf '%s\n' "$pid"
}

. /usr/share/openclawmgr/install-runtime.sh

do_uninstall() {
	acquire_lock
	oc_require_no_pending_transactions || return $?
	write_installer_log "== uninstall begin =="
	/etc/init.d/openclawmgr stop >/dev/null 2>&1 || true
	/etc/init.d/openclawmgr disable >/dev/null 2>&1 || true
	uci -q set "${UCI_NS}.main.enabled=0" && uci -q commit "$UCI_NS" || true

	oc_remove_runtime || return $?
	write_installer_log "Runtime removed (node/global)"
	write_installer_log "== uninstall done =="
}

do_uninstall_openclaw() {
	acquire_lock
	oc_require_no_pending_transactions || return $?
	write_installer_log "== uninstall openclaw begin =="
	/etc/init.d/openclawmgr stop >/dev/null 2>&1 || true
	/etc/init.d/openclawmgr disable >/dev/null 2>&1 || true
	uci -q set "${UCI_NS}.main.enabled=0" && uci -q commit "$UCI_NS" || true

	rm -rf "${GLOBAL_DIR}/lib/node_modules/openclaw" \
		"${GLOBAL_DIR}/bin/openclaw" 2>/dev/null || true
	write_installer_log "OpenClaw removed (node kept)"
	write_installer_log "== uninstall openclaw done =="
}

do_purge() {
	acquire_lock
	oc_require_no_pending_transactions || return $?
	write_installer_log "== purge begin =="
	/etc/init.d/openclawmgr stop >/dev/null 2>&1 || true
	/etc/init.d/openclawmgr disable >/dev/null 2>&1 || true
	uci -q set "${UCI_NS}.main.enabled=0" && uci -q commit "$UCI_NS" || true
	# Safety: only remove the whole base_dir when it looks like a dedicated OpenClawMgr directory.
	# Otherwise, only remove managed subdirectories to avoid accidental system wipe.
	if [ -f "${BASE_DIR}/.openclawmgr.managed" ] || [ "$(basename "$BASE_DIR" 2>/dev/null || echo "")" = "OpenClawMgr" ]; then
		rm -rf "$BASE_DIR" 2>/dev/null || true
		write_installer_log "Base dir removed: $BASE_DIR"
	else
		oc_remove_runtime || return $?
		rm -rf "$DATA_DIR" "$BASE_DIR/npm-cache" "$BASE_DIR/backups" "${BASE_DIR}/.openclawmgr.managed"
		write_installer_log "Base dir kept (safety). Removed: node/global/data/npm-cache under $BASE_DIR"
	fi
	write_installer_log "== purge done =="
}

do_start() {
	acquire_lock
	write_installer_log "== start begin =="
	ensure_dirs || return 1
	fix_data_permissions || return 1
	ensure_token
	ensure_safe_port_for_start || exit 1
	/etc/init.d/openclawmgr enable >/dev/null 2>&1 || return 1
	uci -q set "${UCI_NS}.main.enabled=1" && uci -q commit "$UCI_NS" || return 1
	/etc/init.d/openclawmgr restart >/dev/null 2>&1 || return 1
	if [ -f "$NODE_DIR/.mise-runtime" ]; then
		write_installer_log "Background startup submitted; inspect Runtime Environments tasks while fixed dependencies are prepared."
	else
		oc_health || return 1
	fi
	write_installer_log "== start done =="
}

do_stop() {
	acquire_lock
	write_installer_log "== stop begin =="
	/etc/init.d/openclawmgr stop >/dev/null 2>&1 || return 1
	/etc/init.d/openclawmgr disable >/dev/null 2>&1 || return 1
	uci -q set "${UCI_NS}.main.enabled=0" && uci -q commit "$UCI_NS" || return 1
	write_installer_log "== stop done =="
}

do_restart() {
	acquire_lock
	write_installer_log "== restart begin =="
	ensure_dirs || return 1
	fix_data_permissions || return 1
	ensure_token
	ensure_safe_port_for_start || exit 1
	/etc/init.d/openclawmgr restart >/dev/null 2>&1 || return 1
	if [ -f "$NODE_DIR/.mise-runtime" ]; then
		write_installer_log "Background startup submitted; inspect Runtime Environments tasks while fixed dependencies are prepared."
	else
		oc_health || return 1
	fi
	write_installer_log "== restart done =="
}

	do_apply_config() {
		acquire_lock
		write_installer_log "== apply_config begin =="
		ensure_dirs || return 1
		fix_data_permissions || return 1
		ensure_token
		ensure_gateway_config || return 1

		local pid=""
		pid="$(ubus call service list "{\"name\":\"openclawmgr\"}" 2>/dev/null | jsonfilter -e '$.openclawmgr.instances.gateway.pid' 2>/dev/null || true)"
		if [ "${ENABLED:-0}" = "1" ]; then
			ensure_safe_port_for_start || exit 1
			/etc/init.d/openclawmgr enable >/dev/null 2>&1 || return 1
			if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
				/etc/init.d/openclawmgr restart >/dev/null 2>&1 || return 1
			else
				/etc/init.d/openclawmgr start >/dev/null 2>&1 || return 1
			fi
		else
			/etc/init.d/openclawmgr stop >/dev/null 2>&1 || return 1
			/etc/init.d/openclawmgr disable >/dev/null 2>&1 || return 1
		fi

	[ "${ENABLED:-0}" != 1 ] || oc_health || return 1
	write_installer_log "== apply_config done =="
}

do_status() {
	local entry
	entry="$(find_entry 2>/dev/null || true)"
	[ -n "$entry" ] || return 0
	if [ -f "$NODE_DIR/.mise-runtime" ] && ! /usr/bin/lua /usr/share/openclawmgr/shared-runtime.lua inspect "$BASE_DIR/current/runtime.json" >/dev/null 2>&1; then
		echo "runtime-missing"
		return 0
	fi
	local pid=""
	pid="$(get_running_pid)"
	if [ -n "$pid" ]; then
		echo "running"
		return 0
	fi
	echo "stopped"
}

do_port() { echo "$PORT"; }
do_token() { echo "${TOKEN:-}"; }

diag_paths() {
	local name="$1"
	DIAG_LOG="${DIAG_PREFIX}-${name}.log"
	DIAG_PID="${DIAG_PREFIX}-${name}.pid"
	DIAG_EXIT="${DIAG_PREFIX}-${name}.exit"
	DIAG_LOCK="${DIAG_PREFIX}-${name}.lock"
}

diag_busy() {
	local name="$1"
	diag_paths "$name"
	[ -d "$DIAG_LOCK" ] && return 0
	return 1
}

diag_run() {
	local name="$1" limit="${2:-200}"
	case "$name" in
		doctor|gateway_status|gateway_health|logs|channels_status) ;;
		*) echo "unknown diag: $name" >&2; exit 1 ;;
	esac

	diag_paths "$name"
	if ! mkdir "$DIAG_LOCK" 2>/dev/null; then
		echo "busy" >&2
		exit 2
	fi

	rm -f "$DIAG_EXIT" 2>/dev/null || true
	: >"$DIAG_LOG"
	echo "$$" >"$DIAG_PID"

	(
		set +e
		echo "== $APP diag: $name ==" 
		echo "time: $(log_ts)"
		echo "base_dir: $BASE_DIR"
		echo "config: ${DATA_DIR}/.openclaw/openclaw.json"
		echo ""

		case "$name" in
			doctor)
				NO_COLOR=1 openclaw_cmd doctor
				;;
			gateway_status)
				NO_COLOR=1 openclaw_cmd gateway status --url "ws://127.0.0.1:${PORT}" --token "${TOKEN}"
				;;
			gateway_health)
				NO_COLOR=1 openclaw_cmd gateway health --url "ws://127.0.0.1:${PORT}" --token "${TOKEN}"
				;;
			logs)
				case "$limit" in ''|*[!0-9]*) limit=200 ;; esac
				[ "$limit" -gt 2000 ] && limit=2000
				[ "$limit" -lt 10 ] && limit=10
				NO_COLOR=1 openclaw_cmd logs --plain --limit "$limit"
				;;
			channels_status)
				NO_COLOR=1 openclaw_cmd channels status
				;;
		esac
		rc=$?
		echo ""
		echo "exit_code: $rc"
		exit "$rc"
	) >>"$DIAG_LOG" 2>&1

	rc=$?
	echo "$rc" >"$DIAG_EXIT"
	rm -f "$DIAG_PID" 2>/dev/null || true
	rmdir "$DIAG_LOCK" 2>/dev/null || true
	exit "$rc"
}

diag_poll() {
	local name="$1"
	case "$name" in
		doctor|gateway_status|gateway_health|logs|channels_status) ;;
		*) echo "unknown diag: $name" >&2; exit 1 ;;
	esac

	diag_paths "$name"

	local running=0
	if [ -f "$DIAG_PID" ]; then
		local pid
		pid="$(cat "$DIAG_PID" 2>/dev/null || true)"
		if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
			running=1
		fi
	fi

	if [ "$running" -eq 1 ]; then
		echo "running"
		exit 0
	fi
	if [ -f "$DIAG_EXIT" ]; then
		echo "done:$(cat "$DIAG_EXIT" 2>/dev/null || echo -1)"
		exit 0
	fi
	echo "idle"
}

ACTION="${1:-help}"
shift 1 || true

BASE_DIR="$(uci_get base_dir)"
ENABLED="$(uci_get enabled)"
PORT="$(uci_get port)"
BIND="$(uci_get bind)"
TOKEN="$(uci_get token)"
	ALLOW_INSECURE_AUTH="$(uci_get allow_insecure_auth)"
	DISABLE_DEVICE_AUTH="$(uci_get disable_device_auth)"
ALLOWED_ORIGINS="$(uci_get_list allowed_origins)"
DEFAULT_AGENT="$(uci_get default_agent)"
DEFAULT_MODEL="$(uci_get default_model)"
INSTALL_ACCELERATED="$(uci_get install_accelerated)"
PROVIDER_API_KEY="$(uci_get provider_api_key)"
PROVIDER_BASE_URL="$(uci_get provider_base_url)"

[ -n "$PORT" ] || PORT="18789"
[ -n "$BIND" ] || BIND="lan"
[ -n "$ENABLED" ] || ENABLED="0"
[ -n "$INSTALL_ACCELERATED" ] || INSTALL_ACCELERATED="1"
[ -n "$INSTALL_CHANNEL" ] || INSTALL_CHANNEL="stable"

case "$PORT" in
	''|*[!0-9]*) PORT="18789" ;;
esac
if [ "$PORT" -lt 1 ] 2>/dev/null || [ "$PORT" -gt 65535 ] 2>/dev/null; then
	PORT="18789"
fi
case "$BIND" in
	loopback|lan|auto|tailnet|custom) ;;
	*) BIND="lan" ;;
esac
case "$ENABLED" in
	1|true|yes|on) ENABLED="1" ;;
	*) ENABLED="0" ;;
esac
case "$ALLOW_INSECURE_AUTH" in
	'') ;;
	1|true|yes|on) ALLOW_INSECURE_AUTH="1" ;;
	*) ALLOW_INSECURE_AUTH="0" ;;
esac
case "$DISABLE_DEVICE_AUTH" in
	'') ;;
	1|true|yes|on) DISABLE_DEVICE_AUTH="1" ;;
	*) DISABLE_DEVICE_AUTH="0" ;;
esac
case "$DEFAULT_AGENT" in
	'') ;;
	openai|anthropic|minimax-cn|moonshot|custom-provider) ;;
	*) DEFAULT_AGENT="anthropic" ;;
esac
case "$INSTALL_ACCELERATED" in
	1|true|yes|on) INSTALL_ACCELERATED="1" ;;
	*) INSTALL_ACCELERATED="0" ;;
esac
case "$INSTALL_CHANNEL" in
	stable|latest|compat) ;;
	*) write_installer_log "Invalid install channel: $INSTALL_CHANNEL"; exit 2 ;;
esac

require_base_dir() {
	if [ -z "$BASE_DIR" ]; then
		write_installer_log "base_dir is not configured; please choose a data directory in LuCI and Save & Apply, then retry."
		exit 2
	fi
	if ! validate_base_dir "$BASE_DIR"; then
		write_installer_log "Refusing to operate on unsafe base_dir: $BASE_DIR"
		write_installer_log "Fix: choose a dedicated persistent directory like /mnt/.../OpenClawMgr"
		exit 2
	fi
	# Stop remains available when a disk is offline. Every filesystem mutation
	# requires the real data mount and separation from shared SDK storage.
	if [ "$ACTION" != stop ]; then
		/usr/bin/lua /usr/share/openclawmgr/shared-runtime.lua preflight "$BASE_DIR" || exit 2
	fi
}

ensure_safe_port_for_start() {
	case "$PORT" in
		''|*[!0-9]*) return 1 ;;
	esac
	if [ "$PORT" -le 1024 ] 2>/dev/null; then
		write_installer_log "Refusing to start with unsafe port $PORT (must be >1024)."
		return 1
	fi
	return 0
}

NODE_DIR="${BASE_DIR}/node"
GLOBAL_DIR="${BASE_DIR}/global"
DATA_DIR="${BASE_DIR}/data"

if [ -n "$BASE_DIR" ]; then
	load_gateway_runtime_from_json
fi

case "$PORT" in
	''|*[!0-9]*) PORT="18789" ;;
esac
if [ "$PORT" -lt 1 ] 2>/dev/null || [ "$PORT" -gt 65535 ] 2>/dev/null; then
	PORT="18789"
fi
case "$BIND" in
	loopback|lan|auto|tailnet|custom) ;;
	*) BIND="lan" ;;
esac

	NODE_BIN="${NODE_DIR}/bin/node"
	NPM_BIN="${NODE_DIR}/bin/npm"

case "$ACTION" in
	cancel_install)
		do_cancel_install
		;;
	recover_rollback)
		require_base_dir
		do_recover_rollback
		;;
	recover_install)
		require_base_dir
		do_recover_install
		;;
	rollback_previous)
		require_base_dir
		do_rollback_previous
		;;
	rollback_previous_version)
		require_base_dir
		rollback_previous_version
		;;
	last_operation)
		require_base_dir
		read_last_operation
		;;
	install|upgrade)
		require_base_dir
		do_install
		;;
	uninstall)
		require_base_dir
		do_uninstall
		;;
	uninstall_openclaw)
		require_base_dir
		do_uninstall_openclaw
		;;
	purge)
		require_base_dir
		do_purge
		;;
	rm)
		require_base_dir
		do_uninstall
		;;
	start)
		require_base_dir
		do_start
		;;
	stop)
		require_base_dir
		do_stop
		;;
	restart)
		require_base_dir
		do_restart
		;;
	apply_config)
		require_base_dir
		do_apply_config
		;;
	status)
		[ -n "$BASE_DIR" ] || exit 0
		do_status
		;;
	runtime_ready)
		have_openclaw_runtime
		;;
	port)
		do_port
		;;
	token)
		do_token
		;;
	node_version)
		node_version
		;;
	openclaw_version)
		openclaw_version
		;;
	local_openclaw_version)
		local_openclaw_version
		;;
	latest_openclaw_version)
		latest_openclaw_version
		;;
	diag)
		diag_run "${1:-}" "${2:-}"
		;;
	diag_poll)
		diag_poll "${1:-}"
		;;
	*)
		echo "Usage: $0 {install|upgrade|rollback_previous|rollback_previous_version|last_operation|recover_install|recover_rollback|cancel_install|uninstall|uninstall_openclaw|purge|rm|start|stop|restart|status|port|token|node_version|openclaw_version|local_openclaw_version|latest_openclaw_version|diag|diag_poll}" >&2
		exit 1
		;;
esac
