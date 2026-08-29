local http = require "luci.http"

module("luci.controller.agentflow", package.seeall)

function index()
	if not nixio.fs.access("/etc/config/agentflow") then
		return
	end

	local page = entry({"admin", "services", "agentflow"}, cbi("agentflow"), _("AgentFlow"), 100)
	page.dependent = true
	entry({"admin", "services", "agentflow_status"}, call("agentflow_status"))
end

function agentflow_status()
	local sys = require "luci.sys"
	local uci = require "luci.model.uci".cursor()
	local port = tonumber(uci:get_first("agentflow", "agentflow", "port")) or 9000
	if port < 1 or port > 65535 then
		port = 9000
	end

	local status = {
		running = (sys.call("pidof agentflow >/dev/null") == 0),
		port = port
	}
	http.prepare_content("application/json")
	http.write_json(status)
end
