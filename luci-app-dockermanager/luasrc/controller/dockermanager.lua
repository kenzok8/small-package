module("luci.controller.dockermanager", package.seeall)

local APPS_PROXY_PREFIX = "/apps=http://127.0.0.1:19290"

function index()
	entry({"admin", "services", "dockermanager_status"}, call("dockermanager_status"))
	local open = entry({"admin", "services", "dockermanager", "open"}, call("dockermanager_open"))
	open.leaf = true
	open.dependent = false
	open.sysauth = "root"
	open.sysauth_authenticator = "htmlauth"

	if not nixio.fs.access("/etc/config/dockermanager") then
		return
	end

	entry({"admin", "services", "dockermanager"}, cbi("dockermanager"), _("Docker Manager"), 22).dependent = true
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
	path = path or "/apps/dockermanager/"
	if path:sub(1, 1) ~= "/" then
		path = "/" .. path
	end
	if path:sub(-1) ~= "/" then
		path = path .. "/"
	end
	return path
end

local function cookie_encode(value)
	return tostring(value or ""):gsub("([^A-Za-z0-9._~-])", function(char)
		return string.format("%%%02X", char:byte())
	end)
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
	local http = require "luci.http"
	local uci  = require "luci.model.uci".cursor()
	local host = authority_host(http.getenv("HTTP_HOST") or "")
	if host ~= "" then
		return host
	end
	return uci:get("network", "lan", "ipaddr") or "127.0.0.1"
end

local function linkease_auth_url(name)
	local dispatcher = require "luci.dispatcher"
	return dispatcher.build_url("admin", "services", "linkease_auth", name)
end

local function dockermanager_config()
	local uci = require "luci.model.uci".cursor()
	local port = uci:get_first("dockermanager", "dockermanager", "port") or "8192"
	local base_path = normalized_base_path(uci:get_first("dockermanager", "dockermanager", "base_path"))
	local external_port_enabled = uci:get_first("dockermanager", "dockermanager", "external_port_enabled") == "1"
	local listen_mode = uci:get_first("dockermanager", "dockermanager", "listen_mode") or "auto"
	local socket_path = uci:get_first("dockermanager", "dockermanager", "socket_path") or "/var/run/dockermanager.sock"
	return port, base_path, external_port_enabled, listen_mode, socket_path
end

local function dockermanager_entry_url()
	local port, base_path, external_port_enabled = dockermanager_config()
	if linkeasefull_running() and uhttpd_apps_proxy_available() then
		return base_path
	end
	if not external_port_enabled then
		return nil
	end
	return "http://" .. url_authority(request_or_lan_host(), port) .. base_path
end

local function enable_external_port()
	local uci = require "luci.model.uci".cursor()
	local section = nil
	uci:foreach("dockermanager", "dockermanager", function(s)
		if not section then
			section = s[".name"]
		end
	end)
	if section then
		uci:set("dockermanager", section, "external_port_enabled", "1")
		uci:set("dockermanager", section, "listen_mode", "tcp")
		uci:commit("dockermanager")
	end
	local sys = require "luci.sys"
	sys.call("/etc/init.d/dockermanager restart >/dev/null 2>&1; sleep 1")
end

local function render_enable_port_confirm()
	local dispatcher = require "luci.dispatcher"
	local confirm_url = dispatcher.build_url("admin", "services", "dockermanager", "open") .. "?enable_port=1"
	luci.http.prepare_content("text/html; charset=utf-8")
	luci.http.write("<!doctype html><html><head><meta charset='utf-8'><title>Docker Manager</title></head><body>")
	luci.http.write("<h2>Docker Manager</h2>")
	luci.http.write("<p>当前系统无法通过 LinkEase 桌面代理打开 Docker Manager。</p>")
	luci.http.write("<p>可以启用局域网端口 8192 后继续打开。</p>")
	luci.http.write("<p><a class='cbi-button cbi-button-apply' href='" .. confirm_url .. "'>启用 8192 并打开</a></p>")
	luci.http.write("</body></html>")
end

local function render_open_failed()
	luci.http.prepare_content("text/html; charset=utf-8")
	luci.http.write("<!doctype html><html><head><meta charset='utf-8'><title>Docker Manager</title></head><body>")
	luci.http.write("<h2>Docker Manager</h2>")
	luci.http.write("<p>Docker Manager 已安装，但当前没有可用访问入口。</p>")
	luci.http.write("<p>请启用 LinkEaseFull 的 /apps 代理，或在 Docker Manager 设置中开放 8192 端口。</p>")
	luci.http.write("</body></html>")
end

function dockermanager_status()
	local sys = require "luci.sys"
	local uci = require "luci.model.uci".cursor()
	local port, base_path, external_port_enabled, listen_mode, socket_path = dockermanager_config()
	local entry_url = dockermanager_entry_url()

	local status = {
		running = (sys.call("pidof docker-manager >/dev/null") == 0),
		port = port,
		base_path = base_path,
		listen_mode = listen_mode,
		socket_path = socket_path,
		external_port_enabled = external_port_enabled,
		entry_url = entry_url or "",
		lan_ip = uci:get("network", "lan", "ipaddr") or "",
		proxy_prefix_supported = uhttpd_supports_proxy_prefix(),
		proxy_prefix_enabled = uhttpd_apps_proxy_available(),
		linkeasefull_running = linkeasefull_running()
	}

	luci.http.prepare_content("application/json")
	luci.http.write_json(status)
end

function dockermanager_open()
	local http = require "luci.http"
	if http.formvalue("enable_port") == "1" then
		enable_external_port()
	end

	local entry_url = dockermanager_entry_url()
	if entry_url then
		http.redirect(linkease_auth_url("auth") .. "?return=" .. cookie_encode(entry_url))
		return
	end

	if http.formvalue("enable_port") == "1" then
		render_open_failed()
		return
	end
	render_enable_port_confirm()
end
