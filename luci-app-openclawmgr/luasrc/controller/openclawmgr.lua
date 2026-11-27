module("luci.controller.openclawmgr", package.seeall)

function index()
	local fs = require "nixio.fs"
	if not fs.access("/etc/config/openclawmgr") then
		return
	end

	entry({"admin", "services", "openclawmgr"}, alias("admin", "services", "openclawmgr", "config"), _("OpenClaw 启动器"), 90).dependent = true
	local page = entry({"admin", "services", "openclawmgr", "config"}, call("action_app"), _("Config"), 10)
	page.leaf = true

	entry({"admin", "services", "openclawmgr", "cli"}, form("openclawmgr/cli"), _("命令行"), 20).leaf = true
	entry({"admin", "services", "openclawmgr", "logs"}, template("openclawmgr/logs"), _("日志"), 30).leaf = true

	entry({"admin", "services", "openclawmgr", "status"}, call("action_status")).leaf = true
	entry({"admin", "services", "openclawmgr", "ready"}, call("action_ready")).leaf = true
	entry({"admin", "services", "openclawmgr", "op"}, call("action_op")).leaf = true
	entry({"admin", "services", "openclawmgr", "check_update"}, call("action_check_update")).leaf = true
	entry({"admin", "services", "openclawmgr", "config_data"}, call("action_config_data")).leaf = true
	entry({"admin", "services", "openclawmgr", "apply_config"}, call("action_apply_config")).leaf = true
	entry({"admin", "services", "openclawmgr", "security_data"}, call("action_security_data")).leaf = true
	entry({"admin", "services", "openclawmgr", "security_add"}, call("action_security_add")).leaf = true
	entry({"admin", "services", "openclawmgr", "security_remove"}, call("action_security_remove")).leaf = true
	entry({"admin", "services", "openclawmgr", "security_recheck"}, call("action_security_recheck")).leaf = true

	entry({"admin", "services", "openclawmgr", "logs_api"}, call("action_logs")).leaf = true

	entry({"admin", "services", "openclawmgr", "diag_info"}, call("action_diag_info")).leaf = true
	entry({"admin", "services", "openclawmgr", "diag_run"}, call("action_diag_run")).leaf = true
	entry({"admin", "services", "openclawmgr", "diag_poll"}, call("action_diag_poll")).leaf = true
end

function action_app()
	local http = require "luci.http"
	local tmpl = require "luci.template"
	local disp = require "luci.dispatcher"
	local ctx = disp.context or {}

	tmpl.render("openclawmgr/app", {
		token = ctx.token or "",
	})
	http.close()
end

local function lan_ipv4()
	local sys = require "luci.sys"
	local jsonc = require "luci.jsonc"
	local raw = sys.exec("ubus call network.interface.lan status 2>/dev/null")
	local obj = jsonc.parse(raw)
	if obj and obj["ipv4-address"] then
		for _, addr in ipairs(obj["ipv4-address"]) do
			if addr.address and addr.address ~= "" then
				return addr.address
			end
		end
	end
	return ""
end

local function default_allowed_origin(port_val)
	local ip = lan_ipv4()
	if ip ~= "" then
		return "http://" .. ip .. ":" .. port_val
	end
	return ""
end

local function write_json(obj)
	local http = require "luci.http"
	http.prepare_content("application/json")
	http.write_json(obj)
end

local function read_json_file(path)
	local jsonc = require "luci.jsonc"
	local f = io.open(path, "r")
	if not f then return nil end
	local raw = f:read("*a")
	f:close()
	if not raw or raw == "" then return nil end
	return jsonc.parse(raw)
end

local function openclaw_config_path(base_dir)
	base_dir = tostring(base_dir or ""):gsub("^%s+", ""):gsub("%s+$", "")
	if base_dir == "" then
		return ""
	end
	return base_dir .. "/data/.openclaw/openclaw.json"
end

local function get_runtime_gateway_config(base_dir, fallback)
	fallback = fallback or {}
	local cfg = read_json_file(openclaw_config_path(base_dir)) or {}
	local gateway = cfg.gateway or {}
	local auth = gateway.auth or {}
	local port = tostring(gateway.port or fallback.port or "18789")
	if not port:match("^%d+$") then
		port = tostring(fallback.port or "18789")
	end
	if not port:match("^%d+$") then
		port = "18789"
	end
	local bind = tostring(gateway.bind or fallback.bind or "lan")
	if bind ~= "loopback" and bind ~= "lan" and bind ~= "auto" and bind ~= "tailnet" and bind ~= "custom" then
		bind = tostring(fallback.bind or "lan")
		if bind ~= "loopback" and bind ~= "lan" and bind ~= "auto" and bind ~= "tailnet" and bind ~= "custom" then
			bind = "lan"
		end
	end
	local token = tostring(auth.token or fallback.token or "")
	return {
		port = port,
		bind = bind,
		token = token,
	}
end

local function read_json_body()
	local http = require "luci.http"
	local jsonc = require "luci.jsonc"
	local ctype = http.getenv("CONTENT_TYPE") or ""
	if not ctype:match("^application/json") then
		return nil
	end
	local raw = http.content() or ""
	if #raw == 0 then
		return nil
	end
	local obj = jsonc.parse(raw)
	if type(obj) ~= "table" then
		return nil
	end
	return obj
end

local function get_task_state(task_id)
	local fs = require "nixio.fs"
	local jsonc = require "luci.jsonc"
	local sys = require "luci.sys"

	if not fs.access("/etc/init.d/tasks") then
		return {
			running = false,
			op = "",
			command = "",
		}
	end

	local raw = sys.exec("/etc/init.d/tasks task_status " .. task_id .. " 2>/dev/null")
	local obj = jsonc.parse(raw) or {}
	local cmd = ""
	local cmd_parts = {}

	local function as_bool(v)
		return v == true or v == "true" or v == "1" or v == 1
	end

	if type(obj.command) == "table" then
		cmd_parts = obj.command
		cmd = table.concat(obj.command, " ")
	elseif type(obj.command) == "string" then
		cmd = obj.command
	elseif type(obj.data) == "table" and type(obj.data.command) == "string" then
		cmd = obj.data.command
	end

	local op = ""
	for _, candidate in ipairs({ "rollback_previous", "install", "upgrade", "uninstall_openclaw", "uninstall", "purge", "restart", "start", "stop" }) do
		if cmd:match("%f[%w_]" .. candidate .. "%f[^%w_]") then
			op = candidate
			break
		end
		for _, part in ipairs(cmd_parts) do
			if type(part) == "string" and part:match("%f[%w_]" .. candidate .. "%f[^%w_]") then
				op = candidate
				break
			end
		end
		if op ~= "" then
			break
		end
	end

	return {
		running = as_bool(obj.running),
		op = op,
		command = cmd,
		pid = obj.pid and tostring(obj.pid) or "",
	}
end

local function safe_int(v, def, minv, maxv)
	v = tostring(v or "")
	local n = tonumber(v)
	if not n then
		return def
	end
	n = math.floor(n)
	if minv and n < minv then
		return minv
	end
	if maxv and n > maxv then
		return maxv
	end
	return n
end

