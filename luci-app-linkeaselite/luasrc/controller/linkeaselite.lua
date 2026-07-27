module("luci.controller.linkeaselite", package.seeall)

function index()
	if not nixio.fs.access("/etc/config/linkeaselite") then
		return
	end

	local page = entry({"admin", "services", "linkeaselite"}, firstchild(), _("LinkEaseLite"), 20)
	page.dependent = true
	entry({"admin", "services", "linkeaselite", "config"}, cbi("linkeaselite"), _("Settings"), 10).leaf = true
	entry({"admin", "services", "linkeaselite_status"}, call("linkeaselite_status"))
	entry({"admin", "services", "linkeaselite", "file"}, call("linkeaselite_file_removed")).leaf = true
end

function linkeaselite_status()
	local sys  = require "luci.sys"
	local uci  = require "luci.model.uci".cursor()
	local port = tonumber(uci:get_first("linkeaselite", "linkeaselite", "port"))

	local status = {
		running = (sys.call("pidof linkease-lite >/dev/null") == 0),
		port = (port or 8897)
	}

	luci.http.prepare_content("application/json")
	luci.http.write_json(status)
end

function linkeaselite_file_removed()
	luci.http.status(404, "Not Found")
end
