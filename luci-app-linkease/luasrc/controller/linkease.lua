module("luci.controller.linkease", package.seeall)

function index()
	if not nixio.fs.access("/etc/config/linkease") then
		return
	end

	entry({"admin", "services", "linkease"}, cbi("linkease"), _("LinkEase"), 20).dependent = true

	entry({"admin", "services", "linkease_status"}, call("linkease_status"))
end

function linkease_status()
	local sys  = require "luci.sys"
	local uci  = require "luci.model.uci".cursor()
	local port = tonumber(uci:get_first("linkease", "linkease", "port"))
	local full_enabled = (uci:get_first("linkeasefull", "linkeasefull", "enabled") == "1")

	local status = {
		running = (sys.call("pidof linkease >/dev/null") == 0),
		port = (port or 8897),
		conflict = full_enabled,
		conflict_service = full_enabled and "linkeasefull" or ""
	}

	luci.http.prepare_content("application/json")
	luci.http.write_json(status)
end
