
module("luci.controller.shadowrt", package.seeall)

function index()
	entry({"admin", "services", "shadowrt"}, alias("admin", "services", "shadowrt", "overview"), _("ShadoWRT"), 21).dependent = true
	entry({"admin", "services", "shadowrt", "overview"}, form("shadowrt/overview"), _("Overview"), 10).dependent = true
	entry({"admin", "services", "shadowrt", "config"}, cbi("shadowrt/config"), _("Install"), 20).dependent = true
	entry({"admin", "services", "shadowrt", "action"}, post("shadowrt_action"))
	entry({"admin", "services", "shadowrt", "ls"}, call("shadowrt_ls"))
end

function shadowrt_action()
	local os   = require "os"
	local rshift  = nixio.bit.rshift
	local action = luci.http.formvalue("action")
	local name = luci.http.formvalue("name")
	local r = 1
	if action == "start" or action == "stop" or action == "restart" or action == "reset_network" or action == "rm" or action == "rmd" or action == "clone" then
		r = os.execute("/usr/libexec/istorec/shadowrt.sh " .. action .. " " .. luci.util.shellquote(name) .. " >/dev/null 2>&1")
		r = rshift(r,8)
	end
	luci.http.prepare_content("application/json")
	luci.http.write_json({ code = r })
end

function shadowrt_ls()
	local util  = require "luci.util"
	local clones = util.trim(util.exec("/usr/libexec/istorec/shadowrt.sh ls"))
	luci.http.prepare_content("application/json")
	luci.http.write("{\n\"code\":200,\n\"clones\":")
	luci.http.write(clones)
	luci.http.write("\n}\n")
end
