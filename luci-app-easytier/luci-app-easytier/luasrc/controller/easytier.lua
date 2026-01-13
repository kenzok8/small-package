
module("luci.controller.easytier", package.seeall)

function index()
	if not nixio.fs.access("/etc/config/easytier") then
		return
	end
                  
        entry({"admin", "vpn", "easytier"}, alias("admin", "vpn", "easytier", "easytier"),_("EasyTier"), 46).dependent = true
	entry({"admin", "vpn", "easytier", "easytier"}, cbi("easytier"),_("EasyTier"), 47).leaf = true
	entry({"admin", "vpn",  "easytier",  "easytier_log"}, form("easytier_log"),_("core log"), 48).leaf = true
	entry({"admin", "vpn", "easytier", "get_log"}, call("get_log")).leaf = true
	entry({"admin", "vpn", "easytier", "clear_log"}, call("clear_log")).leaf = true
	entry({"admin", "vpn",  "easytier",  "easytierweb_log"}, form("easytierweb_log"),_("web log"), 49).leaf = true
	entry({"admin", "vpn", "easytier", "get_wlog"}, call("get_wlog")).leaf = true
	entry({"admin", "vpn", "easytier", "clear_wlog"}, call("clear_wlog")).leaf = true
	entry({"admin", "vpn", "easytier", "status"}, call("act_status")).leaf = true
	entry({"admin", "vpn", "easytier", "conninfo"}, call("act_conninfo")).leaf = true
end

function act_status()
	local e = {}
	local sys  = require "luci.sys"
	local uci  = require "luci.model.uci".cursor()
	local port = tonumber(uci:get_first("easytier", "easytier", "web_html_port"))
	e.crunning = luci.sys.call("pgrep easytier-core >/dev/null") == 0
	e.wrunning = luci.sys.call("pgrep easytier-web >/dev/null") == 0
	e.port = (port or 0)
	
	local tagfile = io.open("/tmp/easytier_time", "r")
        if tagfile then
		local tagcontent = tagfile:read("*all")
		tagfile:close()
		if tagcontent and tagcontent ~= "" then
        		os.execute("start_time=$(cat /tmp/easytier_time) && time=$(($(date +%s)-start_time)) && day=$((time/86400)) && [ $day -eq 0 ] && day='' || day=${day}天 && time=$(date -u -d @${time} +'%H小时%M分%S秒') && echo $day $time > /tmp/command_easytier 2>&1")
        		local command_output_file = io.open("/tmp/command_easytier", "r")
        		if command_output_file then
            			e.etsta = command_output_file:read("*all")
            			command_output_file:close()
        		end
		end
	end
	
        local command2 = io.popen('test ! -z "`pidof easytier-core`" && (top -b -n1 | grep -E "$(pidof easytier-core)" 2>/dev/null | grep -v grep | awk \'{for (i=1;i<=NF;i++) {if ($i ~ /easytier-core/) break; else cpu=i}} END {print $cpu}\')')
	e.etcpu = command2:read("*all")
	command2:close()
	
        local command3 = io.popen("test ! -z `pidof easytier-core` && (cat /proc/$(pidof easytier-core | awk '{print $NF}')/status | grep -w VmRSS | awk '{printf \"%.2f MB\", $2/1024}')")
	e.etram = command3:read("*all")
	command3:close()

	local wtagfile = io.open("/tmp/easytierweb_time", "r")
        if wtagfile then
		local wtagcontent = wtagfile:read("*all")
		wtagfile:close()
		if wtagcontent and wtagcontent ~= "" then
        		os.execute("start_time=$(cat /tmp/easytierweb_time) && time=$(($(date +%s)-start_time)) && day=$((time/86400)) && [ $day -eq 0 ] && day='' || day=${day}天 && time=$(date -u -d @${time} +'%H小时%M分%S秒') && echo $day $time > /tmp/command_easytierweb 2>&1")
        		local wcommand_output_file = io.open("/tmp/command_easytierweb", "r")
        		if wcommand_output_file then
            			e.etwebsta = wcommand_output_file:read("*all")
            			wcommand_output_file:close()
        		end
		end
	end

	local command4 = io.popen('test ! -z "`pidof easytier-web`" && (top -b -n1 | grep -E "$(pidof easytier-web)" 2>/dev/null | grep -v grep | awk \'{for (i=1;i<=NF;i++) {if ($i ~ /easytier-web/) break; else cpu=i}} END {print $cpu}\')')
	e.etwebcpu = command4:read("*all")
	command4:close()
	
        local command5 = io.popen("test ! -z `pidof easytier-web` && (cat /proc/$(pidof easytier-web | awk '{print $NF}')/status | grep -w VmRSS | awk '{printf \"%.2f MB\", $2/1024}')")
	e.etwebram = command5:read("*all")
	command5:close()
	
        local command8 = io.popen("([ -s /tmp/easytiernew.tag ] && cat /tmp/easytiernew.tag ) || ( curl -L -k -s --connect-timeout 3 --user-agent 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/117.0.0.0 Safari/537.36' https://api.github.com/repos/EasyTier/EasyTier/releases/latest | grep tag_name | sed 's/[^0-9.]*//g' >/tmp/easytiernew.tag && cat /tmp/easytiernew.tag )")
	e.etnewtag = command8:read("*all")
	command8:close()
	
        local command9 = io.popen("([ -s /tmp/easytier.tag ] && cat /tmp/easytier.tag ) || ( echo `$(uci -q get easytier.@easytier[0].easytierbin) -V | sed 's/^[^0-9]*//'` > /tmp/easytier.tag && cat /tmp/easytier.tag && [ ! -s /tmp/easytier.tag ] && echo '？' >> /tmp/easytier.tag && cat /tmp/easytier.tag )")
	e.ettag = command9:read("*all")
	command9:close()

	luci.http.prepare_content("application/json")
	luci.http.write_json(e)
