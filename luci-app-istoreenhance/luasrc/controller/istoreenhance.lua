module("luci.controller.istoreenhance", package.seeall)

function index()
	if not nixio.fs.access("/etc/config/istoreenhance") then
		return
	end

	entry({"admin", "services", "istoreenhance"}, cbi("istoreenhance"), _("iStoreEnhance"), 20).dependent = true

	entry({"admin", "services", "istoreenhance_status"}, call("istoreenhance_status"))
end

function istoreenhance_status()
	local sys  = require "luci.sys"
	local uci  = require "luci.model.uci".cursor()
	local port = tonumber(uci:get_first("istoreenhance", "istoreenhance", "adminport"))

	local status = {
		running = (sys.call("pidof iStoreEnhance >/dev/null") == 0),
		port = (port or 5003)
	}

	luci.http.prepare_content("application/json")
	luci.http.write_json(status)
end

