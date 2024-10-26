module("luci.controller.mentohust", package.seeall)

function index()
	if not nixio.fs.access("/etc/config/mentohust") then
		return
	end

	local page = entry({"admin", "services", "mentohust"}, cbi("mentohust"), _("锐捷认证"))
	page.dependent = true
	page.acl_depends = { "luci-app-mentohust" }

	entry({"admin", "services", "mentohust", "status"}, call("act_status")).leaf = true
end

function act_status()
	local e = {}
	e.running = luci.sys.call("pgrep mentohust >/dev/null") == 0
	luci.http.prepare_content("application/json")
	luci.http.write_json(e)
end
