module("luci.controller.pushbot",package.seeall)

function index()
	if not nixio.fs.access("/etc/config/pushbot") then return end
	local e = entry
	e({"admin", "services", "pushbot"}, template("pushbot/pushbot_status"), _("全能推送"), 30).dependent = true
	e({"admin", "services", "pushbot", "get_log"}, call("get_log")).leaf = true
	e({"admin", "services", "pushbot", "clear_log"}, call("clear_log")).leaf = true
	e({"admin", "services", "pushbot", "status"}, call("act_status")).leaf = true
	e({"admin", "services", "pushbot", "client_list"}, call("act_client_list")).leaf = true
	e({"admin", "services", "pushbot", "send_test"}, call("act_send_test")).leaf = true
	e({"admin", "services", "pushbot", "send_manual"}, call("act_send_manual")).leaf = true
	e({"admin", "services", "pushbot", "soc_test"}, call("act_soc_test")).leaf = true
	e({"admin", "services", "pushbot", "soc_result"}, call("act_soc_result")).leaf = true
	e({"admin", "services", "pushbot", "get_config"}, call("act_get_config")).leaf = true
	e({"admin", "services", "pushbot", "save_config"}, call("act_save_config")).leaf = true
end

function act_send_manual()
	luci.sys.call("/usr/bin/pushbot/pushbot send &")
	luci.http.prepare_content("application/json"); luci.http.write_json({ok=true})
end

function act_soc_test()
	luci.sys.call("/usr/bin/pushbot/pushbot soc")
	luci.http.redirect(luci.dispatcher.build_url("admin","services","pushbot"))
end

function act_soc_result()
	luci.http.write(luci.sys.exec("cat /tmp/pushbot/soc_tmp 2>/dev/null || echo \"无输出\""))
end

function act_send_test()
	luci.sys.call("/usr/bin/pushbot/pushbot test &")
	luci.http.prepare_content("application/json"); luci.http.write_json({ok=true})
end

function act_status()
	luci.http.prepare_content("application/json")
	luci.http.write_json({running = luci.sys.exec("pgrep -f pushbot/pushbot") ~= ""})
end

