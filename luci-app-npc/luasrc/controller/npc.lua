module("luci.controller.npc",package.seeall)
function index()
if not nixio.fs.access("/etc/config/npc")then
return
end
local e
e=entry({"admin","services","npc"},cbi("npc"),_("Npc"),100)
e.i18n="npc"
e.dependent=true
entry({"admin","services","npc","status"},call("status")).leaf=true
end
function status()
local e={}
e.running=luci.sys.call("pgrep npc > /dev/null")==0
luci.http.prepare_content("application/json")
luci.http.write_json(e)
end
