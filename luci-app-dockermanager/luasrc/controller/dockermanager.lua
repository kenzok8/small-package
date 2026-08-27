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
	return port, base_path
end

local function dockermanager_entry_url()
	local port, base_path = dockermanager_config()
	if uhttpd_apps_proxy_available() then
		return base_path
	end
	return "http://" .. url_authority(request_or_lan_host(), port) .. base_path
end

function dockermanager_status()
	local sys = require "luci.sys"
	local uci = require "luci.model.uci".cursor()
	local port, base_path = dockermanager_config()

	local status = {
		running = (sys.call("pidof docker-manager >/dev/null") == 0),
		port = port,
		base_path = base_path,
		lan_ip = uci:get("network", "lan", "ipaddr") or "",
		proxy_prefix_supported = uhttpd_supports_proxy_prefix(),
		proxy_prefix_enabled = uhttpd_apps_proxy_available()
	}

	luci.http.prepare_content("application/json")
	luci.http.write_json(status)
end

function dockermanager_open()
	local http = require "luci.http"
	http.redirect(linkease_auth_url("auth") .. "?return=" .. cookie_encode(dockermanager_entry_url()))
end
