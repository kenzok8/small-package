module("luci.controller.gecoosac", package.seeall)
local uci=require"luci.model.uci".cursor()

function index()
	if not nixio.fs.access("/etc/config/gecoosac") then
		return
	end
	entry({"admin", "services"}, firstchild(), _("services") , 45).dependent = false
	local page
	page = entry({"admin", "services", "gecoosac"}, cbi("gecoosac"), _("集客AC控制器"), 100)
	page.dependent = true
	entry({"admin","services","gecoosac","status"},call("act_status")).leaf=true
end

function act_status()
	local e={}
	local binpath=uci:get("gecoosac","config","program_path")
	e.running=luci.sys.call("pgrep "..binpath.." >/dev/null")==0
	luci.http.prepare_content("application/json")
	luci.http.write_json(e)
end