function act_client_list()
	local clients = {}
	local f = io.open("/tmp/pushbot/ipAddress", "r")
	if f then
		for l in f:lines() do
			l = l:gsub("%s+$", "")
			if l ~= "" then
				local ip, mac, hn, up = l:match("^(%S+)%s+(%S+)%s+(%S+)%s+(%S+)")
				if mac then
					local n = os.time()
					clients[#clients+1] = {ip=ip or "", mac=mac:upper(), hostname=hn or "", uptime=((tonumber(up) and n - tonumber(up)) or 0)}
				end
			end
		end
		f:close()
	end
	luci.http.prepare_content("application/json"); luci.http.write_json(clients)
end

function get_log()
	local uci = require("luci.model.uci").cursor()
	if uci:get("pushbot", "pushbot", "debuglevel") ~= "1" then luci.http.write("日志已关闭") return end
	luci.http.write(luci.sys.exec("[ -f '/tmp/pushbot/pushbot.log' ] && cat /tmp/pushbot/pushbot.log"))
end

function clear_log()
	luci.sys.call("echo '' > /tmp/pushbot/pushbot.log")
end

function act_get_config()
	local uci = require("luci.model.uci").cursor()
	local fs = require("nixio.fs")
	local sys = require("luci.sys")
	local c, l, f, s = {}, {}, {}, {}

	local scalar_opts = {"pushbot_enable","lite_enable","jsonpath","dd_webhook","we_webhook","pp_token","pp_channel","pp_webhook","pp_topic_enable","pp_topic","pushdeer_key","pushdeer_srv_enable","pushdeer_srv","fs_webhook","bark_token","bark_srv_enable","bark_srv","bark_sound","bark_icon_enable","bark_icon","bark_level","device_name","sleeptime","oui_data","oui_dir","reset_regularly","debuglevel","pushbot_sheep","starttime","endtime","macmechanism","pushbot_interface","macmechanism2","crontab","regular_time","regular_time_2","regular_time_3","interval_time","send_title","router_status","router_temp","router_wan","client_list","google_check_timeout","pushbot_up","pushbot_down","cpuload_enable","cpuload","temperature_enable","temperature","client_usage","client_usage_max","client_usage_disturb","pushbot_ipv4","ipv4_interface","pushbot_ipv6","ipv6_interface","web_logged","ssh_logged","web_login_failed","ssh_login_failed","login_max_num","web_login_black","ip_black_timeout","up_timeout","down_timeout","timeout_retry_count","thread_num","soc_code","pve_host","pve_port","err_enable","err_sheep_enable","network_err_event","system_time_event","autoreboot_time","network_restart_time","public_ip_event","public_ip_retry_count"}
	for _, o in ipairs(scalar_opts) do local v = uci:get("pushbot", "pushbot", o); if v then c[o] = v end end
	local lite_ok, lite_raw = pcall(function() return uci:get_list("pushbot", "pushbot", "lite_enable") end)
	if lite_ok and type(lite_raw) == "table" and #lite_raw > 0 then c["lite_enable"] = lite_raw
	else local lite = uci:get("pushbot", "pushbot", "lite_enable"); if lite then local p = {}; for v in lite:gmatch("%S+") do p[#p+1] = v end; c["lite_enable"] = p end end
	local list_opts = {"device_aliases","pushbot_whitelist","pushbot_blacklist","MAC_online_list","MAC_offline_list","ip_white_list","client_usage_whitelist","err_device_aliases"}
	for _, o in ipairs(list_opts) do
		local t = {}; local ok, raw = pcall(function() return uci:get_list("pushbot", "pushbot", o) end)
		if ok and type(raw) == "table" then for _, v in ipairs(raw) do if v and v ~= "" then t[#t+1] = v end end
		else raw = uci:get("pushbot", "pushbot", o); if raw and raw ~= "" then for v in raw:gmatch("%S+") do t[#t+1] = v end end end
		l[o] = t
	end
	for name, path in pairs({diy_json="/usr/bin/pushbot/api/diy.json", ipv4_list="/usr/bin/pushbot/api/ipv4.list", ipv6_list="/usr/bin/pushbot/api/ipv6.list", ip_black_list="/usr/bin/pushbot/api/ip_blacklist"}) do
		local ok, data = pcall(function() return fs.readfile(path) end); f[name] = (ok and data) or ""
	end
	s.ifaces = {}; local h = io.popen("timeout 3 ls /sys/class/net 2>/dev/null")
	if h then for line in h:lines() do local n = line:gsub("%s+", ""); if n ~= "lo" and not n:match("^ifb") then s.ifaces[#s.ifaces+1] = n end end; h:close() end
	s.ip_hints = {}; local arp = io.popen("timeout 3 grep -E '^[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+' /proc/net/arp 2>/dev/null")
	if arp then for line in arp:lines() do local ip = line:match("^(%d+%.%d+%.%d+%.%d+)"); if ip and ip ~= "0.0.0.0" and ip ~= "127.0.0.1" then s.ip_hints[#s.ip_hints+1] = ip end end; arp:close() end
	s.mac_hints = {}; pcall(function() sys.net.mac_hints(function(mac, name) if mac and mac ~= "" then s.mac_hints[#s.mac_hints+1] = {m = mac, n = name or ""} end end) end)
	luci.http.prepare_content("application/json")
	luci.http.write_json({config = c, lists = l, files = f, system = s})
end

function act_save_config()
	local fs = require("nixio.fs")
	luci.http.prepare_content("application/json")
	local ok, body = pcall(function() return luci.http.content() end)
	if not ok or not body then luci.http.write_json({ok=false, error="no data"}); return end
	local ok, data = pcall(function() return require("luci.jsonc").parse(body) end)
	if not ok or not data then luci.http.write_json({ok=false, error="invalid json"}); return end

	local file_paths = {diy_json="/usr/bin/pushbot/api/diy.json", ipv4_list="/usr/bin/pushbot/api/ipv4.list", ipv6_list="/usr/bin/pushbot/api/ipv6.list", ip_black_list="/usr/bin/pushbot/api/ip_blacklist"}
	local list_opts = {device_aliases=true, pushbot_whitelist=true, pushbot_blacklist=true, MAC_online_list=true, MAC_offline_list=true, ip_white_list=true, client_usage_whitelist=true, err_device_aliases=true}
	local sq = function(s) return "'" .. s:gsub("'", "'\\''") .. "'" end
	local uci_cmd = function(...)
		local c = "/sbin/uci -q"
		for _, a in ipairs({...}) do c = c .. " " .. a end
		os.execute(c)
	end
	for opt, val in pairs(data) do
		if file_paths[opt] then
			if val and type(val) == "string" and val ~= "" then fs.writefile(file_paths[opt], val:gsub("\r\n", "\n"))
			else fs.writefile(file_paths[opt], "") end
		elseif list_opts[opt] then
			uci_cmd("delete", "pushbot.pushbot." .. sq(opt))
			local function add(v) if v ~= "" then uci_cmd("add_list", "pushbot.pushbot." .. sq(opt) .. "=" .. sq(v)) end end
			if type(val) == "table" then for _, v in ipairs(val) do add(v) end else add(val) end
		else
			if val == nil or val == "" then uci_cmd("delete", "pushbot.pushbot." .. sq(opt))
			elseif type(val) == "table" then
				local p = {}; for _, v in ipairs(val) do if v ~= "" then p[#p+1] = v end end
				if #p > 0 then uci_cmd("delete", "pushbot.pushbot." .. sq(opt)); uci_cmd("set", "pushbot.pushbot." .. sq(opt) .. "=" .. sq(table.concat(p, " "))) end
			else uci_cmd("delete", "pushbot.pushbot." .. sq(opt)); uci_cmd("set", "pushbot.pushbot." .. sq(opt) .. "=" .. sq(val)) end
		end
	end
	uci_cmd("commit", "pushbot")
	luci.http.write_json({ok=true})
end
