local http = require "luci.http"

module("luci.controller.kai", package.seeall)

function index()
	if not nixio.fs.access("/etc/config/kai") then
		return
	end
	local page
	page = entry({"admin", "services","kai"}, cbi("kai"), _("KAI"), 100)
	page.dependent = true
    entry({"admin", "services", "kai_status"}, call("kai_status"))

end

function kai_status()
	local sys  = require "luci.sys"
	local uci  = require "luci.model.uci".cursor()
	local status = {
		running = (sys.call("pidof kai_bin >/dev/null") == 0),
		port = 8197
	}
	luci.http.prepare_content("application/json")
	luci.http.write_json(status)
end
