module("luci.controller.fastnet", package.seeall)

function index()
	if not nixio.fs.access("/etc/config/fastnet") then return end

	entry({"admin", "services", "fastnet"}, cbi("fastnet"), _("FastNet"), 50).dependent = true
	entry({"admin", "services", "fastnet", "status"}, call("action_status")).leaf = true
	local open = entry({"admin", "services", "fastnet", "open"}, call("action_open"))
	open.leaf = true
	open.dependent = false
	open.sysauth = false
end

local function compat()
	local dispatcher = require "luci.dispatcher"
	return require("luci.model.linkease.apps_compat").new({
		http = require "luci.http",
		resolver = require("luci.model.linkease.apps_openwrt").new(),
		auth_url = dispatcher.build_url("admin", "services", "linkease_auth", "auth")
	})
end

function action_status()
	local sys = require "luci.sys"
	local uci = require "luci.model.uci".cursor()
	compat():legacy_status("fastnet", {
		running = sys.call("pidof FastNet >/dev/null") == 0,
		port = uci:get_first("fastnet", "fastnet", "port") or "3200"
	})
end

function action_open()
	compat():open("fastnet")
end
