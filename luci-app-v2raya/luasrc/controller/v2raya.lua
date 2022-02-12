module("luci.controller.v2raya", package.seeall)

function index()
	if not nixio.fs.access("/etc/config/v2raya") then
		return
	end

	local page = entry({"admin", "services", "v2raya"}, cbi("v2raya"), _("v2rayA"), 30)
	page.dependent = true
	page.acl_depends = { "luci-app-v2raya" }

	entry({"admin", "services", "v2raya", "status"}, call("act_status")).leaf = true
end

function act_status()
	local e = {}
	e.running = luci.sys.call("pgrep -f v2raya >/dev/null") == 0
	e.bin_version = luci.sys.exec("v2raya --version")
	luci.http.prepare_content("application/json")
	luci.http.write_json(e)
end
