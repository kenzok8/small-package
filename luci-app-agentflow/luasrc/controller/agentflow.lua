local http = require "luci.http"

module("luci.controller.agentflow", package.seeall)

local APPS_PROXY_PREFIX = "/apps=http://127.0.0.1:19290"
local DEFAULT_BASE_PATH = "/apps/agentflow/"
local DEFAULT_PORT = 9000
local AGENTS = {
	{ id = "codexcli", package = "@openai/codex" },
	{ id = "claude-code", package = "@anthropic-ai/claude-code" },
	{ id = "opencode", package = "opencode-ai" },
	{ id = "kimi", package = "@moonshot-ai/kimi-code" },
	{ id = "reasonix", package = "reasonix" }
}

function index()
	entry({"admin", "services", "agentflow_status"}, call("agentflow_status"))
	local open = entry({"admin", "services", "agentflow", "open"}, call("agentflow_open"))
	open.leaf = true
	open.dependent = false
	open.sysauth = false

	if not nixio.fs.access("/etc/config/agentflow") then
		return
	end

	local install = entry({"admin", "services", "agentflow", "agent_install"}, call("agentflow_agent_install"))
	install.leaf = true

	local page = entry({"admin", "services", "agentflow"}, cbi("agentflow"), _("AgentFlow"), 100)
	page.dependent = true
end

local function write_json(obj)
	http.prepare_content("application/json")
	http.write_json(obj)
end

local function require_post_csrf()
	local dispatcher = require "luci.dispatcher"
	local context = dispatcher.context or {}
	local expected = context.authtoken or context.token

	if (http.getenv("REQUEST_METHOD") or "") ~= "POST" then
		http.status(405, "Method Not Allowed")
		write_json({ ok = false, error = "method not allowed" })
		return false
	end

	if not context.authsession or not expected or http.formvalue("token") ~= expected then
		http.status(403, "Forbidden")
		write_json({ ok = false, error = "invalid csrf token" })
		return false
	end

	return true
end

local function uhttpd_has_apps_proxy_prefix()
	local uci = require "luci.model.uci".cursor()
	local mappings = uci:get_list("uhttpd", "main", "proxy_prefix") or {}

	for _, mapping in ipairs(mappings) do
		if mapping == APPS_PROXY_PREFIX then
			return true
		end
	end
	return false
end

local function uhttpd_supports_proxy_prefix()
	local sys = require "luci.sys"
	return sys.call("grep -qr 'proxy_prefix' /etc/init.d/uhttpd /lib/functions /usr/share/uhttpd 2>/dev/null") == 0
end

local function uhttpd_apps_proxy_available()
	return uhttpd_supports_proxy_prefix() and uhttpd_has_apps_proxy_prefix()
end

local function linkeasefull_running()
	local sys = require "luci.sys"
	return sys.call("[ -x /etc/init.d/linkeasefull ] && /etc/init.d/linkeasefull running >/dev/null 2>&1") == 0
end

local function normalized_base_path(path)
	path = path or DEFAULT_BASE_PATH
	if path:sub(1, 1) ~= "/" then
		path = "/" .. path
	end
	if path:sub(-1) ~= "/" then
		path = path .. "/"
	end
	return path
end

local function authority_host(authority)
	if not authority or authority == "" then
		return ""
	end
	if authority:sub(1, 1) == "[" then
		return authority:match("^%[([^%]]+)%]") or ""
	end
	return authority:match("^([^:]+)") or authority
end

local function url_authority(host, port)
	if not host or host == "" then
		host = "127.0.0.1"
	end
	if host:find(":") and host:sub(1, 1) ~= "[" then
		host = "[" .. host .. "]"
	end
	return host .. ":" .. tostring(port)
end

local function request_or_lan_host()
	local uci = require "luci.model.uci".cursor()
	local host = authority_host(http.getenv("HTTP_HOST") or "")
	if host ~= "" then
		return host
	end
	return uci:get("network", "lan", "ipaddr") or "127.0.0.1"
end

local function agentflow_config()
	local uci = require "luci.model.uci".cursor()
	local port = tonumber(uci:get_first("agentflow", "agentflow", "port")) or DEFAULT_PORT
	if port < 1 or port > 65535 then
		port = DEFAULT_PORT
	end
	local base_path = normalized_base_path(uci:get_first("agentflow", "agentflow", "base_path"))
	return port, base_path
end

local function agentflow_entry_url()
	local port, base_path = agentflow_config()
	if linkeasefull_running() and uhttpd_apps_proxy_available() then
		return base_path
	end
	return "http://" .. url_authority(request_or_lan_host(), port) .. base_path
end

local function node_modules_root()
	local sys = require "luci.sys"
	local util = require "luci.util"
	local script = table.concat({
		'. /lib/functions/mise.sh 2>/dev/null || exit 1',
		'istore_runtime_env >/dev/null 2>&1 || exit 1',
		'mise_bin="$(command -v mise-istore || command -v mise)"',
		'[ -n "$mise_bin" ] || exit 1',
		'node_dir="$("$mise_bin" where node@lts 2>/dev/null)"',
		'[ -n "$node_dir" ] || exit 1',
		'printf "%s/lib/node_modules" "$node_dir"'
	}, "; ")
	local root = sys.exec("/bin/sh -c " .. util.shellquote(script)) or ""
	root = root:match("^%s*(.-)%s*$")
	if root == "" or root:sub(1, 1) ~= "/" then
		return nil
	end
	return root
