module("luci.controller.istoreenhance", package.seeall)

function index()
	if not nixio.fs.access("/etc/config/istoreenhance") then return end

	entry({"admin", "services", "istoreenhance"}, cbi("istoreenhance"), _("KSpeeder"), 20).dependent = true
	entry({"admin", "services", "istoreenhance_status"}, call("istoreenhance_status"))
	local open = entry({"admin", "services", "istoreenhance", "open"}, call("istoreenhance_open"))
	open.leaf = true
	open.dependent = false
	open.sysauth = false
end

local function compat()
	return require("luci.model.linkease.apps_compat").new()
end

function istoreenhance_status()
	local sys = require "luci.sys"
	local uci = require "luci.model.uci".cursor()
	compat():legacy_status("kspeeder", {
		running = sys.call("pidof iStoreEnhance >/dev/null") == 0,
		port = uci:get_first("istoreenhance", "istoreenhance", "adminport") or "5003"
	})
end

function istoreenhance_open()
	compat():open("kspeeder")
end
