local http = require "luci.http"

module("luci.controller.baidudrive", package.seeall)

function index()
	if not nixio.fs.access("/etc/config/baidudrive") then
		return
	end
	local page
	page = entry({"admin", "services", "baidudrive"}, cbi("baidudrive"), _("BaiduDrive"), 100)
	page.dependent = true
	entry({"admin", "services", "baidudrive_status"}, call("baidudrive_status"))
end

function baidudrive_status()
	local sys = require "luci.sys"
	local uci = require "luci.model.uci".cursor()
	local port = uci:get_first("baidudrive", "baidudrive", "port") or "8080"
	local status = {
		running = (sys.call("pidof baidudrive >/dev/null") == 0),
		port = port
	}
	luci.http.prepare_content("application/json")
	luci.http.write_json(status)
end
