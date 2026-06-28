local http = require "luci.http"

module("luci.controller.virtualdog", package.seeall)

function index()
	if not nixio.fs.access("/etc/config/virtualdog") then
		return
	end

	local page
	page = entry({"admin", "services", "virtualdog"}, cbi("virtualdog"), _("VirtualDog"), 70)
	page.dependent = true
	entry({"admin", "services", "virtualdog_status"}, call("virtualdog_status"))
end

function virtualdog_status()
	local sys = require "luci.sys"
	local uci = require "luci.model.uci".cursor()
	local port = uci:get_first("virtualdog", "virtualdog", "port") or "8080"
	local status = {
		running = (sys.call("pidof virtualdogd >/dev/null") == 0),
		port = port
	}
	http.prepare_content("application/json")
	http.write_json(status)
end
