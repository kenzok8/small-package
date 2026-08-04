module("luci.controller.linkeasefull", package.seeall)

function index()
	if not nixio.fs.access("/etc/config/linkeasefull") then
		return
	end

	entry({"admin", "services", "linkeasefull"}, cbi("linkeasefull"), _("LinkEase Full"), 21).dependent = true
	entry({"admin", "services", "linkeasefull_status"}, call("linkeasefull_status"))
	entry({"admin", "services", "linkeasefull", "auth"}, call("linkeasefull_auth")).leaf = true
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

function linkeasefull_status()
	local sys  = require "luci.sys"
	local uci  = require "luci.model.uci".cursor()
	local linkease_enabled = (uci:get_first("linkease", "linkease", "enabled") == "1")

	local status = {
		running = (sys.call("pidof linkease-full >/dev/null") == 0),
		full_port = 19290,
		legacy_port = 8897,
		base_path = "/apps/",
		lan_ip = uci:get("network", "lan", "ipaddr") or "",
		proxy_prefix_enabled = uhttpd_has_apps_proxy_prefix(),
		conflict = linkease_enabled,
		conflict_service = linkease_enabled and "linkease" or ""
	}

	luci.http.prepare_content("application/json")
	luci.http.write_json(status)
end

local function retrieve_luci_session()
	local http = require "luci.http"
	local util = require "luci.util"

	for _, key in ipairs({"sysauth_https", "sysauth_http", "sysauth"}) do
		local sid = http.getcookie(key)
		if sid and sid ~= "" then
			local sdat = util.ubus("session", "get", { ubus_rpc_session = sid })
			if sdat and type(sdat.values) == "table" then
				return sid
			end
		end
	end
	return nil
end

local function valid_apps_return(value)
	if not value or value == "" then
		return false
	end
	if value == "/apps" then
		return true
	end
	local prefix = value:sub(1, 6)
	return prefix == "/apps/" or prefix == "/apps?" or prefix == "/apps#"
end

local function valid_cookie_value(value)
	return value and value:match("^[A-Za-z0-9._%-_]+$") ~= nil
end

function linkeasefull_auth()
	local http = require "luci.http"
	local sid = retrieve_luci_session()

	if not valid_cookie_value(sid) then
		http.status(403, "Forbidden")
		return
	end

	local target = http.formvalue("return") or "/apps/"
	if not valid_apps_return(target) then
		target = "/apps/"
	end

	http.header("Set-Cookie", "linkease_openwrt_sid=" .. sid .. "; Path=/apps; HttpOnly; SameSite=Lax")
	http.redirect(target)
end