end

function get_log()
    local log = ""
    local files = {"/tmp/easytier.log"}
    for i, file in ipairs(files) do
        if luci.sys.call("[ -f '" .. file .. "' ]") == 0 then
            log = log .. luci.sys.exec("sed 's/\\x1b\\[[0-9;]*m//g' " .. file)
        end
    end
    luci.http.write(log)
end

function clear_log()
	luci.sys.call("echo '' >/tmp/easytier.log")
end

function get_wlog()
    local log = ""
    local files = {"/tmp/easytierweb.log"}
    for i, file in ipairs(files) do
        if luci.sys.call("[ -f '" .. file .. "' ]") == 0 then
            log = log .. luci.sys.exec("sed 's/\\x1b\\[[0-9;]*m//g' " .. file)
        end
    end
    luci.http.write(log)
end

function clear_wlog()
	luci.sys.call("echo '' >/tmp/easytierweb.log")
end

function act_conninfo()
	local e = {}
	local uci = require "luci.model.uci".cursor()
	local easytierbin = uci:get_first("easytier", "easytier", "easytierbin") or "/usr/bin/easytier-core"
	local clibin = easytierbin:gsub("easytier%-core$", "easytier-cli")
	
	local process_status = luci.sys.exec("pgrep easytier-core")
	
	if process_status ~= "" then
		-- 获取各类CLI信息
		local function get_cli_output(cmd)
			local handle = io.popen(clibin .. " " .. cmd .. " 2>&1")
			if handle then
				local result = handle:read("*all")
				handle:close()
				return result or ""
			end
			return ""
		end
		
		e.node = get_cli_output("node")
		e.peer = get_cli_output("peer")
		e.connector = get_cli_output("connector")
		e.stun = get_cli_output("stun")
		e.route = get_cli_output("route")
		e.peer_center = get_cli_output("peer-center")
		e.vpn_portal = get_cli_output("vpn-portal")
		e.proxy = get_cli_output("proxy")
		e.acl = get_cli_output("acl stats")
		e.mapped_listener = get_cli_output("mapped-listener")
		e.stats = get_cli_output("stats")
		
		-- 获取启动参数
		local cmdhandle = io.popen("cat /proc/$(pidof easytier-core)/cmdline 2>/dev/null | tr '\\0' ' '")
		if cmdhandle then
			e.cmdline = cmdhandle:read("*all") or ""
			cmdhandle:close()
		else
			e.cmdline = ""
		end
	else
		local errMsg = "错误：程序未运行！请启动程序后刷新"
		e.node = errMsg
		e.peer = errMsg
		e.connector = errMsg
		e.stun = errMsg
		e.route = errMsg
		e.peer_center = errMsg
		e.vpn_portal = errMsg
		e.proxy = errMsg
		e.acl = errMsg
		e.mapped_listener = errMsg
		e.stats = errMsg
		e.cmdline = errMsg
	end
	
	luci.http.prepare_content("application/json")
	luci.http.write_json(e)
end
