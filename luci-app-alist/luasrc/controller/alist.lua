module("luci.controller.alist", package.seeall)

function index()
	if not nixio.fs.access("/etc/config/alist") then
		return
	end

	entry({"admin", "nas"}, firstchild(), "NAS", 44).dependent = false
	entry({"admin", "nas", "alist"}, cbi("alist"), _("Alist"), 20).dependent = true
	entry({"admin", "nas", "alist_status"}, call("alist_status"))
end

function alist_status()
	local sys  = require "luci.sys"
	local uci  = require "luci.model.uci".cursor()
	local port = tonumber(uci:get_first("alist", "alist", "port"))

	local status = {
		running = (sys.call("pidof alist >/dev/null") == 0),
		port = (port or 5244)
	}

	luci.http.prepare_content("application/json")
	luci.http.write_json(status)
end
