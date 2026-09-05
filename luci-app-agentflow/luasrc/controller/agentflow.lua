local http = require "luci.http"

module("luci.controller.agentflow", package.seeall)

local APPS_PROXY_PREFIX = "/apps=http://127.0.0.1:19290"
local DEFAULT_BASE_PATH = "/apps/agentflow/"
local DEFAULT_PORT = 9000

function index()
	entry({"admin", "services", "agentflow_status"}, call("agentflow_status"))
	local open = entry({"admin", "services", "agentflow", "open"}, call("agentflow_open"))
	open.leaf = true
	open.dependent = false
	open.sysauth = false

	if not nixio.fs.access("/etc/config/agentflow") then
		return
	end

	local page = entry({"admin", "services", "agentflow"}, cbi("agentflow"), _("AgentFlow"), 100)
	page.dependent = true
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

function agentflow_status()
	local sys = require "luci.sys"
	local port, base_path = agentflow_config()
	local entry_url = agentflow_entry_url()

	local status = {
		running = (sys.call("pidof agentflow >/dev/null") == 0),
		port = port,
		base_path = base_path,
		entry_url = entry_url,
		proxy_prefix_supported = uhttpd_supports_proxy_prefix(),
		proxy_prefix_enabled = uhttpd_apps_proxy_available(),
		linkeasefull_running = linkeasefull_running()
	}
	http.prepare_content("application/json")
	http.write_json(status)
end

function agentflow_open()
	local entry_url = agentflow_entry_url()
	http.redirect(entry_url)
end
