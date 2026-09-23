module("luci.controller.baidudrive", package.seeall)

function index()
	if not nixio.fs.access("/etc/config/baidudrive") then return end
	entry({"admin", "services", "baidudrive"}, cbi("baidudrive"), _("BaiduDrive"), 100).dependent = true
	entry({"admin", "services", "baidudrive_status"}, call("baidudrive_status"))

	local open = entry({"admin", "services", "baidudrive", "open"}, call("baidudrive_open"))
	open.leaf = true
	open.dependent = false
	open.sysauth = "root"
	open.sysauth_authenticator = "htmlauth"
end

local function compat()
	local dispatcher = require "luci.dispatcher"
	return require("luci.model.linkease.apps_compat").new({
		http = require "luci.http",
		resolver = require("luci.model.linkease.apps_openwrt").new(),
		auth_url = dispatcher.build_url("admin", "services", "linkease_auth", "auth")
	})
end

function baidudrive_status()
	local sys = require "luci.sys"
	local uci = require("luci.model.uci").cursor()
	local app_running = sys.call("pidof baidudrive >/dev/null") == 0
	local sdk_running = sys.call("pidof baiduNas >/dev/null") == 0
	compat():legacy_status("baidudrive", {
		running = app_running and sdk_running,
		app_running = app_running,
		sdk_running = sdk_running,
		port = uci:get_first("baidudrive", "baidudrive", "port") or "10780"
	})
end

function baidudrive_open()
	compat():open("baidudrive")
end