end

local function agent_statuses()
	local fs = require "nixio.fs"
	local jsonc = require "luci.jsonc"
	local root = node_modules_root()
	local statuses = {}

	for _, agent in ipairs(AGENTS) do
		local status = { id = agent.id, installed = false }
		if root then
			local package_file = root .. "/" .. agent.package .. "/package.json"
			local package_data = fs.readfile(package_file)
			local package_json = package_data and jsonc.parse(package_data) or nil
			if type(package_json) == "table" then
				status.installed = true
				status.version = package_json.version
			end
		end
		statuses[#statuses + 1] = status
	end

	return statuses, root ~= nil
end

function agentflow_status()
	local sys = require "luci.sys"
	local port, base_path = agentflow_config()
	local entry_url = agentflow_entry_url()
	local agents, agents_available = agent_statuses()

	local status = {
		running = (sys.call("pidof agentflow >/dev/null") == 0),
		port = port,
		base_path = base_path,
		entry_url = entry_url,
		proxy_prefix_supported = uhttpd_supports_proxy_prefix(),
		proxy_prefix_enabled = uhttpd_apps_proxy_available(),
		linkeasefull_running = linkeasefull_running(),
		agents_available = agents_available,
		agents = agents
	}
	write_json(status)
end

function agentflow_agent_install()
	local fs = require "nixio.fs"
	local jsonc = require "luci.jsonc"
	local sys = require "luci.sys"
	local util = require "luci.util"
	local task_id = "agentflow-agent-install"
	local task_script = "/tmp/agentflow-agent-install.sh"
	local installer_url = "https://fw.koolcenter.com/binary/geili/agentflow/releases/installapp/installapp-mise.sh"
	local supported_agents = {}
	for _, supported_agent in ipairs(AGENTS) do
		supported_agents[supported_agent.id] = true
	end

	if not require_post_csrf() then
		return
	end

	local agent = http.formvalue("agent") or ""
	if not supported_agents[agent] then
		write_json({ ok = false, error = "unsupported agent" })
		return
	end
	if not fs.access("/etc/init.d/tasks") then
		write_json({ ok = false, error = "taskd is not available" })
		return
	end
	if not fs.access("/lib/functions/mise.sh") then
		write_json({ ok = false, error = "mise environment helper is not available" })
		return
	end

	local task_status = sys.exec("/etc/init.d/tasks task_status " .. task_id .. " 2>/dev/null")
	local status = jsonc.parse(task_status) or {}
	local running = type(status) == "table" and status.running
	if running == true or running == 1 or running == "1" or running == "true" then
		write_json({ ok = true, busy = true, task_id = task_id })
		return
	end

	local install_script = table.concat({
		"set -e",
		"agent=" .. util.shellquote(agent),
		"installer_url=" .. util.shellquote(installer_url),
		'installer="/tmp/agentflow-installapp-mise.$$"',
		'cleanup() { rm -f "$installer" "$0"; }',
		"trap cleanup 0 HUP INT TERM",
		'. /lib/functions/mise.sh',
		'if ! istore_runtime_env; then echo "[agentflow] Failed to initialize the shared runtime environment" >&2; exit 1; fi',
		"set -u",
		"export MISE_YES=1",
		'echo "[agentflow] Downloading installer: $installer_url"',
		'if command -v wget >/dev/null 2>&1; then',
		'\twget -O "$installer" "$installer_url"',
		'elif command -v curl >/dev/null 2>&1; then',
		'\tcurl -fL -o "$installer" "$installer_url"',
		'elif command -v uclient-fetch >/dev/null 2>&1; then',
		'\tuclient-fetch -O "$installer" "$installer_url"',
		"else",
		'\techo "[agentflow] No HTTPS download tool is available" >&2',
		"\texit 1",
		"fi",
		'if [ ! -s "$installer" ]; then echo "[agentflow] Failed to download the agent installer" >&2; exit 1; fi',
		'chmod 0700 "$installer"',
		'echo "[agentflow] Running installapp-mise.sh for $agent in $HOME"',
		'/bin/sh "$installer" "$agent"'
	}, "\n")
	if not fs.writefile(task_script, install_script .. "\n") then
		write_json({ ok = false, error = "failed to create install task", task_id = task_id })
		return
	end
	if sys.call("chmod 0600 " .. util.shellquote(task_script)) ~= 0 then
		fs.unlink(task_script)
		write_json({ ok = false, error = "failed to secure install task", task_id = task_id })
		return
	end

	local command = "/bin/sh " .. util.shellquote(task_script)
	local rc = sys.call("/etc/init.d/tasks task_add " .. task_id .. " " .. util.shellquote(command) .. " >/dev/null 2>&1")
	if rc ~= 0 then
		fs.unlink(task_script)
		write_json({ ok = false, error = "failed to start install task", task_id = task_id })
		return
	end

	write_json({ ok = true, task_id = task_id })
end

function agentflow_open()
	local entry_url = agentflow_entry_url()
	http.redirect(entry_url)
end
