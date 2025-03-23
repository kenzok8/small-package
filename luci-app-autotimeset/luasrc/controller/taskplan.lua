module("luci.controller.taskplan",package.seeall)
local fs=require"nixio.fs"
local http=require"luci.http"
function index()
	if not nixio.fs.access("/etc/config/taskplan") then
		return
	end
        entry({"admin", "control"}, firstchild(), "Control", 44).dependent = false
        local e = entry({"admin", "control", "taskplan"}, alias("admin", "control", "taskplan", "scheduledtask"), _("Task Plan"), 20)
	e.dependent = false
	e.acl_depends = { "luci-app-taskplan" }
        entry({"admin", "control", "taskplan", "scheduledtask"}, cbi("taskplan/scheduledtask"),  _("Scheduled task"), 10).leaf = true
        entry({"admin", "control", "taskplan", "startuptask"}, cbi("taskplan/startuptask"),  _("Startup task"), 20).leaf = true
        entry({"admin", "control", "taskplan", "log"}, form("taskplan/log"), _("Log"), 30).leaf = true
        entry({"admin","control","taskplan","dellog"},call("dellog"))
        entry({"admin","control","taskplan","getlog"},call("getlog"))
end

function getlog()
	logfile="/etc/taskplan/taskplan.log"
	if not fs.access(logfile) then
		http.write("")
		return
	end
	local f=io.open(logfile,"r")
	local a=f:read("*a") or ""
	f:close()
	a=string.gsub(a,"\n$","")
	http.prepare_content("text/plain; charset=utf-8")
	http.write(a)
end

function dellog()
	fs.writefile("/etc/taskplan/taskplan.log","")
	http.prepare_content("application/json")
	http.write('')
end
