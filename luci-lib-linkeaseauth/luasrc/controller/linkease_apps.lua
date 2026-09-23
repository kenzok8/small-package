module("luci.controller.linkease_apps", package.seeall)

function index()
	local open = entry({"admin", "services", "linkease_apps", "open"}, call("open"))
	open.leaf = true
	open.dependent = false
	open.sysauth = false

	local status = entry({"admin", "services", "linkease_apps", "status"}, call("status"))
	status.leaf = true
	status.dependent = false
	status.sysauth = "root"
	status.sysauth_authenticator = "htmlauth"
end

local function handler()
	local dispatcher = require "luci.dispatcher"
	return require("luci.model.linkease.apps_http").new({
		http = require "luci.http",
		resolver = require("luci.model.linkease.apps_openwrt").new(),
		auth_url = dispatcher.build_url("admin", "services", "linkease_auth", "auth")
	})
end

function open()
	handler():open()
end

function status()
	handler():status()
end
