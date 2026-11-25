local http = require "luci.http"

module("luci.controller.agentflow", package.seeall)

function index()
	local status = entry({"admin", "services", "agentflow_status"}, call("agentflow_status"))
	status.acl_depends = { "luci-app-agentflow" }
	local open = entry({"admin", "services", "agentflow", "open"}, call("agentflow_open"))
	open.leaf = true
	open.dependent = false
	open.sysauth = false

	if not nixio.fs.access("/etc/config/agentflow") then return end
	entry({"admin", "services", "agentflow"}, cbi("agentflow"), _("AgentFlow"), 100).dependent = true
end

local function compat()
	local dispatcher = require "luci.dispatcher"
	return require("luci.model.linkease.apps_compat").new({
		http = http,
		resolver = require("luci.model.linkease.apps_openwrt").new(),
		auth_url = dispatcher.build_url("admin", "services", "linkease_auth", "auth")
	})
end

function agentflow_status()
	local sys = require "luci.sys"
	local uci = require "luci.model.uci".cursor()
	local providers = require("luci.model.agentflow.providers").new():list()
	compat():legacy_status("agentflow", {
		running = sys.call("pidof agentflow >/dev/null") == 0,
		port = uci:get_first("agentflow", "agentflow", "port") or "9000",
		base_path = "/apps/agentflow/",
		providers = providers
	})
end

function agentflow_open()
	compat():open("agentflow")
end
