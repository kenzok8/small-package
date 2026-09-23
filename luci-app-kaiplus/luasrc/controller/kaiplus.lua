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
	local external_port_enabled = uci:get_first("kaiplus", "kaiplus", "external_port_enabled") == "1"
	compat():legacy_status("kaiplus", {
		running = sys.call("pidof kaiplus_bin >/dev/null") == 0,
		port = uci:get_first("kaiplus", "kaiplus", "port") or "8189",
		base_path = uci:get_first("kaiplus", "kaiplus", "base_path") or "/apps/kaiplus/",
		listen_mode = uci:get_first("kaiplus", "kaiplus", "listen_mode") or "auto",
		socket_path = uci:get_first("kaiplus", "kaiplus", "socket_path") or "/var/run/kaiplus.sock",
		external_port_enabled = external_port_enabled,
		lan_ip = uci:get("network", "lan", "ipaddr") or ""
	})
end

function kaiplus_open()
	compat():open("kaiplus")
end
