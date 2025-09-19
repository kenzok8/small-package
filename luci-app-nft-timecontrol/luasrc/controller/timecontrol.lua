module("luci.controller.timecontrol", package.seeall)
-- Copyright 2022-2025 sirpdboy <herboy2008@gmail.com>
function index()
    if not nixio.fs.access("/etc/config/timecontrol") then return end
    entry({"admin", "control"}, firstchild(), "Control", 44).dependent = false

    local e = entry({"admin", "control", "timecontrol"}, cbi("timecontrol"), _("Timecontrol"), 10)
    e.dependent=false
    e.acl_depends = { "luci-app-timecontrol" }
    entry({"admin", "control", "timecontrol", "status"}, call("act_status")).leaf = true
end

function act_status()
    local sys  = require "luci.sys"
    local e = {} 
     e.status = sys.call(" busybox ps -w | grep timecontrol | grep -v grep  >/dev/null ") == 0  
    luci.http.prepare_content("application/json")
    luci.http.write_json(e)
end
