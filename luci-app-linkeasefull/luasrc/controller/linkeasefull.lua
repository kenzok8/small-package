module("luci.controller.linkeasefull", package.seeall)

function index()
	entry({"admin", "services", "linkeasefull_status"}, call("linkeasefull_status"))
	local open = entry({"admin", "services", "linkeasefull", "open"}, call("linkeasefull_open"))
	open.leaf = true
	open.dependent = false
	open.sysauth = "root"
	open.sysauth_authenticator = "htmlauth"
	local auth = entry({"admin", "services", "linkeasefull", "auth"}, call("linkeasefull_auth"))
	auth.leaf = true
	auth.dependent = false
	auth.sysauth = "root"
	auth.sysauth_authenticator = "htmlauth"
	local auth_finish = entry({"admin", "services", "linkeasefull", "auth_finish"}, call("linkeasefull_auth_finish"))
	auth_finish.leaf = true
	auth_finish.dependent = false
	auth_finish.sysauth = "root"
	auth_finish.sysauth_authenticator = "htmlauth"

	if not nixio.fs.access("/etc/config/linkeasefull") then
		return
	end

	entry({"admin", "services", "linkeasefull"}, cbi("linkeasefull"), _("LinkEase Full"), 21).dependent = true
end

local function uhttpd_has_apps_proxy_prefix()
	local uci = require "luci.model.uci".cursor()
	local mappings = uci:get_list("uhttpd", "main", "proxy_prefix") or {}

	for _, mapping in ipairs(mappings) do
		if mapping == "/apps=http://127.0.0.1:19290" then
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

function linkeasefull_status()
	local sys  = require "luci.sys"
	local uci  = require "luci.model.uci".cursor()

	local status = {
		running = (sys.call("pidof linkease-full >/dev/null") == 0),
		full_port = 19290,
		legacy_port = 8897,
		base_path = "/apps/",
		lan_ip = uci:get("network", "lan", "ipaddr") or "",
		proxy_prefix_supported = uhttpd_supports_proxy_prefix(),
		proxy_prefix_enabled = uhttpd_apps_proxy_available(),
		conflict = false,
		conflict_service = ""
	}

	luci.http.prepare_content("application/json")
	luci.http.write_json(status)
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

local function linkeasefull_entry_url()
	if uhttpd_apps_proxy_available() then
		return "/apps/"
	end
	return "http://" .. url_authority(request_or_lan_host(), 19290) .. "/apps/"
end

function linkeasefull_open()
	local http = require "luci.http"
	http.redirect(linkease_auth_url("auth") .. "?return=" .. cookie_encode(linkeasefull_entry_url()))
end

function linkeasefull_auth()
	local http = require "luci.http"
	local target = http.formvalue("return") or "/apps/"
	http.redirect(linkease_auth_url("auth") .. "?return=" .. cookie_encode(target))
end

function linkeasefull_auth_finish()
	local http = require "luci.http"
	http.redirect(linkease_auth_url("auth_finish"))
end
