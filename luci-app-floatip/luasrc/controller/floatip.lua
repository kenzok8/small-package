module("luci.controller.floatip", package.seeall)

function index()
	if not nixio.fs.access("/etc/config/floatip") then
		return
	end

	entry({"admin", "services", "floatip"}, cbi("floatip"), _("FloatingGateway"), 20).dependent = true

	entry({"admin", "services", "floatip_status"}, call("floatip_status"))
end

function floatip_status()
	local sys  = require "luci.sys"
	local uci  = require "luci.model.uci".cursor()

	local status = {
		running = (sys.call("pidof floatip.sh >/dev/null") == 0),
	}

	luci.http.prepare_content("application/json")
	luci.http.write_json(status)
end

