module("luci.controller.shanligong", package.seeall)

function index()
    entry({"admin", "services", "shanligong"}, alias("admin", "services", "shanligong", "post"), _("山理工认证"), 99).index = true
    entry({"admin", "services", "shanligong", "post"}, cbi("shanligong"), _("认证设置"), 1)
    entry({"admin", "services", "shanligong", "log"}, cbi("shanligong_log"), _("认证日志"), 2)
    entry({"admin", "services", "shanligong", "status"}, call("act_status")).leaf = true

end

function act_status()
	local e = {}
	e.running = luci.sys.call("ps | grep shanligong | grep -v grep >/dev/null") == 0
	luci.http.prepare_content("application/json")
	luci.http.write_json(e)
end

