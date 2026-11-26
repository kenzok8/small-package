local http = require "luci.http"

module("luci.controller.dsh", package.seeall)

function index()
	local open = entry({"admin", "services", "dsh", "open"}, call("dsh_open"))
	open.leaf = true
	open.dependent = false
	open.sysauth = "root"
	open.sysauth_authenticator = "htmlauth"

	if not nixio.fs.access("/etc/config/dsh") then return end
	entry({"admin", "services", "dsh"}, cbi("dsh"), _("DSH"), 101).dependent = true
end

local function request_host()
	local authority = http.getenv("HTTP_HOST") or ""
	return authority:match("^(%[[%x:%.]+%]):?%d*$")
		or authority:match("^([%w%.%-]+):?%d*$")
end

local function runtime_value(action)
	local util = require "luci.util"
	return util.trim(util.exec("/usr/libexec/istorec/dsh.sh " .. action .. " 2>/dev/null"))
end

function dsh_open()
	local ctx = require("luci.dispatcher").context
	if http.getenv("REQUEST_METHOD") ~= "GET" then http.status(405); return end
	if not ctx.authsession or ctx.authuser ~= "root" then http.status(403); return end

	local host = request_host()
	local port = tonumber(runtime_value("port"))
	if not host or not port or port % 1 ~= 0 or port < 1024 or port > 65535
		or runtime_value("health") ~= "healthy" then
		http.status(503)
		return
	end

	local target = "http://" .. host .. ":" .. tostring(port) .. "/"

	http.header("Cache-Control", "no-store")
	http.header("Referrer-Policy", "no-referrer")
	http.redirect(target)
end
