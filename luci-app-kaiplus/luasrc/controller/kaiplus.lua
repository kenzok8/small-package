module("luci.controller.kaiplus", package.seeall)

function index()
	entry({"admin", "services", "kaiplus_status"}, call("kaiplus_status"))
	local open = entry({"admin", "services", "kaiplus", "open"}, call("kaiplus_open"))
	open.leaf = true
	open.dependent = false
	open.sysauth = "root"
	open.sysauth_authenticator = "htmlauth"

	if not nixio.fs.access("/etc/config/kaiplus") then return end
	entry({"admin", "services", "kaiplus"}, cbi("kaiplus"), _("KaiPlus"), 100).dependent = true
end

local function compat()
	local dispatcher = require "luci.dispatcher"
	return require("luci.model.linkease.apps_compat").new({
		http = require "luci.http",
		resolver = require("luci.model.linkease.apps_openwrt").new(),
		auth_url = dispatcher.build_url("admin", "services", "linkease_auth", "auth")
	})
end

function kaiplus_status()
	local sys = require "luci.sys"
	local uci = require("luci.model.uci").cursor()
	compat():legacy_status("kaiplus", {
		running = sys.call("pidof kaiplus >/dev/null") == 0,
		port = uci:get_first("kaiplus", "kaiplus", "port") or "8189",
		base_path = "/apps/kaiplus/",
		listen_mode = "tcp",
		external_port_enabled = true,
		lan_ip = uci:get("network", "lan", "ipaddr") or ""
	})
end

function kaiplus_open()
	compat():open("kaiplus")
end
