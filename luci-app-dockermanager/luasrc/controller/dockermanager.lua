module("luci.controller.dockermanager", package.seeall)

function index()
	entry({"admin", "services", "dockermanager_status"}, call("dockermanager_status"))
	local open = entry({"admin", "services", "dockermanager", "open"}, call("dockermanager_open"))
	open.leaf = true
	open.dependent = false
	open.sysauth = "root"
	open.sysauth_authenticator = "htmlauth"

	if not nixio.fs.access("/etc/config/dockermanager") then return end
	entry({"admin", "services", "dockermanager"}, cbi("dockermanager"), _("Docker Manager"), 22).dependent = true
end

local function compat()
	local dispatcher = require "luci.dispatcher"
	return require("luci.model.linkease.apps_compat").new({
		http = require "luci.http",
		resolver = require("luci.model.linkease.apps_openwrt").new(),
		auth_url = dispatcher.build_url("admin", "services", "linkease_auth", "auth")
	})
end

function dockermanager_status()
	local sys = require "luci.sys"
	local uci = require("luci.model.uci").cursor()
	compat():legacy_status("dockermanager", {
		running = sys.call("pidof docker-manager >/dev/null") == 0,
		port = uci:get_first("dockermanager", "dockermanager", "port") or "8192",
		base_path = uci:get_first("dockermanager", "dockermanager", "base_path") or "/apps/dockermanager/",
		listen_mode = uci:get_first("dockermanager", "dockermanager", "listen_mode") or "auto",
		socket_path = uci:get_first("dockermanager", "dockermanager", "socket_path") or "/var/run/dockermanager.sock",
		external_port_enabled = uci:get_first("dockermanager", "dockermanager", "external_port_enabled") == "1",
		lan_ip = uci:get("network", "lan", "ipaddr") or ""
	})
end

function dockermanager_open()
	compat():open("dockermanager")
end
