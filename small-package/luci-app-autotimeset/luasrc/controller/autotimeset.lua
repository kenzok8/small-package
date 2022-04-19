module("luci.controller.autotimeset",package.seeall)
function index()
	if not nixio.fs.access("/etc/config/autotimeset") then
		return
	end
	local page
	page = entry({"admin","system","autotimeset"},cbi("autotimeset"),_("Scheduled Setting"),88)
	page.dependent = true
end
