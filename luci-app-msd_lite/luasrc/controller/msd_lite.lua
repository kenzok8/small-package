
module("luci.controller.msd_lite", package.seeall)

function index()
	if not nixio.fs.access("/etc/config/msd_lite") then
		return
	end

	local page
	page = entry({"admin", "services", "msd_lite"}, cbi("msd_lite"), _("MultiSD_Lite"), 60)
	page.dependent = true
	page = entry({"admin", "services", "msd_lite", "status"}, call("act_status"))
	page.leaf = true
end

local function is_running()
	return luci.sys.call("pidof msd_lite >/dev/null") == 0
end

function act_status()
	local e = {}
	e.running = is_running()
	luci.http.prepare_content("application/json")
	luci.http.write_json(e)
end
