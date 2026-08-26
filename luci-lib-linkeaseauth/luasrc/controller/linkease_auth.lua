module("luci.controller.linkease_auth", package.seeall)

function index()
	local auth = entry({"admin", "services", "linkease_auth", "auth"}, call("linkease_auth"))
	auth.leaf = true
	auth.dependent = false
	auth.sysauth = "root"
	auth.sysauth_authenticator = "htmlauth"

	local auth_finish = entry({"admin", "services", "linkease_auth", "auth_finish"}, call("linkease_auth_finish"))
	auth_finish.leaf = true
	auth_finish.dependent = false
	auth_finish.sysauth = "root"
	auth_finish.sysauth_authenticator = "htmlauth"
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

local function authority_host(authority)
	if not authority or authority == "" then
		return ""
	end
	if authority:sub(1, 1) == "[" then
		return authority:match("^%[([^%]]+)%]") or ""
	end
	return authority:match("^([^:]+)") or authority
end

local function valid_apps_return(value)
	if not value or value == "" then
		return false
	end
	local function valid_path(path)
		if path == "/apps" then
			return true
		end
		local prefix = path:sub(1, 6)
		return prefix == "/apps/" or prefix == "/apps?" or prefix == "/apps#"
	end
	if value:sub(1, 1) == "/" then
		return valid_path(value)
	end

	local scheme, authority, path = value:match("^(https?://)([^/]+)(/.*)$")
	if not scheme or not authority or not valid_path(path) then
		return false
	end

	local http = require "luci.http"
	local uci = require "luci.model.uci".cursor()
	local request_host = http.getenv("HTTP_HOST") or ""
	local lan_host = uci:get("network", "lan", "ipaddr") or ""
	local authority_host_value = authority_host(authority)

	if authority_host_value ~= "" and authority_host_value == authority_host(request_host) then
		return true
	end
	if authority_host_value ~= "" and authority_host_value == authority_host(lan_host) then
		return true
	end

	-- Example: http://192.168.30.93:8192/apps/dockermanager/
	return false
end

local function valid_cookie_value(value)
	return value and value:match("^[A-Za-z0-9._%-_]+$") ~= nil
end

local pending_return_cookie = "linkease_openwrt_pending_return"
local bridge_return_cookie = "linkease_openwrt_return"
local pending_return_cookie_path = "/cgi-bin/luci/admin/services/linkease_auth"
local bridge_return_cookie_path = "/cgi-bin/luci/admin/services/linkease_auth/auth"

local function cookie_encode(value)
	return tostring(value or ""):gsub("([^A-Za-z0-9._~-])", function(char)
		return string.format("%%%02X", char:byte())
	end)
end

local function cookie_decode(value)
	if not value or value == "" then
		return nil
	end
	return value:gsub("%%(%x%x)", function(hex)
		return string.char(tonumber(hex, 16))
	end)
end

local function safe_return_target(value)
	if valid_apps_return(value) then
		return value
	end
	return "/apps/"
end

local function set_pending_return_cookie(target)
	local http = require "luci.http"
	http.header("Set-Cookie", pending_return_cookie .. "=" .. cookie_encode(target) .. "; Path=" .. pending_return_cookie_path .. "; Max-Age=300; HttpOnly; SameSite=Lax")
end

local function clear_pending_return_cookie()
	local http = require "luci.http"
	http.header("Set-Cookie", pending_return_cookie .. "=; Path=" .. pending_return_cookie_path .. "; Max-Age=0; HttpOnly; SameSite=Lax")
end

local function clear_bridge_return_cookie()
	local http = require "luci.http"
	http.header("Set-Cookie", bridge_return_cookie .. "=; Path=" .. bridge_return_cookie_path .. "; Max-Age=0; HttpOnly; SameSite=Lax")
end

local function requested_return_target()
	local http = require "luci.http"
	return safe_return_target(http.formvalue("return") or cookie_decode(http.getcookie(bridge_return_cookie)) or "/apps/")
end

local function pending_return_target()
	local http = require "luci.http"
	return safe_return_target(cookie_decode(http.getcookie(pending_return_cookie)))
end

local function auth_finish_url()
	local dispatcher = require "luci.dispatcher"
	return dispatcher.build_url("admin", "services", "linkease_auth", "auth_finish")
end

function linkease_auth()
	local http = require "luci.http"
	local sid = retrieve_luci_session()
	local target = requested_return_target()

	if valid_cookie_value(sid) then
		clear_bridge_return_cookie()
		http.header("Set-Cookie", "linkease_openwrt_sid=" .. sid .. "; Path=/apps; HttpOnly; SameSite=Lax")
		http.redirect(target)
		return
	end

	set_pending_return_cookie(target)
	http.redirect(auth_finish_url())
end

function linkease_auth_finish()
	local http = require "luci.http"
	local sid = retrieve_luci_session()

	if not valid_cookie_value(sid) then
		http.status(403, "Forbidden")
		return
	end

	local target = pending_return_target()

	clear_pending_return_cookie()
	http.header("Set-Cookie", "linkease_openwrt_sid=" .. sid .. "; Path=/apps; HttpOnly; SameSite=Lax")
	http.redirect(target)
end
