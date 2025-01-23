
module("luci.controller.easytier", package.seeall)

function index()
	if not nixio.fs.access("/etc/config/easytier") then
		return
	end
                  
        entry({"admin", "vpn", "easytier"}, alias("admin", "vpn", "easytier", "easytier"),_("EasyTier"), 46).dependent = true
	entry({"admin", "vpn", "easytier", "easytier"}, cbi("easytier"),_("EasyTier"), 47).leaf = true
	entry({"admin", "vpn",  "easytier",  "easytier_log"}, form("easytier_log"),_("日志"), 48).leaf = true
	entry({"admin", "vpn", "easytier", "get_log"}, call("get_log")).leaf = true
	entry({"admin", "vpn", "easytier", "clear_log"}, call("clear_log")).leaf = true
	entry({"admin", "vpn", "easytier", "status"}, call("act_status")).leaf = true
end

function act_status()
	local e = {}
	local sys  = require "luci.sys"
	e.crunning = luci.sys.call("pgrep easytier-core >/dev/null") == 0
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
            log = log .. luci.sys.exec("cat " .. file)
        end
    end
    luci.http.write(log)
end

function clear_log()
	luci.sys.call("echo '' >/tmp/easytier.log")
end




