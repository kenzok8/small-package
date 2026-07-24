module("luci.controller.pushbot",package.seeall)

function index()
	if not nixio.fs.access("/etc/config/pushbot") then
		return
	end

	entry({"admin", "services", "pushbot"}, cbi("pushbot/setting"), _("全能推送"), 30).dependent = true
	entry({"admin", "services", "pushbot", "get_log"}, call("get_log")).leaf = true
	entry({"admin", "services", "pushbot", "clear_log"}, call("clear_log")).leaf = true
	entry({"admin", "services", "pushbot", "status"}, call("act_status")).leaf = true
	entry({"admin", "services", "pushbot", "client_list"}, call("act_client_list")).leaf = true
	entry({"admin", "services", "pushbot", "send_test"}, call("act_send_test")).leaf = true
	entry({"admin", "services", "pushbot", "soc_test"}, call("act_soc_test")).leaf = true
	entry({"admin", "services", "pushbot", "soc_result"}, call("act_soc_result")).leaf = true
end

function act_soc_test()
	luci.sys.call("/usr/bin/pushbot/pushbot soc")
	luci.http.redirect(luci.dispatcher.build_url("admin","services","pushbot","setting"))
end

function act_soc_result()
	luci.http.write(luci.sys.exec("cat /tmp/pushbot/soc_tmp 2>/dev/null || echo \"无输出\""))
end

function act_send_test()
	luci.sys.call("/usr/bin/pushbot/pushbot test &")
	luci.http.prepare_content("application/json")
	luci.http.write_json({ok=true})
end

function act_status()
	local e={}
	e.running = luci.sys.exec("pgrep -f pushbot/pushbot") ~= ""
	luci.http.prepare_content("application/json")
	luci.http.write_json(e)
end

function act_client_list()
	local clients = {}
	local f = io.open("/tmp/pushbot/ipAddress", "r")
	if f then
		for line in f:lines() do
			line = line:gsub("%s+$", "")
			if line ~= "" then
				local ip, mac, hostname, uptime = line:match("^(%S+)%s+(%S+)%s+(%S+)%s+(%S+)")
				if mac then
					local now = os.time()
					local seconds = tonumber(uptime) and (now - tonumber(uptime)) or 0
					clients[#clients+1] = {
						ip = ip or "",
						mac = mac:upper(),
						hostname = hostname or "",
						uptime = seconds
					}
				end
			end
		end
		f:close()
	end
	luci.http.prepare_content("application/json")
	luci.http.write_json(clients)
end

function get_log()
	local uci = require("luci.model.uci").cursor()
	local debug = uci:get("pushbot", "pushbot", "debuglevel")
	if debug ~= "1" then
		luci.http.write("日志已关闭")
		return
	end
	luci.http.write(luci.sys.exec(
		"[ -f '/tmp/pushbot/pushbot.log' ] && cat /tmp/pushbot/pushbot.log"))
end

function clear_log()
	luci.sys.call("echo '' > /tmp/pushbot/pushbot.log")
end
