local http = require "luci.http"

module("luci.controller.kaiplus", package.seeall)

function index()
	if not nixio.fs.access("/etc/config/kaiplus") then
		return
	end
	local page
	page = entry({"admin", "services", "kaiplus"}, cbi("kaiplus"), _("KaiPlus"), 100)
	page.dependent = true
	entry({"admin", "services", "kaiplus_status"}, call("kaiplus_status"))
end

function kaiplus_status()
	local sys = require "luci.sys"
	local uci = require "luci.model.uci".cursor()
	local port = uci:get_first("kaiplus", "kaiplus", "port", "8189")
	local base_path = uci:get_first("kaiplus", "kaiplus", "base_path", "/apps/kaiplus/")
	local status = {
		running = (sys.call("pidof kaiplus_bin >/dev/null") == 0),
		port = port,
		base_path = base_path
	}
	luci.http.prepare_content("application/json")
	luci.http.write_json(status)
end
