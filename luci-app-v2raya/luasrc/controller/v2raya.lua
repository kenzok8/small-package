module("luci.controller.v2raya", package.seeall)

function index()
	if not nixio.fs.access("/etc/config/v2raya") then
		return
	end

	local page = entry({"admin", "services", "v2raya"}, alias("admin", "services", "v2raya", "basic"), _("v2rayA"), 30)
	page.dependent = true
	page.acl_depends = { "luci-app-v2raya" }

	entry({"admin", "services", "v2raya", "basic"}, cbi("v2raya/basic")).leaf = true
	entry({"admin", "services", "v2raya", "log"}, cbi("v2raya/log")).leaf = true
	entry({"admin", "services", "v2raya", "get_log"}, call("get_log")).leaf = true
	entry({"admin", "services", "v2raya", "clear_log"}, call("clear_log")).leaf = true
	entry({"admin", "services", "v2raya", "status"}, call("act_status")).leaf = true
end

function act_status()
	local e = {}
	e.running = luci.sys.call("pgrep -f v2raya >/dev/null") == 0
	luci.http.prepare_content("application/json")
	luci.http.write_json(e)
end

function get_log()
	luci.http.write(luci.sys.exec("[ -f $(uci -q get v2raya.config.log_file) ] && cat $(uci -q get v2raya.config.log_file)"))
end
	
function clear_log()
	luci.sys.call("echo '' > $(uci -q get v2raya.config.log_file)")
end
