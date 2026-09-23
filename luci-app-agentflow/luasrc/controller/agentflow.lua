module("luci.controller.agentflow", package.seeall)

function index()
	entry({"admin", "services", "agentflow_status"}, call("agentflow_status"))
	local open = entry({"admin", "services", "agentflow", "open"}, call("agentflow_open"))
	open.leaf = true
	open.dependent = false
	open.sysauth = false

	if not nixio.fs.access("/etc/config/agentflow") then return end
	entry({"admin", "services", "agentflow"}, cbi("agentflow"), _("AgentFlow"), 100).dependent = true
end

local function compat()
	return require("luci.model.linkease.apps_compat").new()
end

function agentflow_status()
	local sys = require "luci.sys"
	local uci = require "luci.model.uci".cursor()
	compat():legacy_status("agentflow", {
		running = sys.call("pidof agentflow >/dev/null") == 0,
		port = uci:get_first("agentflow", "agentflow", "port") or "9000",
		base_path = uci:get_first("agentflow", "agentflow", "base_path") or "/apps/agentflow/"
	})
end

function agentflow_open()
	compat():open("agentflow")
end