local function trim(v)
	return tostring(v or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function normalize_dir_path(path)
	path = trim(path)
	if path == "" then
		return ""
	end
	if path ~= "/" then
		path = path:gsub("/+$", "")
		if path == "" then
			path = "/"
		end
	end
	return path
end

local function validate_base_dir_input(path)
	path = normalize_dir_path(path)
	if path == "" then
		return false, "数据目录不能为空"
	end
	if not path:match("^/") then
		return false, "数据目录必须是绝对路径"
	end
	if path == "/" then
		return false, "数据目录不能使用 / 根目录"
	end
	if path == "/root" or path:match("^/root/") then
		return false, "数据目录不能使用 /root 开头的目录"
	end
	return true, nil, path
end

local function split_dots(v)
	local parts = {}
	for part in tostring(v or ""):gmatch("[^%.]+") do
		parts[#parts + 1] = part
	end
	return parts
end

local function semver_compare(a, b)
	a = trim(a):gsub("^v", "")
	b = trim(b):gsub("^v", "")
	if a == "" or b == "" then
		return nil
	end

	local a_core, a_pre = a:match("^([^%-]+)%-?(.*)$")
	local b_core, b_pre = b:match("^([^%-]+)%-?(.*)$")
	local a_nums = split_dots(a_core)
	local b_nums = split_dots(b_core)
	local max_len = math.max(#a_nums, #b_nums)

	for i = 1, max_len do
		local av = tonumber(a_nums[i] or "0") or 0
		local bv = tonumber(b_nums[i] or "0") or 0
		if av ~= bv then
			return av > bv and 1 or -1
		end
	end

	a_pre = trim(a_pre)
	b_pre = trim(b_pre)
	if a_pre == "" and b_pre == "" then
		return 0
	end
	if a_pre == "" then
		return 1
	end
	if b_pre == "" then
		return -1
	end

	local a_ids = split_dots(a_pre)
	local b_ids = split_dots(b_pre)
	max_len = math.max(#a_ids, #b_ids)
	for i = 1, max_len do
		local ai = a_ids[i]
		local bi = b_ids[i]
		if ai == nil then return -1 end
		if bi == nil then return 1 end

		local an = tonumber(ai)
		local bn = tonumber(bi)
		if an and bn then
			if an ~= bn then
				return an > bn and 1 or -1
			end
		elseif an and not bn then
			return -1
		elseif not an and bn then
			return 1
		elseif ai ~= bi then
			return ai > bi and 1 or -1
		end
	end

	return 0
end

local function require_csrf()
	local http = require "luci.http"
	local disp = require "luci.dispatcher"

	local method = http.getenv("REQUEST_METHOD") or ""
	if method ~= "POST" then
		return true
	end

	local ctx = disp.context
	if not (ctx and ctx.authsession) then
		write_json({ ok = false, error = "auth session missing" })
		return false
	end

	local expected = ctx.token
	local header_token = http.getenv("HTTP_X_LUCI_TOKEN")
	local form_token = http.formvalue("token")
	local body = read_json_body()
	local body_token = (type(body) == "table") and body["token"] or nil
	local provided = header_token or form_token or body_token

	if expected and provided ~= expected then
		write_json({ ok = false, error = "bad csrf token" })
		return false
	end
	if not expected and (not provided or #provided == 0) then
		write_json({ ok = false, error = "csrf token missing" })
		return false
	end
	return true
end

local function get_host()
	local http = require "luci.http"
	local host = http.getenv("HTTP_HOST") or http.getenv("SERVER_NAME") or ""
	host = host:gsub(":%d+$", "")
	if host == "_redirect2ssl" or host == "redirect2ssl" or host == "" then
		host = http.getenv("SERVER_ADDR") or "localhost"
	end
	return host
end

local function security_config_path(base_dir)
	base_dir = trim(base_dir)
	if base_dir == "" then
		return ""
	end
	return base_dir .. "/data/.openclawmgr/openclawmgr-security.json"
end

local function load_security_config(base_dir)
	local data = read_json_file(security_config_path(base_dir))
	if type(data) ~= "table" or type(data.items) ~= "table" then
		return { items = {} }
	end
	return data
end

local function save_security_config(base_dir, data)
	local jsonc = require "luci.jsonc"
	local sys = require "luci.sys"
	local util = require "luci.util"
	local path = security_config_path(base_dir)
	local dir = base_dir .. "/data/.openclawmgr"
	local tmp = path .. ".tmp"
	local f

	if trim(path) == "" then
		return false
	end
	sys.call("mkdir -p " .. util.shellquote(dir) .. " >/dev/null 2>&1")
	f = io.open(tmp, "w")
	if not f then
		return false
	end
	f:write(jsonc.stringify(data) or "{\"items\":[]}")
	f:close()
	if not os.rename(tmp, path) then
		os.remove(tmp)
		return false
	end
	return true
end

local function security_stat(path)
	local sys = require "luci.sys"
	local util = require "luci.util"
	local raw = sys.exec("stat -c '%u:%g:%a' " .. util.shellquote(path) .. " 2>/dev/null"):gsub("%s+$", "")
	local uid, gid, mode = raw:match("^(%d+):(%d+):(%d+)$")
	if not uid then
		return nil
	end
	return {
		uid = tonumber(uid),
		gid = tonumber(gid),
		mode = mode,
	}
end

local function security_path_exists(path)
	local sys = require "luci.sys"
	local util = require "luci.util"
	return sys.call("[ -e " .. util.shellquote(path) .. " ] >/dev/null 2>&1") == 0
end

local function security_path_is_dir(path)
	local sys = require "luci.sys"
	local util = require "luci.util"
	return sys.call("[ -d " .. util.shellquote(path) .. " ] >/dev/null 2>&1") == 0
end

local function security_probe(path)
	local sys = require "luci.sys"
	local util = require "luci.util"
	local raw = sys.exec("stat -Lc '%F|%u|%g|%a' " .. util.shellquote(path) .. " 2>/dev/null"):gsub("%s+$", "")
	local kind, uid, gid, mode = raw:match("^(.-)|(%d+)|(%d+)|(%d+)$")
	if kind then
		return {
			kind = kind,
			uid = tonumber(uid),
			gid = tonumber(gid),
			mode = mode,
		}
	end
	if security_path_is_dir(path) then
		return { kind = "directory" }
	end
	if security_path_exists(path) then
		return { kind = "other" }
	end
	return nil
end

local function security_apply(path)
	local sys = require "luci.sys"
	local util = require "luci.util"
	local quoted = util.shellquote(path)
	if sys.call("chown root:root " .. quoted .. " >/dev/null 2>&1") ~= 0 then
		return false, "chown failed"
	end
	if sys.call("chmod 0750 " .. quoted .. " >/dev/null 2>&1") ~= 0 then
		return false, "chmod failed"
	end
	return true
end

local function security_restore(path, uid, gid, mode)
	local sys = require "luci.sys"
	local util = require "luci.util"
	local quoted = util.shellquote(path)
	if sys.call("chown " .. tostring(uid) .. ":" .. tostring(gid) .. " " .. quoted .. " >/dev/null 2>&1") ~= 0 then
		return false, "restore chown failed"
	end
	if sys.call("chmod " .. tostring(mode) .. " " .. quoted .. " >/dev/null 2>&1") ~= 0 then
		return false, "restore chmod failed"
	end
	return true
end

local function security_protection_mode()
	return "仅允许 root 和 root 组访问"
end

local function security_check_item(item)
	if security_path_is_dir(item.path) then
		local st = security_stat(item.path)
		if not st then
			return {
				id = tostring(item.id or ""),
				path = tostring(item.path or ""),
				protectionMode = security_protection_mode(),
				status = "check-failed",
				checkResult = "检测失败",
			}
		end
		if st.uid == 0 and st.gid == 0 and (st.mode == "750" or st.mode == "0750") then
			return {
				id = tostring(item.id or ""),
				path = tostring(item.path or ""),
				protectionMode = security_protection_mode(),
				status = "active",
				checkResult = "openclawmgr 无法进入该目录",
			}
		end
		return {
			id = tostring(item.id or ""),
			path = tostring(item.path or ""),
			protectionMode = security_protection_mode(),
			status = "inactive",
			checkResult = "目录权限与预期不一致",
		}
	end
	if not security_path_exists(item.path) then
		return {
			id = tostring(item.id or ""),
			path = tostring(item.path or ""),
			protectionMode = security_protection_mode(),
			status = "not-found",
			checkResult = "目录不存在",
		}
	end
	return {
		id = tostring(item.id or ""),
		path = tostring(item.path or ""),
		protectionMode = security_protection_mode(),
		status = "check-failed",
		checkResult = "目标不是目录",
	}
end

local function validate_security_path(path, base_dir, items)
	path = trim(path)
	base_dir = trim(base_dir)
	if path == "" then
		return false, "请输入目录路径"
	end
	if not path:match("^/") then
		return false, "请输入绝对路径"
	end
	if path == "/" then
		return false, "不能添加根目录 /"
	end
	for _, item in ipairs(items or {}) do
		if tostring(item.path or "") == path then
			return false, "该目录已在列表中"
		end
	end
	if base_dir ~= "" then
		local esc_base = base_dir:gsub("([^%w])", "%%%1")
		local esc_path = path:gsub("([^%w])", "%%%1")
		if path == base_dir or path:match("^" .. esc_base .. "/") then
			return false, "不能添加 OpenClaw 的运行目录"
		end
		if base_dir:match("^" .. esc_path .. "/") then
			return false, "不能添加 OpenClaw 运行目录的父目录"
		end
	end
	return true
end

local function find_security_item(items, id)
	for index, item in ipairs(items or {}) do
		if tostring(item.id or "") == tostring(id or "") then
			return item, index
		end
	end
	return nil, nil
end

function action_logs()
	local http = require "luci.http"
	local sys = require "luci.sys"
	local fs = require "nixio.fs"
	local util = require "luci.util"

	local limit = safe_int(http.formvalue("limit"), 200, 50, 2000)
	local kind = (http.formvalue("kind") or "openclaw"):lower()

	local cmd = ""
	if kind == "tasks" then
		local f = "/var/log/tasks/openclawmgr.log"
		if fs.access(f) then
			cmd = "tail -n " .. limit .. " " .. util.shellquote(f) .. " 2>/dev/null"
		else
			cmd = "echo '(task log not found: " .. f .. ")'"
		end
	elseif kind == "openclawmgr" then
		cmd = "logread 2>/dev/null | grep -i openclawmgr | tail -n " .. limit
	elseif kind == "all" then
		cmd = "logread 2>/dev/null | tail -n " .. limit
	else
		-- default: openclaw gateway logs
		cmd = "logread 2>/dev/null | grep -i openclaw | tail -n " .. limit
	end

	local log = sys.exec(cmd) or ""
	write_json({ ok = true, kind = kind, limit = limit, server_time = os.time(), log = log })
end

local function configured_base_path(base_dir)
	local jsonc = require "luci.jsonc"
	if type(base_dir) ~= "string" or base_dir == "" then
		return "/"
	end
	local path = base_dir .. "/data/.openclaw/openclaw.json"
	local f = io.open(path, "r")
	if not f then
		return "/"
	end

	local raw = f:read("*a") or ""
	f:close()

	local obj = jsonc.parse(raw)
	local base_path = obj
		and obj.gateway
		and obj.gateway.controlUi
		and obj.gateway.controlUi.basePath
	if type(base_path) ~= "string" or base_path == "" or base_path == "/" then
		return "/"
	end
	if base_path:sub(1, 1) ~= "/" then
		base_path = "/" .. base_path
	end
	return base_path:gsub("/+$", "") .. "/"
end

local function fmt_elapsed(seconds)
	seconds = tonumber(seconds) or 0
	if seconds < 60 then
		return string.format("%ds", seconds)
	elseif seconds < 3600 then
		return string.format("%dm%02ds", math.floor(seconds / 60), seconds % 60)
	elseif seconds < 86400 then
		return string.format("%dh%02dm", math.floor(seconds / 3600), math.floor((seconds % 3600) / 60))
	end
	return string.format("%dd%02dh", math.floor(seconds / 86400), math.floor((seconds % 86400) / 3600))
end

local function get_running_pid()
	local sys = require "luci.sys"
	local jsonc = require "luci.jsonc"
	local raw = sys.exec("ubus call service list '{\"name\":\"openclawmgr\"}' 2>/dev/null")
	local obj = jsonc.parse(raw) or {}
	local svc = obj.openclawmgr
	if type(svc) ~= "table" or type(svc.instances) ~= "table" then
		return ""
	end
	local inst = svc.instances.gateway
	if type(inst) == "table" and inst.pid then
		return tostring(inst.pid)
	end
	return ""
end

local function installer_lock_pid()
	local f = io.open("/tmp/openclawmgr-installer.lock/pid", "r")
	if not f then
		return ""
	end
	local pid = (f:read("*l") or ""):gsub("%s+$", "")
	f:close()
	return pid
end

local function installer_lock_running()
	local sys = require "luci.sys"
	local pid = installer_lock_pid()
	if pid ~= "" and sys.call("kill -0 " .. pid .. " >/dev/null 2>&1") == 0 then
		local f = io.open("/proc/" .. pid .. "/cmdline", "r")
		local cmdline = ""
		if f then
			cmdline = (f:read("*a") or ""):gsub("%z", " ")
			f:close()
		end
		if cmdline:match("openclawmgr%.sh") and (cmdline:match("%f[%w_]install%f[^%w_]") or cmdline:match("%f[%w_]upgrade%f[^%w_]") or cmdline:match("%f[%w_]rollback_previous%f[^%w_]")) then
			return true, pid
		end
	end
	return false, pid
end

local function get_pid_uptime_human(pid)
	if not pid or pid == "" then
		return ""
	end
	local f = io.open("/proc/" .. pid .. "/stat", "r")
	if not f then
		return ""
	end
	local stat_line = f:read("*l") or ""
	f:close()

	local uf = io.open("/proc/uptime", "r")
	if not uf then
		return ""
	end
	local uptime_line = uf:read("*l") or ""
	uf:close()

	local after = stat_line:match("%) (.+)$")
	if not after then
		return ""
	end
	local fields = {}
	for part in after:gmatch("%S+") do
		fields[#fields + 1] = part
	end
	local start_ticks = tonumber(fields[20] or "")
	local system_uptime = tonumber((uptime_line:match("^(%S+)"))) or 0
	if not start_ticks or system_uptime <= 0 then
		return ""
	end

	local ticks_per_sec = 100
	local elapsed = math.floor(system_uptime - (start_ticks / ticks_per_sec))
	if elapsed < 0 then
		elapsed = 0
	end
	return fmt_elapsed(elapsed)
end

local function probe_gateway_ready(port, base_dir, bind)
	local sys = require "luci.sys"
	local util = require "luci.util"

	if not port or not tostring(port):match("^%d+$") then
		return false, "", ""
	end
	if not base_dir or base_dir == "" then
		return false, "", ""
	end

	local base_path = configured_base_path(base_dir)
	local candidates = {}

	if bind == "lan" or bind == "auto" then
		local ip = lan_ipv4()
		if ip ~= "" then
			candidates[#candidates + 1] = ip
		end
	end
	candidates[#candidates + 1] = "127.0.0.1"

	local last_code, last_url = "", ""
	for _, host in ipairs(candidates) do
		local url = "http://" .. host .. ":" .. port .. base_path
		last_url = url
		local cmd = string.format(
			"curl -fsS -o /dev/null --connect-timeout 1 --max-time 2 -w '%%{http_code}' %s 2>/dev/null",
			util.shellquote(url)
		)
		local code = sys.exec(cmd):gsub("%s+$", "")
		last_code = code
		local n = tonumber(code) or 0
		if n >= 200 and n < 400 then
			return true, code, url
		end
	end
	return false, last_code, last_url
end

function action_status()
	local sys = require "luci.sys"
	local uci = require "luci.model.uci".cursor()
	local task = get_task_state("openclawmgr")

	local enabled = uci:get("openclawmgr", "main", "enabled") or "0"
	local base_dir = uci:get("openclawmgr", "main", "base_dir") or ""
	local runtime_gateway = get_runtime_gateway_config(base_dir, {
		port = uci:get("openclawmgr", "main", "port") or "18789",
		bind = uci:get("openclawmgr", "main", "bind") or "lan",
		token = uci:get("openclawmgr", "main", "token") or "",
	})
	local port = runtime_gateway.port
	local bind = runtime_gateway.bind
	local token = runtime_gateway.token

	if not port:match("^%d+$") then port = "18789" end

	local running = false
	local installed = false
	local runtime_missing = false
	if base_dir ~= "" then
		local st = sys.exec("/usr/libexec/istorec/openclawmgr.sh status 2>/dev/null"):gsub("%s+$", "")
		running = (st == "running")
		runtime_missing = (st == "runtime-missing")
		installed = (st == "running" or st == "stopped" or runtime_missing)
		if runtime_missing then running = get_running_pid() ~= "" end
	end

	local reachable, reachable_code, reachable_url = false, "", ""
	if installed and not running then
		reachable, reachable_code, reachable_url = probe_gateway_ready(port, base_dir, bind)
	end
	local lock_running, lock_pid = installer_lock_running()
	local installing = (task.running and (task.op == "install" or task.op == "upgrade" or task.op == "rollback_previous")) or lock_running
	if not installing and task.running and not installed and not running then
		installing = true
	end

	local node_ver = ""
	local oc_ver = ""
	local target_oc_ver = ""
	local rollback_ver = ""
	local runtime_info
	local runtime_preparation
	local last_operation
	if base_dir ~= "" then
		node_ver = sys.exec("/usr/libexec/istorec/openclawmgr.sh node_version 2>/dev/null"):gsub("%s+$", "")
		oc_ver = sys.exec("/usr/libexec/istorec/openclawmgr.sh openclaw_version 2>/dev/null"):gsub("%s+$", "")
		-- Describe only a validated app-owned binding. A version string alone
		-- cannot distinguish a musl executable from a private glibc runtime.
		local raw = sys.exec("/usr/bin/lua /usr/share/openclawmgr/shared-runtime.lua describe " .. require("luci.util").shellquote(base_dir .. "/current/runtime.json") .. " 2>/dev/null")
		runtime_info = require("luci.jsonc").parse(raw)
		local prep_raw = require("nixio.fs").readfile(base_dir .. "/log/runtime-prepare/status.json")
		local prep = prep_raw and require("luci.jsonc").parse(prep_raw)
		if type(prep) == "table" and prep.storage_root == uci:get("mise", "main", "storage_root") then
			runtime_preparation = { status = prep.status, error = prep.error }
		end
		local operation_raw = sys.exec("/usr/libexec/istorec/openclawmgr.sh last_operation 2>/dev/null")
		local operation = require("luci.jsonc").parse(operation_raw)
		if type(operation) == "table" then
			last_operation = operation
		end
	end
	target_oc_ver = sys.exec("/usr/libexec/istorec/openclawmgr.sh latest_openclaw_version 2>/dev/null"):gsub("%s+$", "")
	if installed then
		rollback_ver = sys.exec("/usr/libexec/istorec/openclawmgr.sh rollback_previous_version 2>/dev/null"):gsub("%s+$", "")
	end
	local pid = running and get_running_pid() or ""
	if pid == "" and installing and lock_pid ~= "" then
		pid = lock_pid
	end
	local uptime_human = running and get_pid_uptime_human(pid) or ""

	local base_url = ""
	if base_dir ~= "" then
		base_url = "http://" .. get_host() .. ":" .. port .. configured_base_path(base_dir)
	end
	local token_url = base_url
	if token ~= "" then
		token_url = token_url .. "#token=" .. token
	end

	write_json({
		ok = true,
		enabled = enabled,
		installed = installed,
		runtime_missing = runtime_missing,
		running = running,
		reachable = reachable,
		reachable_http_code = reachable_code,
		reachable_url = reachable_url,
		task_running = task.running,
		task_op = task.op,
		installing = installing,
		port = port,
		bind = bind,
		base_dir = base_dir,
		token = token,
		node_version = node_ver,
		runtime_info = runtime_info,
		runtime_preparation = runtime_preparation,
		openclaw_version = oc_ver,
		target_openclaw_version = target_oc_ver,
		rollback_available = rollback_ver ~= "",
		rollback_version = rollback_ver,
		last_operation = last_operation,
		pid = pid,
		uptime_human = uptime_human,
		base_url = base_url,
		token_url = token_url,
		url = token_url,
	})
end

function action_ready()
	local uci = require "luci.model.uci".cursor()

	local base_dir = uci:get("openclawmgr", "main", "base_dir") or ""
	local runtime_gateway = get_runtime_gateway_config(base_dir, {
		port = uci:get("openclawmgr", "main", "port") or "18789",
		bind = uci:get("openclawmgr", "main", "bind") or "lan",
	})
	local port = runtime_gateway.port
	local bind = runtime_gateway.bind

	if base_dir == "" then
		write_json({ ok = true, ready = false, reason = "base_dir missing" })
		return
	end

	local ready, code, url = probe_gateway_ready(port, base_dir, bind)

	write_json({
		ok = true,
		ready = ready,
		http_code = code,
		url = url,
	})
end

function action_check_update()
	local sys = require "luci.sys"
	local http = require "luci.http"
	local util = require "luci.util"
	local uci = require "luci.model.uci".cursor()
	local install_channel = http.formvalue("install_channel") or ""
	if install_channel ~= "" and install_channel ~= "stable" and install_channel ~= "compat" and install_channel ~= "latest" then
		write_json({ ok = false, error = "invalid install_channel" })
		return
	end

	if not require_csrf() then
		return
	end

	local base_dir = uci:get("openclawmgr", "main", "base_dir") or ""
	if trim(base_dir) == "" then
		write_json({ ok = false, error = "请先配置数据目录" })
		return
	end

	local st = trim(sys.exec("/usr/libexec/istorec/openclawmgr.sh status 2>/dev/null"))
	local installed = (st == "running" or st == "stopped" or st == "runtime-missing")
	if st == "runtime-missing" then
		write_json({ ok = false, error = "固定运行时缺失，请在运行时环境恢复对应实例，或执行升级重新准备。", installed = true, runtime_missing = true })
		return
	end
	if not installed then
		write_json({ ok = false, error = "OpenClaw 尚未安装", installed = false })
		return
	end

	local local_ver = trim(sys.exec("/usr/libexec/istorec/openclawmgr.sh local_openclaw_version 2>/dev/null"))
	if local_ver == "" then
		local_ver = trim(sys.exec("/usr/libexec/istorec/openclawmgr.sh openclaw_version 2>/dev/null"))
	end
	if local_ver == "" then
		write_json({ ok = false, error = "获取本地版本失败", installed = true })
		return
	end

	local remote_channel = install_channel ~= "" and install_channel or "latest"
	local remote_cmd = "INSTALL_CHANNEL=" .. util.shellquote(remote_channel) .. " /usr/libexec/istorec/openclawmgr.sh latest_openclaw_version 2>/dev/null"
	local remote_ver = trim(sys.exec(remote_cmd))
	if remote_ver == "" then
		write_json({ ok = false, error = "获取远程版本失败", installed = true, local_version = local_ver })
		return
	end

	local cmp = semver_compare(remote_ver, local_ver)
	local has_update = false
	if cmp == nil then
		has_update = remote_ver ~= local_ver
	else
		has_update = cmp > 0
	end

	write_json({
		ok = true,
		installed = true,
		local_version = local_ver,
		remote_version = remote_ver,
		has_update = has_update,
	})
end

function action_apply_config()
	local sys = require "luci.sys"

	if not require_csrf() then
		return
	end

	local rc = sys.call("/usr/libexec/istorec/openclawmgr.sh apply_config >/dev/null 2>&1")
	if rc ~= 0 then
		write_json({ ok = false, error = "apply config failed" })
		return
	end

	write_json({
		ok = true,
		applied_at = os.date("%Y-%m-%d %H:%M:%S"),
	})
end

function action_config_data()
	local http = require "luci.http"
	local jsonc = require "luci.jsonc"
	local sys = require "luci.sys"
	local util = require "luci.util"
	local uci = require "luci.model.uci".cursor()
	local model = require "luci.model.openclawmgr"

	local function write_json_file(path, obj)
		local dir = path:match("^(.+)/[^/]+$")
		if dir and dir ~= "" then
			sys.call("mkdir -p " .. util.shellquote(dir) .. " >/dev/null 2>&1")
		end
		local encoded = jsonc.stringify(obj, true) or "{}"
		encoded = encoded:gsub("\\/", "/")
		local f = io.open(path, "w")
		if not f then
			return false
		end
		f:write(encoded)
		f:write("\n")
		f:close()
		return true
	end

	local function config_path(base_dir)
		return openclaw_config_path(base_dir)
	end

	local function ensure_table(parent, key)
		if type(parent[key]) ~= "table" then
			parent[key] = {}
		end
		return parent[key]
	end

	local infer_custom_provider_model
	local display_model_name

	local function env_key_for_agent(agent)
		if agent == "openai" then return "OPENAI_API_KEY" end
		if agent == "anthropic" then return "ANTHROPIC_API_KEY" end
		if agent == "minimax-cn" then return "MINIMAX_API_KEY" end
		if agent == "moonshot" then return "MOONSHOT_API_KEY" end
		return ""
	end

	local function default_model_for_agent(agent, current_custom_model)
		if agent == "openai" then return "gpt-5.2" end
		if agent == "anthropic" then return "claude-sonnet-4-6" end
		if agent == "minimax-cn" then return "MiniMax-M2.5" end
		if agent == "moonshot" then return "kimi-k2.5" end
		if agent == "custom-provider" then return trim(current_custom_model) ~= "" and trim(current_custom_model) or "custom-model" end
		return "claude-sonnet-4-6"
	end

	local function normalized_model_path(agent, value, current_custom_model)
		local model_name = display_model_name(value)
		if model_name == "" then
			model_name = default_model_for_agent(agent, current_custom_model)
		end
		return agent .. "/" .. model_name
	end

	local function infer_agent_from_cfg(cfg)
		local primary = cfg.agents and cfg.agents.defaults and cfg.agents.defaults.model and cfg.agents.defaults.model.primary
		if type(primary) == "string" and primary:match("^[^/]+/.+") then
			return primary:match("^([^/]+)/") or ""
		end
		local providers = cfg.models and cfg.models.providers
		if type(providers) == "table" then
			for _, agent in ipairs({ "openai", "anthropic", "minimax-cn", "moonshot", "custom-provider" }) do
				if type(providers[agent]) == "table" then
					return agent
				end
			end
		end
		return ""
	end

	local function get_runtime_config(base_dir)
		local cfg = read_json_file(config_path(base_dir)) or {}
		local gateway_cfg = get_runtime_gateway_config(base_dir, {
			port = uci:get("openclawmgr", "main", "port") or "18789",
			bind = uci:get("openclawmgr", "main", "bind") or "lan",
			token = uci:get("openclawmgr", "main", "token") or "",
		})
		local gateway = cfg.gateway or {}
		local control = gateway.controlUi or {}
		local auth = gateway.auth or {}
		local primary = cfg.agents and cfg.agents.defaults and cfg.agents.defaults.model and cfg.agents.defaults.model.primary
		local agent = infer_agent_from_cfg(cfg)
		if agent == "" then
			agent = uci:get("openclawmgr", "main", "default_agent") or "anthropic"
		end

		local default_model = ""
		if type(primary) == "string" and primary ~= "" then
			default_model = display_model_name(primary)
		elseif agent == "custom-provider" then
			default_model = infer_custom_provider_model(base_dir)
		else
			default_model = display_model_name(uci:get("openclawmgr", "main", "default_model") or "")
		end

		local provider = cfg.models and cfg.models.providers and cfg.models.providers[agent] or {}
		local env = cfg.env or {}
		local provider_api_key = ""
		local env_key = env_key_for_agent(agent)
		if env_key ~= "" and type(env[env_key]) == "string" then
			provider_api_key = env[env_key]
		elseif type(provider.apiKey) == "string" then
			provider_api_key = provider.apiKey
		else
			provider_api_key = uci:get("openclawmgr", "main", "provider_api_key") or ""
		end

		local allowed_origins = {}
		if type(control.allowedOrigins) == "table" then
			for _, item in ipairs(control.allowedOrigins) do
				item = trim(item)
				if item ~= "" then
					allowed_origins[#allowed_origins + 1] = item
				end
			end
		elseif #allowed_origins == 0 then
			for _, item in ipairs(uci:get_list("openclawmgr", "main", "allowed_origins") or {}) do
				item = trim(item)
				if item ~= "" then
					allowed_origins[#allowed_origins + 1] = item
				end
			end
		end

		local allow_insecure_auth = control.allowInsecureAuth
		if type(allow_insecure_auth) ~= "boolean" then
			allow_insecure_auth = (uci:get("openclawmgr", "main", "allow_insecure_auth") or "1") == "1"
		end

		local disable_device_auth = control.dangerouslyDisableDeviceAuth
		if type(disable_device_auth) ~= "boolean" then
			disable_device_auth = (uci:get("openclawmgr", "main", "disable_device_auth") or "1") == "1"
		end

		local provider_base_url = ""
		if type(provider.baseUrl) == "string" then
			provider_base_url = provider.baseUrl
		else
			provider_base_url = uci:get("openclawmgr", "main", "provider_base_url") or ""
		end

		return {
			port = gateway_cfg.port,
			bind = gateway_cfg.bind,
			token = gateway_cfg.token,
			allowed_origins = allowed_origins,
			allow_insecure_auth = allow_insecure_auth,
			disable_device_auth = disable_device_auth,
			default_agent = agent,
			default_model = default_model,
			provider_api_key = provider_api_key,
			provider_base_url = provider_base_url,
		}
	end

	local function write_runtime_config(base_dir, service_cfg, runtime_cfg)
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

		local path = config_path(base_dir)
		if path == "" then
			return false
		end
		local cfg = read_json_file(path) or {}
		local gateway = ensure_table(cfg, "gateway")
		gateway.mode = "local"
		gateway.port = tonumber(service_cfg.port) or 18789
		gateway.bind = service_cfg.bind or "lan"
		local auth = ensure_table(gateway, "auth")
		auth.mode = "token"
		auth.token = runtime_cfg.token or ""
		local control = ensure_table(gateway, "controlUi")
		control.enabled = true
		control.allowedOrigins = runtime_cfg.allowed_origins or {}
		control.allowInsecureAuth = runtime_cfg.allow_insecure_auth == true
		control.dangerouslyDisableDeviceAuth = runtime_cfg.disable_device_auth == true
		control.dangerouslyAllowHostHeaderOriginFallback = service_cfg.bind ~= "loopback"

		local env = type(cfg.env) == "table" and cfg.env or {}
		for _, key in ipairs({ "OPENAI_API_KEY", "ANTHROPIC_API_KEY", "MINIMAX_API_KEY", "MOONSHOT_API_KEY" }) do
			env[key] = nil
		end
		local env_key = env_key_for_agent(runtime_cfg.default_agent)
		if env_key ~= "" and trim(runtime_cfg.provider_api_key) ~= "" then
			env[env_key] = runtime_cfg.provider_api_key
		end
		cfg.env = next(env) and env or nil

		local models = ensure_table(cfg, "models")
		if type(models.mode) ~= "string" or models.mode == "" then
			models.mode = "merge"
		end
		local providers = {}
		models.providers = providers
		local provider = {}
		providers[runtime_cfg.default_agent] = provider
		local model_name = display_model_name(runtime_cfg.default_model)
		if model_name == "" then
			model_name = default_model_for_agent(runtime_cfg.default_agent, infer_custom_provider_model(base_dir))
		end
		if runtime_cfg.default_agent == "openai" then
			provider.api = "openai-completions"
			provider.baseUrl = trim(runtime_cfg.provider_base_url) ~= "" and runtime_cfg.provider_base_url or "https://api.openai.com/v1"
			provider.apiKey = trim(runtime_cfg.provider_api_key) ~= "" and runtime_cfg.provider_api_key or nil
			provider.authHeader = nil
		elseif runtime_cfg.default_agent == "anthropic" then
			provider.api = "anthropic-messages"
			provider.baseUrl = trim(runtime_cfg.provider_base_url) ~= "" and runtime_cfg.provider_base_url or "https://api.anthropic.com"
			provider.apiKey = trim(runtime_cfg.provider_api_key) ~= "" and runtime_cfg.provider_api_key or nil
			provider.authHeader = nil
		elseif runtime_cfg.default_agent == "minimax-cn" then
			provider.api = "anthropic-messages"
			provider.baseUrl = trim(runtime_cfg.provider_base_url) ~= "" and runtime_cfg.provider_base_url or "https://api.minimaxi.com/anthropic"
			provider.apiKey = trim(runtime_cfg.provider_api_key) ~= "" and runtime_cfg.provider_api_key or nil
			provider.authHeader = true
		elseif runtime_cfg.default_agent == "moonshot" then
			provider.api = "openai-completions"
			provider.baseUrl = trim(runtime_cfg.provider_base_url) ~= "" and runtime_cfg.provider_base_url or "https://api.moonshot.cn/v1"
			provider.apiKey = trim(runtime_cfg.provider_api_key) ~= "" and runtime_cfg.provider_api_key or nil
			provider.authHeader = nil
		else
			provider.api = "openai-completions"
			provider.baseUrl = runtime_cfg.provider_base_url or ""
			provider.apiKey = trim(runtime_cfg.provider_api_key) ~= "" and runtime_cfg.provider_api_key or nil
			provider.authHeader = nil
		end
		provider.models = {
			{ id = model_name, name = model_name }
		}

		local agents = ensure_table(cfg, "agents")
		local defaults = ensure_table(agents, "defaults")
		local model_cfg = ensure_table(defaults, "model")
		model_cfg.primary = normalized_model_path(runtime_cfg.default_agent, model_name, infer_custom_provider_model(base_dir))

		prune_empty_tables(cfg)

		return write_json_file(path, cfg)
	end

	infer_custom_provider_model = function(base_dir)
		base_dir = tostring(base_dir or "")
		if base_dir == "" then return "" end
		local cfg = read_json_file(base_dir .. "/data/.openclaw/openclaw.json") or {}
		local primary = cfg.agents and cfg.agents.defaults and cfg.agents.defaults.model and cfg.agents.defaults.model.primary
		if type(primary) == "string" and primary:match("^custom%-provider/.+") then
			return primary:gsub("^[^/]+/", "")
		end
		local providers = cfg.models and cfg.models.providers
		local custom = providers and providers["custom-provider"]
		local models = custom and custom.models
		local first = type(models) == "table" and models[1] or nil
		local id = first and first.id
		if type(id) == "string" and id ~= "" then
			return id
		end
		return ""
	end

	display_model_name = function(value)
		value = tostring(value or "")
		if value == "" then
			return ""
		end
		return value:gsub("^[^/]+/", "")
	end

	if (http.getenv("REQUEST_METHOD") or "GET") == "POST" then
		if not require_csrf() then
			return
		end

	local body = read_json_body() or {}
	local section = "main"

		local function bool_to_uci(value)
			return value and "1" or "0"
		end

		local function has(key)
			return body[key] ~= nil
		end

		local current = get_runtime_config(uci:get("openclawmgr", section, "base_dir") or "")
		local requested_default_agent = tostring(has("default_agent") and body.default_agent or current.default_agent or "anthropic")

		if has("enabled") then
			uci:set("openclawmgr", section, "enabled", bool_to_uci(body.enabled == true or body.enabled == "1"))
		end

		if has("port") then
			local port = tostring(body.port or "")
			if not port:match("^%d+$") then
				write_json({ ok = false, error = "invalid port" })
				return
			end
			local port_num = tonumber(port) or 0
			if port_num < 1025 or port_num > 65535 then
				write_json({ ok = false, error = "invalid port (must be 1025-65535)" })
				return
			end
		end

		if has("bind") then
			local bind = tostring(body.bind or "")
			if bind ~= "loopback" and bind ~= "lan" and bind ~= "auto" and bind ~= "tailnet" and bind ~= "custom" then
				write_json({ ok = false, error = "invalid bind" })
				return
			end
		end

		if has("base_dir") then
			local ok, err, normalized = validate_base_dir_input(body.base_dir or "")
			if not ok then
				write_json({ ok = false, error = err })
				return
			end
			body.base_dir = normalized
			local base_dir = normalized
			uci:set("openclawmgr", section, "base_dir", base_dir)
		end

		if has("default_agent") then
			local agent = tostring(body.default_agent or "")
			if agent ~= "openai" and agent ~= "anthropic" and agent ~= "minimax-cn" and agent ~= "moonshot" and agent ~= "custom-provider" then
				write_json({ ok = false, error = "invalid default_agent" })
				return
			end
		end

		if has("install_accelerated") then
			uci:set("openclawmgr", section, "install_accelerated", bool_to_uci(body.install_accelerated == true or body.install_accelerated == "1"))
		end

		if has("provider_base_url") then
			local value = tostring(body.provider_base_url or "")
			if requested_default_agent == "custom-provider" and value == "" then
				write_json({ ok = false, error = "provider_base_url required for custom-provider" })
				return
			end
			if value ~= "" and not value:match("^https?://") then
				write_json({ ok = false, error = "invalid provider_base_url" })
				return
			end
		end

		if has("token") then
			body.token = tostring(body.token or "")
		end

		local effective_base_dir = tostring(has("base_dir") and body.base_dir or (uci:get("openclawmgr", section, "base_dir") or ""))
		local effective_port = tostring(has("port") and body.port or current.port or "18789")
		local effective_bind = tostring(has("bind") and body.bind or current.bind or "lan")
		local runtime_cfg = {
			token = tostring(has("token") and body.token or current.token or ""),
			allowed_origins = current.allowed_origins,
			allow_insecure_auth = current.allow_insecure_auth,
			disable_device_auth = current.disable_device_auth,
			default_agent = requested_default_agent,
			default_model = tostring(has("default_model") and body.default_model or current.default_model or ""),
			provider_api_key = tostring(has("provider_api_key") and body.provider_api_key or current.provider_api_key or ""),
			provider_base_url = tostring(has("provider_base_url") and body.provider_base_url or current.provider_base_url or ""),
		}

		if has("allowed_origins") then
			local origins = {}
			if type(body.allowed_origins) == "table" then
				for _, item in ipairs(body.allowed_origins) do
					item = trim(item)
					if item ~= "" then
						origins[#origins + 1] = item
					end
				end
			end
			runtime_cfg.allowed_origins = origins
		end

		if has("allow_insecure_auth") then
			runtime_cfg.allow_insecure_auth = (body.allow_insecure_auth == true or body.allow_insecure_auth == "1")
		end

		if has("disable_device_auth") then
			runtime_cfg.disable_device_auth = (body.disable_device_auth == true or body.disable_device_auth == "1")
		end

		if runtime_cfg.default_agent == "custom-provider" and trim(runtime_cfg.provider_base_url) == "" then
			write_json({ ok = false, error = "provider_base_url required for custom-provider" })
			return
		end
		if trim(runtime_cfg.provider_base_url) ~= "" and not tostring(runtime_cfg.provider_base_url):match("^https?://") then
			write_json({ ok = false, error = "invalid provider_base_url" })
			return
		end

		uci:commit("openclawmgr")
		if effective_base_dir == "" then
			write_json({ ok = false, error = "base_dir required" })
			return
		end
		local ok = write_runtime_config(effective_base_dir, {
			port = effective_port,
			bind = effective_bind,
		}, runtime_cfg)
		if not ok then
			write_json({ ok = false, error = "write openclaw.json failed" })
			return
		end
		for _, key in ipairs({ "port", "bind", "token", "allowed_origins", "allow_insecure_auth", "disable_device_auth", "default_agent", "default_model", "provider_api_key", "provider_base_url" }) do
			uci:delete("openclawmgr", section, key)
		end
		uci:commit("openclawmgr")
		write_json({ ok = true })
		return
	end

	local base_dir = uci:get("openclawmgr", "main", "base_dir") or ""
	local blocks = model.blocks()
	local home = model.home()
	local paths, default_path = model.find_paths(blocks, home, "Configs")
	local choices = {}
	local seen = {}

	local function add_choice(path)
		if path and path ~= "" and not seen[path] then
			table.insert(choices, path)
			seen[path] = true
		end
	end

	if base_dir ~= "" then
		add_choice(base_dir)
	end
	for _, path in ipairs(paths or {}) do
		add_choice(path)
	end
	add_choice(default_path or "/root/Configs/OpenClawMgr")

	local runtime_cfg = get_runtime_config(base_dir)

	write_json({
		ok = true,
		config = {
			enabled = (uci:get("openclawmgr", "main", "enabled") or "0") == "1",
			port = runtime_cfg.port,
			bind = runtime_cfg.bind,
			base_dir = base_dir,
			token = runtime_cfg.token,
			allowed_origins = runtime_cfg.allowed_origins,
			allow_insecure_auth = runtime_cfg.allow_insecure_auth,
			disable_device_auth = runtime_cfg.disable_device_auth,
			default_agent = runtime_cfg.default_agent,
			default_model = runtime_cfg.default_model,
			install_accelerated = (uci:get("openclawmgr", "main", "install_accelerated") or "1") == "1",
			provider_api_key = runtime_cfg.provider_api_key,
			provider_base_url = runtime_cfg.provider_base_url,
		},
		options = {
			base_dir_choices = choices,
			suggested_base_dir = default_path or "",
			default_origin = default_allowed_origin(runtime_cfg.port),
		}
	})
end

function action_security_data()
	local uci = require "luci.model.uci".cursor()
	local base_dir = trim(uci:get("openclawmgr", "main", "base_dir") or "")
	local data, items = nil, {}
	if base_dir == "" then
		write_json({ ok = true, items = items })
		return
	end
	data = load_security_config(base_dir)
	for _, item in ipairs(data.items or {}) do
		items[#items + 1] = security_check_item(item)
	end
	write_json({ ok = true, items = items })
end

function action_security_add()
	local uci = require "luci.model.uci".cursor()
	if not require_csrf() then
		return
	end
	local base_dir = trim(uci:get("openclawmgr", "main", "base_dir") or "")
	local body = read_json_body() or {}
	local path = trim(body.path or "")
	local data, ok, err, item, st, probe = nil, nil, nil, nil, nil, nil
	if base_dir == "" then
		write_json({ ok = false, error = "base_dir required" })
		return
	end
	data = load_security_config(base_dir)
	ok, err = validate_security_path(path, base_dir, data.items)
	if not ok then
		write_json({ ok = false, error = err })
		return
	end
	item = {
		id = "dir_" .. tostring(os.time()) .. tostring(math.random(1000, 9999)),
		path = path,
		orig_uid = 0,
		orig_gid = 0,
		orig_mode = "755",
	}
	probe = security_probe(path)
	if not probe then
		write_json({ ok = false, error = "目录不存在" })
		return
	end
	if probe.kind ~= "directory" then
		write_json({ ok = false, error = "目标不是目录" })
		return
	end
	st = security_stat(path)
	if not st then
		write_json({ ok = false, error = "读取目录权限失败" })
		return
	end
	item.orig_uid = st.uid
	item.orig_gid = st.gid
	item.orig_mode = st.mode
	ok, err = security_apply(path)
	if not ok then
		write_json({ ok = false, error = err or "apply failed" })
		return
	end
	data.items[#data.items + 1] = item
	if not save_security_config(base_dir, data) then
		write_json({ ok = false, error = "save security config failed" })
		return
	end
	write_json({ ok = true, item = security_check_item(item) })
end

function action_security_remove()
	local uci = require "luci.model.uci".cursor()
	if not require_csrf() then
		return
	end
	local base_dir = trim(uci:get("openclawmgr", "main", "base_dir") or "")
	local body = read_json_body() or {}
	local id = tostring(body.id or "")
	local mode = tostring(body.mode or "direct")
	local data, item, index = nil, nil, nil
	if base_dir == "" then
		write_json({ ok = false, error = "base_dir required" })
		return
	end
	if mode ~= "direct" and mode ~= "restore" then
		write_json({ ok = false, error = "invalid mode" })
		return
	end
	data = load_security_config(base_dir)
	item, index = find_security_item(data.items, id)
	if not item then
		write_json({ ok = false, error = "item not found" })
		return
	end
	if mode == "restore" and security_path_exists(item.path) then
		local ok, err = security_restore(item.path, item.orig_uid, item.orig_gid, item.orig_mode)
		if not ok then
			write_json({ ok = false, error = err or "restore failed" })
			return
		end
	end
	table.remove(data.items, index)
	if not save_security_config(base_dir, data) then
		write_json({ ok = false, error = "save security config failed" })
		return
	end
	write_json({ ok = true })
end

function action_security_recheck()
	local uci = require "luci.model.uci".cursor()
	if not require_csrf() then
		return
	end
	local base_dir = trim(uci:get("openclawmgr", "main", "base_dir") or "")
	local body = read_json_body() or {}
	local id = tostring(body.id or "")
	local data, item = nil, nil
	if base_dir == "" then
		write_json({ ok = false, error = "base_dir required" })
		return
	end
	data = load_security_config(base_dir)
	item = find_security_item(data.items, id)
	if not item then
		write_json({ ok = false, error = "item not found" })
		return
	end
	write_json({ ok = true, item = security_check_item(item) })
end

function action_op()
	local http = require "luci.http"
	local i18n = require "luci.i18n"
	local sys = require "luci.sys"
	local util = require "luci.util"
	local fs = require "nixio.fs"
	local tasks = nil
	do
		local ok, mod = pcall(require, "luci.model.tasks")
		if ok then tasks = mod end
	end

	if not require_csrf() then
		return
	end

	local op = http.formvalue("op") or ""
	local install_channel = http.formvalue("install_channel") or ""
	local ok_ops = { install = true, upgrade = true, rollback_previous = true, start = true, stop = true, restart = true, apply_config = true, uninstall = true, uninstall_openclaw = true, purge = true, cancel_install = true }
	if not ok_ops[op] then
		write_json({ ok = false, error = "unknown op" })
		return
	end
	if install_channel ~= "" and install_channel ~= "stable" and install_channel ~= "compat" and install_channel ~= "latest" then
		write_json({ ok = false, error = "invalid install_channel" })
		return
	end

	local task_id = "openclawmgr"
	local script_path = "/usr/libexec/istorec/openclawmgr.sh"

	if op == "cancel_install" then
		if not fs.access("/etc/init.d/tasks") then
			write_json({ ok = false, error = i18n.translate("taskd is not available") })
			return
		end

		local task = get_task_state(task_id)
		local st = sys.exec("/usr/libexec/istorec/openclawmgr.sh status 2>/dev/null"):gsub("%s+$", "")
		local installed = (st == "running" or st == "stopped" or st == "runtime-missing")
		local install_like = task.running and (task.op == "install" or task.op == "upgrade" or not installed)
		if not install_like then
			write_json({ ok = false, error = i18n.translate("No install task is running") })
			return
		end

		-- The coordinator owns cancellation, child joins and rollback. task_del
		-- may kill its process group, so only delete taskd state after cleanup.
		local rc = sys.call(script_path .. " cancel_install >/dev/null 2>&1")
		if rc == 0 then
			sys.call("/etc/init.d/tasks task_del " .. task_id .. " >/dev/null 2>&1")
			write_json({ ok = true, canceled = true, task_id = task_id })
			return
		end

		write_json({ ok = false, error = i18n.translate("Failed to stop installation"), task_id = task_id, pid = task.pid })
		return
	end

	if not fs.access("/etc/init.d/tasks") then
		-- fallback (shouldn't happen on iStoreOS with luci-lib-taskd installed)
		local cmd = script_path .. " " .. util.shellquote(op)
		if install_channel ~= "" and (op == "install" or op == "upgrade") then
			cmd = "INSTALL_CHANNEL=" .. util.shellquote(install_channel) .. " " .. cmd
		end
		sys.exec("( " .. cmd .. " ) >/dev/null 2>&1 &")
		write_json({ ok = true, queued = true, task_id = task_id, warning = "taskd missing; fallback to background exec" })
		return
	end

	local cmd = string.format("\"%s\" %s", script_path, op)
	if install_channel ~= "" and (op == "install" or op == "upgrade") then
		cmd = "INSTALL_CHANNEL=" .. util.shellquote(install_channel) .. " " .. cmd
	end
	local rc = sys.call("/etc/init.d/tasks task_add " .. task_id .. " " .. util.shellquote(cmd) .. " >/dev/null 2>&1")
	if rc == 0 then
		write_json({ ok = true, task_id = task_id })
		return
	end

	-- busy: try to report which task is running
	local running_task = ""
	if tasks and tasks.status then
		local all = tasks.status("") or {}
		for id, st in pairs(all) do
			if type(st) == "table" and st.running then
				running_task = id
				break
			end
		end
	end

	write_json({ ok = false, busy = true, task_id = task_id, running_task_id = running_task })
end

local function file_read(path)
	local f = io.open(path, "r")
	if not f then return nil end
	local c = f:read("*a")
	f:close()
	return c
end

function action_diag_info()
	local sys = require "luci.sys"
	local util = require "luci.util"
	local uci = require "luci.model.uci".cursor()

	local base_dir = uci:get("openclawmgr", "main", "base_dir") or ""
	local enabled = uci:get("openclawmgr", "main", "enabled") or "0"
	local runtime_gateway = get_runtime_gateway_config(base_dir, {
		port = uci:get("openclawmgr", "main", "port") or "18789",
		bind = uci:get("openclawmgr", "main", "bind") or "lan",
	})
	local port = runtime_gateway.port
	local bind = runtime_gateway.bind

	local avail_mb = 0
	if base_dir ~= "" then
		local df_kb = sys.exec("df -kP " .. util.shellquote(base_dir) .. " 2>/dev/null | awk 'NR==2{print $4}'"):gsub("%s+", "")
		avail_mb = math.floor((tonumber(df_kb) or 0) / 1024)
	end

	local node_ver = ""
	local oc_ver = ""
	if base_dir ~= "" then
		node_ver = sys.exec("/usr/libexec/istorec/openclawmgr.sh node_version 2>/dev/null"):gsub("%s+$", "")
		oc_ver = sys.exec("/usr/libexec/istorec/openclawmgr.sh openclaw_version 2>/dev/null"):gsub("%s+$", "")
	end

	local has_node = false
	local has_openclaw = false
	local has_config = false
	if base_dir ~= "" then
		has_node = sys.call("/usr/libexec/istorec/openclawmgr.sh runtime_ready >/dev/null 2>&1") == 0
		has_openclaw = sys.call("[ -x " .. util.shellquote(base_dir .. "/global/bin/openclaw") .. " ] >/dev/null 2>&1") == 0
		has_config = sys.call("[ -f " .. util.shellquote(base_dir .. "/data/.openclaw/openclaw.json") .. " ] >/dev/null 2>&1") == 0
	end

	local default_gw = sys.exec("ip route 2>/dev/null | awk '/^default/{print $3; exit}' 2>/dev/null"):gsub("%s+", "")

	local svc = util.ubus("service", "list", { name = "openclawmgr" })
	local pid = ""
	if type(svc) == "table" and type(svc.openclawmgr) == "table" and type(svc.openclawmgr.instances) == "table" then
		local inst = svc.openclawmgr.instances.gateway
		if type(inst) == "table" and inst.pid then
			pid = tostring(inst.pid)
		end
	end
	local running = pid ~= ""

	write_json({
		ok = true,
		base_dir = base_dir,
		available_mb = avail_mb,
		enabled = enabled,
		port = port,
		bind = bind,
		default_gw = default_gw,
		node_version = node_ver,
		openclaw_version = oc_ver,
		has_node = has_node,
		has_openclaw = has_openclaw,
		has_config = has_config,
		procd_pid = pid,
		running = running,
			url = (base_dir ~= "" and ("http://" .. get_host() .. ":" .. port .. configured_base_path(base_dir)) or ""),
		})
	end

function action_diag_run()
	local http = require "luci.http"
	local sys = require "luci.sys"
	local util = require "luci.util"

	if not require_csrf() then
		return
	end

	local op = http.formvalue("op") or ""
	local limit = http.formvalue("limit") or ""
	local ok_ops = {
		doctor = true,
		gateway_status = true,
		gateway_health = true,
		logs = true,
		channels_status = true,
	}
	if not ok_ops[op] then
		write_json({ ok = false, error = "unknown op" })
		return
	end

	local cmd = "/usr/libexec/istorec/openclawmgr.sh diag " .. util.shellquote(op)
	if op == "logs" and limit:match("^%d+$") then
		cmd = cmd .. " " .. util.shellquote(limit)
	end

	sys.exec("( " .. cmd .. " ) >/dev/null 2>&1 &")
	write_json({ ok = true, queued = true })
end

function action_diag_poll()
	local http = require "luci.http"
	local sys = require "luci.sys"
	local util = require "luci.util"

	local op = http.formvalue("op") or ""
	local ok_ops = {
		doctor = true,
		gateway_status = true,
		gateway_health = true,
		logs = true,
		channels_status = true,
	}
	if not ok_ops[op] then
		write_json({ ok = false, error = "unknown op" })
		return
	end

	local st = sys.exec("/usr/libexec/istorec/openclawmgr.sh diag_poll " .. util.shellquote(op) .. " 2>/dev/null"):gsub("%s+$", "")

	local log = file_read("/tmp/openclawmgr-diag-" .. op .. ".log") or ""
	local exit_code = nil
	local state = "idle"
	if st == "running" then
		state = "running"
	elseif st:match("^done:") then
		state = "done"
		exit_code = tonumber(st:gsub("^done:", "")) or -1
	end

	write_json({
		ok = true,
		state = state,
		exit_code = exit_code,
		log = log,
	})
end
