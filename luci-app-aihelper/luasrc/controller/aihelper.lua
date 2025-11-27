local http = require "luci.http"

module("luci.controller.aihelper", package.seeall)

function index()
	if not nixio.fs.access("/etc/config/aihelper") then
		return
	end
	local page
	page = entry({"admin", "services","aihelper"}, cbi("aihelper"), _("AiHelper"), 100)
	page.dependent = true
    entry({"admin", "services", "aihelper_status"}, call("aihelper_status"))

end

function aihelper_status()
	local sys  = require "luci.sys"
	local uci  = require "luci.model.uci".cursor()
	local status = {
		running = (sys.call("pidof aihelper >/dev/null") == 0),
		port = 9310
	}
	luci.http.prepare_content("application/json")
	luci.http.write_json(status)
end
