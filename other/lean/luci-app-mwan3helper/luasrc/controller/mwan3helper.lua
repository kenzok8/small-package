module("luci.controller.mwan3helper", package.seeall)

function index()
	if not nixio.fs.access("/etc/config/mwan3helper") then
		return
	end

	entry({"admin", "services", "mwan3helper"}, alias("admin", "services", "mwan3helper", "list"), _("MWAN3 Helper"), 300).dependent = true
	entry({"admin", "services", "mwan3helper", "list"}, cbi("mwan3helper/list")).leaf = true
end
