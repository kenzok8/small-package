
module("luci.controller.easytier", package.seeall)
local i18n = require "luci.i18n"

-- 安全执行命令并返回结果
local function safe_exec(cmd)
    local handle = io.popen(cmd)
    if not handle then return "" end
    local result = handle:read("*all") or ""
    handle:close()
    return result:gsub("[\r\n]+$", "")
end

-- 安全读取文件内容
local function safe_read_file(path)
    local file = io.open(path, "r")
    if not file then return nil end
    local content = file:read("*all")
    file:close()
    return content
end

-- 计算运行时长
local function calc_uptime(start_time_file)
    local content = safe_read_file(start_time_file)
    if not content or content == "" then return "" end
    
    local start_time = tonumber(content:match("%d+"))
    if not start_time then return "" end
    
    local now = os.time()
    local elapsed = now - start_time
    
    local days = math.floor(elapsed / 86400)
    local hours = math.floor((elapsed % 86400) / 3600)
    local mins = math.floor((elapsed % 3600) / 60)
    local secs = elapsed % 60
    
    local result = ""
    if days > 0 then result = days .. "天 " end
    result = result .. string.format("%02d小时%02d分%02d秒", hours, mins, secs)
    return result
end

function index()
	if not nixio.fs.access("/etc/config/easytier") then
		return
	end
	
	entry({"admin", "vpn"}, firstchild(), "VPN", 45).dependent = false
	entry({"admin", "vpn", "easytier"}, firstchild(),_("EasyTier"), 46).dependent = true
	entry({"admin", "vpn", "easytier", "status"}, cbi("easytier_status"),_("Status"), 1).leaf = true
	entry({"admin", "vpn", "easytier", "config"}, cbi("easytier"),_("EasyTier Core"), 2).leaf = true
	entry({"admin", "vpn", "easytier", "webconsole"}, template("easytier/easytier_web"),_("EasyTier Web"), 3).leaf = true
	entry({"admin", "vpn", "easytier", "log"}, template("easytier/easytier_log"),_("Logs"), 4).leaf = true
	entry({"admin", "vpn", "easytier", "upload"}, template("easytier/easytier_upload"),_("Upload Program"), 5).leaf = true
	entry({"admin", "vpn", "easytier", "upload_binary"}, call("upload_binary")).leaf = true
	entry({"admin", "vpn", "easytier", "get_upload_config"}, call("get_upload_config")).leaf = true
	entry({"admin", "vpn", "easytier", "save_upload_config"}, call("save_upload_config")).leaf = true
	entry({"admin", "vpn", "easytier", "get_disk_space"}, call("get_disk_space")).leaf = true
	entry({"admin", "vpn", "easytier", "get_tun_info"}, call("get_tun_info")).leaf = true
	entry({"admin", "vpn", "easytier", "get_log"}, call("get_log")).leaf = true
	entry({"admin", "vpn", "easytier", "get_log_size"}, call("get_log_size")).leaf = true
	entry({"admin", "vpn", "easytier", "clear_log"}, call("clear_log")).leaf = true
	entry({"admin", "vpn", "easytier", "get_wlog"}, call("get_wlog")).leaf = true
	entry({"admin", "vpn", "easytier", "get_wlog_size"}, call("get_wlog_size")).leaf = true
	entry({"admin", "vpn", "easytier", "clear_wlog"}, call("clear_wlog")).leaf = true
	entry({"admin", "vpn", "easytier", "clear_version_cache"}, call("clear_version_cache")).leaf = true
	entry({"admin", "vpn", "easytier", "get_web_config"}, call("get_web_config")).leaf = true
	entry({"admin", "vpn", "easytier", "save_web_config"}, call("save_web_config")).leaf = true
	entry({"admin", "vpn", "easytier", "reset_database"}, call("reset_database")).leaf = true
	entry({"admin", "vpn", "easytier", "check_web_status"}, call("check_web_status")).leaf = true
	entry({"admin", "vpn", "easytier", "api_status"}, call("act_status")).leaf = true
	entry({"admin", "vpn", "easytier", "api_conninfo"}, call("act_conninfo")).leaf = true
	entry({"admin", "vpn", "easytier", "restart_service"}, call("restart_service")).leaf = true
	entry({"admin", "vpn", "easytier", "toggle_core"}, call("toggle_core")).leaf = true
	entry({"admin", "vpn", "easytier", "toggle_web"}, call("toggle_web")).leaf = true
	entry({"admin", "vpn", "easytier", "download_easytier"}, call("download_easytier")).leaf = true
	entry({"admin", "vpn", "easytier", "download_progress"}, call("download_progress")).leaf = true
	entry({"admin", "vpn", "easytier", "cancel_download"}, call("cancel_download")).leaf = true
end

function act_status()
	local e = {}
	local sys  = require "luci.sys"
	local uci  = require "luci.model.uci".cursor()
	local port = tonumber(uci:get_first("easytier", "easytier", "web_html_port"))
	e.crunning = luci.sys.call("pgrep easytier-core >/dev/null") == 0
	e.wrunning = luci.sys.call("pgrep easytier-web >/dev/null") == 0
	e.port = (port or 0)
	e.cenabled = uci:get_first("easytier", "easytier", "enabled") == "1"
	e.wenabled = uci:get_first("easytier", "easytier", "web_enabled") == "1"
	
	-- 使用 Lua 原生计算运行时长
	e.etsta = calc_uptime("/tmp/easytier_time")
	e.etwebsta = calc_uptime("/tmp/easytierweb_time")
	
	-- 获取 CPU 和内存使用率（使用原始命令）
	local command2 = io.popen('test ! -z "`pidof easytier-core`" && (top -b -n1 | grep -E "$(pidof easytier-core)" 2>/dev/null | grep -v grep | awk \'{for (i=1;i<=NF;i++) {if ($i ~ /easytier-core/) break; else cpu=i}} END {print $cpu}\')')
	e.etcpu = command2:read("*all")
	command2:close()
	
	local command3 = io.popen("test ! -z `pidof easytier-core` && (cat /proc/$(pidof easytier-core | awk '{print $NF}')/status | grep -w VmRSS | awk '{printf \"%.2f MB\", $2/1024}')")
	e.etram = command3:read("*all")
	command3:close()
	
	local command4 = io.popen('test ! -z "`pidof easytier-web`" && (top -b -n1 | grep -E "$(pidof easytier-web)" 2>/dev/null | grep -v grep | awk \'{for (i=1;i<=NF;i++) {if ($i ~ /easytier-web/) break; else cpu=i}} END {print $cpu}\')')
	e.etwebcpu = command4:read("*all")
	command4:close()
	
	local command5 = io.popen("test ! -z `pidof easytier-web` && (cat /proc/$(pidof easytier-web | awk '{print $NF}')/status | grep -w VmRSS | awk '{printf \"%.2f MB\", $2/1024}')")
	e.etwebram = command5:read("*all")
	command5:close()
	
	-- 获取版本信息
	local cached_newtag = safe_read_file("/tmp/easytiernew.tag")
	if cached_newtag and cached_newtag ~= "" then
		e.etnewtag = cached_newtag:gsub("[\r\n]+", "")
	else
		e.etnewtag = safe_exec("curl -L -k -s --connect-timeout 3 --user-agent 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/117.0.0.0 Safari/537.36' https://api.github.com/repos/EasyTier/EasyTier/releases/latest | grep tag_name | sed 's/[^0-9.]*//g'")
		if e.etnewtag ~= "" then
			local f = io.open("/tmp/easytiernew.tag", "w")
			if f then f:write(e.etnewtag); f:close() end
		end
	end
	
	local cached_tag = safe_read_file("/tmp/easytier.tag")
	if cached_tag and cached_tag ~= "" then
		e.ettag = cached_tag:gsub("[\r\n]+", "")
	else
		local easytierbin = uci:get_first("easytier", "easytier", "easytierbin") or "/usr/bin/easytier-core"
		e.ettag = safe_exec(easytierbin .. " -V 2>/dev/null | sed 's/^[^0-9]*//'")
		if e.ettag == "" or e.ettag == nil then e.ettag = "unknown" end
		local f = io.open("/tmp/easytier.tag", "w")
		if f then f:write(e.ettag); f:close() end
	end
	
	local cached_webtag = safe_read_file("/tmp/easytierweb.tag")
	if cached_webtag and cached_webtag ~= "" then
		e.etwebtag = cached_webtag:gsub("[\r\n]+", "")
	else
		local easytierwebbin = uci:get_first("easytier", "easytier", "webbin") or "/usr/bin/easytier-web"
		e.etwebtag = safe_exec(easytierwebbin .. " -V 2>/dev/null | sed 's/^[^0-9]*//'")
		if e.etwebtag == "" or e.etwebtag == nil then e.etwebtag = "unknown" end
		local f = io.open("/tmp/easytierweb.tag", "w")
		if f then f:write(e.etwebtag); f:close() end
	end
	
	e.no_tun = uci:get_first("easytier", "easytier", "no_tun") == "1"
	e.dev_name = uci:get_first("easytier", "easytier", "dev_name") or "tun0"

	luci.http.prepare_content("application/json")
	luci.http.write_json(e)
end

function get_upload_config()
	local uci = require "luci.model.uci".cursor()
	local http = require "luci.http"
	
	http.prepare_content("application/json")
	
	local config = {
		easytierbin = uci:get_first("easytier", "easytier", "easytierbin") or "/usr/bin/easytier-core",
		webbin = uci:get_first("easytier", "easytier", "webbin") or "/usr/bin/easytier-web",
		github_proxys = {},
		fallback_version = uci:get_first("easytier", "easytier", "fallback_version") or "v2.6.4"
	}
	
	-- 读取代理列表（list 类型）
	uci:foreach("easytier", "easytier", function(s)
		local proxys = s.github_proxys
		if proxys then
			if type(proxys) == "table" then
				config.github_proxys = proxys
			else
				table.insert(config.github_proxys, proxys)
			end
		end
	end)
	
	http.write_json(config)
end

function save_upload_config()
	local uci = require "luci.model.uci".cursor()
	local http = require "luci.http"
	local json = require "luci.jsonc"
	
	http.prepare_content("application/json")
	
	-- 读取 POST 数据
	local content = http.content()
	local data = json.parse(content)
	
	if not data then
		http.write_json({success = false, message = "Invalid JSON data"})
		return
	end
	
	-- 保存配置
	uci:set("easytier", "@easytier[0]", "easytierbin", data.easytierbin or "/usr/bin/easytier-core")
	uci:set("easytier", "@easytier[0]", "webbin", data.webbin or "/usr/bin/easytier-web")
	uci:set("easytier", "@easytier[0]", "fallback_version", data.fallback_version or "v2.6.4")
	
	-- 删除旧的代理列表
	uci:delete("easytier", "@easytier[0]", "github_proxys")
	
	-- 保存代理列表（list 类型）
	if data.github_proxys and type(data.github_proxys) == "table" then
		for _, proxy in ipairs(data.github_proxys) do
			if proxy and proxy ~= "" then
				local current = uci:get("easytier", "@easytier[0]", "github_proxys") or {}
				if type(current) ~= "table" then
					current = {current}
				end
				table.insert(current, proxy)
				uci:set("easytier", "@easytier[0]", "github_proxys", current)
			end
		end
	end
	
	uci:commit("easytier")
	
	http.write_json({success = true, message = "Configuration saved successfully"})
end

function get_disk_space()
	local http = require "luci.http"
	local json = require "luci.jsonc"
	local nixio = require "nixio"
	
	http.prepare_content("application/json")
	
	local content = http.content()
	local data = json.parse(content)
	
	if not data or not data.path then
		http.write_json({success = false, message = "Invalid path"})
		return
	end
	
	local path = data.path
	local full_path = data.full_path
	local input_type = data.type
	
	local df_output = luci.sys.exec("df -h '" .. path .. "' 2>/dev/null | tail -n 1")
	local df_kb = luci.sys.exec("df -k '" .. path .. "' 2>/dev/null | tail -n 1")
	
	if df_output and df_output ~= "" and df_kb and df_kb ~= "" then
		local available = df_output:match("%S+%s+%S+%s+%S+%s+(%S+)")
		local available_kb = df_kb:match("%S+%s+%S+%s+%S+%s+(%d+)")
		local available_mb = available_kb and math.floor(tonumber(available_kb) / 1024) or 0
		
		if available and available_mb then
			local result = {
				success = true,
				available = available,
				available_mb = available_mb
			}
			
			if input_type == "easytierbin" and full_path then
				if nixio.fs.access(full_path) then
					local size = luci.sys.exec("ls -lh '" .. full_path .. "' 2>/dev/null | awk '{print $5}'")
					if size and size ~= "" then
						result.core_size = size:gsub("[\r\n]+$", "")
					end
				end
				
				local dir = full_path:match("(.*/)")
				local cli_path = (dir or "/usr/bin/") .. "easytier-cli"
				if nixio.fs.access(cli_path) then
					local size = luci.sys.exec("ls -lh '" .. cli_path .. "' 2>/dev/null | awk '{print $5}'")
					if size and size ~= "" then
						result.cli_size = size:gsub("[\r\n]+$", "")
					end
				end
			elseif input_type == "webbin" and full_path then
				if nixio.fs.access(full_path) then
					local size = luci.sys.exec("ls -lh '" .. full_path .. "' 2>/dev/null | awk '{print $5}'")
					if size and size ~= "" then
						result.web_size = size:gsub("[\r\n]+$", "")
					end
				end
			end
			
			http.write_json(result)
			return
		end
	end
	
	http.write_json({success = false, message = "Unable to query disk space"})
end

function get_tun_info()
	luci.http.prepare_content("application/json")
	
	local ifname = luci.http.formvalue("ifname") or "tun0"
	
	local exists = luci.sys.exec("ip link show " .. ifname .. " >/dev/null 2>&1 && echo 1 || echo 0")
	if not exists:match("1") then
		luci.http.write('{"success":false,"exists":false}')
		return
	end
	
	local ifconfig_out = luci.sys.exec("ifconfig " .. ifname .. " 2>/dev/null")
	
	local ip = ifconfig_out:match("inet addr:([%d%.]+)") or ifconfig_out:match("inet ([%d%.]+)")
	
	local netmask = ""
	local netmask_full = ifconfig_out:match("Mask:([%d%.]+)") or ifconfig_out:match("netmask ([%d%.]+)")
	
	if not netmask_full or netmask_full == "" then
		local ip_output = luci.sys.exec("ip -4 addr show " .. ifname .. " 2>/dev/null | grep 'inet ' | head -n1 | awk '{print $2}'")
		local cidr = ip_output:match("/(%d+)")
		if cidr then
			cidr = tonumber(cidr)
			local mask = 0xFFFFFFFF - (2 ^ (32 - cidr) - 1)
			netmask = string.format("%d.%d.%d.%d",
				math.floor(mask / 16777216) % 256,
				math.floor(mask / 65536) % 256,
				math.floor(mask / 256) % 256,
				mask % 256)
		end
	else
		netmask = netmask_full
	end
	
	local ipv6_cmd = luci.sys.exec("ip -6 addr show " .. ifname .. " 2>/dev/null | grep 'inet6' | head -n1 | awk '{print $2}'")
	local ipv6 = ipv6_cmd:gsub("%s", "")
	if ipv6 == "" then ipv6 = nil end
	
	local mtu = ifconfig_out:match("MTU:(%d+)") or luci.sys.exec("ip link show " .. ifname .. " 2>/dev/null | head -n1 | sed -n 's/.*mtu \\([0-9]*\\).*/\\1/p'"):gsub("%s", "")
	
	local state = "UNKNOWN"
	if ifconfig_out:match("UP") then
		state = "UP"
	elseif ifconfig_out:match("DOWN") then
		state = "DOWN"
	end
	
	local rx = luci.sys.exec("cat /sys/class/net/" .. ifname .. "/statistics/rx_bytes 2>/dev/null || echo 0"):gsub("%s", "")
	local tx = luci.sys.exec("cat /sys/class/net/" .. ifname .. "/statistics/tx_bytes 2>/dev/null || echo 0"):gsub("%s", "")
	
	local response = string.format('{"success":true,"exists":true,"ip":"%s","netmask":"%s","mtu":"%s","state":"%s","rx_bytes":%s,"tx_bytes":%s',
		ip or "", netmask, mtu, state, rx, tx)
	
	if ipv6 then
		response = response .. ',"ipv6":"' .. ipv6 .. '"'
	end
	
	response = response .. '}'
	
	luci.http.write(response)
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

function get_log_size()
    local size = luci.sys.exec("[ -f '/tmp/easytier.log' ] && stat -c%s /tmp/easytier.log 2>/dev/null || echo 0")
    luci.http.prepare_content("application/json")
    luci.http.write_json({size = tonumber(size) or 0})
end

function get_wlog_size()
    local size = luci.sys.exec("[ -f '/tmp/easytierweb.log' ] && stat -c%s /tmp/easytierweb.log 2>/dev/null || echo 0")
    luci.http.prepare_content("application/json")
    luci.http.write_json({size = tonumber(size) or 0})
end

function clear_log()
	luci.sys.call("echo '' >/tmp/easytier.log")
end

local function test_binary(path)
	local handle = io.popen(path .. " -h 2>&1")
	local output = handle:read("*a")
	handle:close()
	
	local line_count = 0
	for _ in output:gmatch("[^\r\n]+") do
		line_count = line_count + 1
	end
	
	return line_count >= 3 and output:lower():match("easytier")
end

local function cleanup_files(...)
	for _, file in ipairs({...}) do
		nixio.fs.remove(file)
	end
end

function upload_binary()
	local http = require "luci.http"
	local uci = require "luci.model.uci".cursor()
	local nixio = require "nixio"
	local translate = i18n.translate
	
	local fp
	local filename = ""
	local tmp_file = ""
	
	http.setfilehandler(
		function(meta, chunk, eof)
			if meta and meta.file then
				filename = meta.file
				tmp_file = "/tmp/upload_" .. filename
			end
			if not fp and tmp_file ~= "" then
				fp = io.open(tmp_file, "w")
			end
			if chunk and fp then
				fp:write(chunk)
			end
			if eof and fp then
				fp:close()
			end
		end
	)
	
	http.prepare_content("application/json")
	
	if not http.formvalue("file") or tmp_file == "" then
		http.write_json({success = false, message = translate("No file uploaded")})
		return
	end
	
	local is_archive = filename:match("%.zip$") or filename:match("%.tar%.gz$") or filename:match("%.tgz$") or filename:match("%.tar$")
	
	if is_archive then
		local extract_dir = "/tmp/easytier_extract"
		os.execute("rm -rf " .. extract_dir .. " && mkdir -p " .. extract_dir)
		
		if filename:match("%.zip$") then
			if os.execute("which unzip >/dev/null 2>&1") ~= 0 then
				cleanup_files(tmp_file)
				http.write_json({success = false, message = translate("System lacks unzip package, cannot extract zip archive")})
				return
			end
			os.execute("unzip -o -q " .. tmp_file .. " -d " .. extract_dir)
		else
			os.execute("tar -xzf " .. tmp_file .. " -C " .. extract_dir .. " 2>/dev/null || tar -xf " .. tmp_file .. " -C " .. extract_dir)
		end
		
		os.execute("find " .. extract_dir .. "/easytier-linux-* -maxdepth 1 -type f -exec mv {} " .. extract_dir .. "/ \\; 2>/dev/null")
		cleanup_files(tmp_file)
		
		if nixio.fs.access(extract_dir .. "/easytier-web") then
			nixio.fs.remove(extract_dir .. "/easytier-web")
		end
		
		local binaries = {"easytier-core", "easytier-cli", "easytier-web-embed"}
		local valid_bins = {}
		
		for _, bin in ipairs(binaries) do
			local src = extract_dir .. "/" .. bin
			if nixio.fs.access(src) then
				nixio.fs.chmod(src, "755")
				if test_binary(src) then
					table.insert(valid_bins, {name = bin, path = src})
				else
					cleanup_files(src)
				end
			end
		end
		
		if #valid_bins == 0 then
			os.execute("rm -rf " .. extract_dir)
			http.write_json({success = false, message = translate("Not a valid EasyTier program or architecture mismatch")})
			return
		end
		
		local core_path = uci:get_first("easytier", "easytier", "easytierbin") or "/usr/bin/easytier-core"
		local web_path = uci:get_first("easytier", "easytier", "webbin") or "/usr/bin/easytier-web"
		
		for _, bin in ipairs(valid_bins) do
			local final_path
			if bin.name == "easytier-web-embed" then
				final_path = web_path
			elseif bin.name == "easytier-core" then
				final_path = core_path
			elseif bin.name == "easytier-cli" then
				local core_dir = core_path:match("(.*/)")
				final_path = (core_dir or "/usr/bin/") .. "easytier-cli"
			end
			
			os.execute("rm -f " .. final_path)
			
			if os.execute("mv " .. bin.path .. " " .. final_path) ~= 0 then
				os.execute("rm -rf " .. extract_dir)
				http.write_json({success = false, message = translate("Failed to move file. Insufficient space or permission denied")})
				return
			end
			
			os.execute("chmod 755 " .. final_path)
			if not test_binary(final_path) then
				os.execute("rm -f " .. final_path)
				os.execute("rm -rf " .. extract_dir)
				http.write_json({success = false, message = translate("Not a valid EasyTier program or architecture mismatch")})
				return
			end
		end
		
		os.execute("rm -rf " .. extract_dir)
		nixio.fs.remove("/tmp/easytier.tag")
		nixio.fs.remove("/tmp/easytierweb.tag")
		http.write_json({success = true, message = translate("Successfully installed") .. " " .. #valid_bins .. " " .. translate("binary file(s)")})
	else
		local valid_names = {["easytier-core"] = true, ["easytier-cli"] = true, ["easytier-web-embed"] = true, ["easytier-web"] = true}
		
		if not valid_names[filename] then
			cleanup_files(tmp_file)
			http.write_json({success = false, message = translate("Not a valid EasyTier program")})
			return
		end
		
		if filename == "easytier-web" then
			cleanup_files(tmp_file)
			http.write_json({success = false, message = translate("easytier-web is not used by this plugin, please upload easytier-web-embed")})
			return
		end
		
		nixio.fs.chmod(tmp_file, "755")
		if not test_binary(tmp_file) then
			cleanup_files(tmp_file)
			http.write_json({success = false, message = translate("Not a valid EasyTier program or architecture mismatch")})
			return
		end
		
		local core_path = uci:get_first("easytier", "easytier", "easytierbin") or "/usr/bin/easytier-core"
		local web_path = uci:get_first("easytier", "easytier", "webbin") or "/usr/bin/easytier-web"
		
		local final_path
		if filename == "easytier-web-embed" then
			final_path = web_path
		elseif filename == "easytier-core" then
			final_path = core_path
		elseif filename == "easytier-cli" then
			local core_dir = core_path:match("(.*/)")
			final_path = (core_dir or "/usr/bin/") .. "easytier-cli"
		end
		
		os.execute("rm -f " .. final_path)
		
		if os.execute("mv " .. tmp_file .. " " .. final_path) ~= 0 then
			cleanup_files(tmp_file)
			http.write_json({success = false, message = translate("Failed to move file. Insufficient space or permission denied")})
			return
		end
		
		os.execute("chmod 755 " .. final_path)
		if not test_binary(final_path) then
			os.execute("rm -f " .. final_path)
			http.write_json({success = false, message = translate("Not a valid EasyTier program or architecture mismatch")})
			return
		end
		
		nixio.fs.remove("/tmp/easytier.tag")
		nixio.fs.remove("/tmp/easytierweb.tag")
		http.write_json({success = true, message = translate("Binary uploaded successfully to") .. " " .. final_path})
	end
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

function clear_version_cache()
	local type = luci.http.formvalue("type")
	if type == "core" then
		luci.sys.call("rm -f /tmp/easytiernew.tag /tmp/easytier.tag")
	elseif type == "web" then
		luci.sys.call("rm -f /tmp/easytiernew.tag /tmp/easytierweb.tag")
	end
	luci.http.write("OK")
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
		
		-- 检查是否使用配置文件启动
		if e.cmdline:match("%-%-config%-file") or e.cmdline:match("%-c%s+/") then
			e.config_file = safe_read_file("/etc/easytier/config.toml") or ""
		else
			e.config_file = ""
		end
	else
		local errMsg = i18n.translate("Error: Program not running! Please start the program and refresh")
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


function get_web_config()
	luci.http.prepare_content("application/json")
	local uci = require "luci.model.uci".cursor()
	
	local config = {
		web_enabled = uci:get_first("easytier", "easytier", "web_enabled") or "0",
		web_db_path = uci:get_first("easytier", "easytier", "web_db_path") or "/etc/easytier/et.db",
		web_protocol = uci:get_first("easytier", "easytier", "web_protocol") or "udp",
		web_port = uci:get_first("easytier", "easytier", "web_port") or "22020",
		web_fw_web = uci:get_first("easytier", "easytier", "web_fw_web") or "0",
		web_api_port = uci:get_first("easytier", "easytier", "web_api_port") or "11211",
		web_html_port = uci:get_first("easytier", "easytier", "web_html_port") or "11211",
		web_api_addr = uci:get_first("easytier", "easytier", "web_api_addr") or "0.0.0.0",
		web_html_addr = uci:get_first("easytier", "easytier", "web_html_addr") or "0.0.0.0",
		web_fw_api = uci:get_first("easytier", "easytier", "web_fw_api") or "0",
		web_api_host = uci:get_first("easytier", "easytier", "web_api_host") or "",
		web_geoip_db = uci:get_first("easytier", "easytier", "web_geoip_db") or "",
		web_disable_registration = uci:get_first("easytier", "easytier", "web_disable_registration") or "0",
		web_allow_auto_create_user = uci:get_first("easytier", "easytier", "web_allow_auto_create_user") or "0",
		web_weblog = uci:get_first("easytier", "easytier", "web_weblog") or "off",
		-- OIDC配置
		web_oidc_enabled = uci:get_first("easytier", "easytier", "web_oidc_enabled") or "0",
		web_oidc_issuer_url = uci:get_first("easytier", "easytier", "web_oidc_issuer_url") or "",
		web_oidc_client_id = uci:get_first("easytier", "easytier", "web_oidc_client_id") or "",
		web_oidc_client_secret = uci:get_first("easytier", "easytier", "web_oidc_client_secret") or "",
		web_oidc_redirect_url = uci:get_first("easytier", "easytier", "web_oidc_redirect_url") or "",
		web_oidc_username_claim = uci:get_first("easytier", "easytier", "web_oidc_username_claim") or "preferred_username",
		web_oidc_scopes = uci:get_first("easytier", "easytier", "web_oidc_scopes") or "openid profile",
		web_oidc_frontend_base_url = uci:get_first("easytier", "easytier", "web_oidc_frontend_base_url") or "",
		web_oidc_disable_pkce = uci:get_first("easytier", "easytier", "web_oidc_disable_pkce") or "0",
		-- Webhook配置
		web_webhook_enabled = uci:get_first("easytier", "easytier", "web_webhook_enabled") or "0",
		web_webhook_url = uci:get_first("easytier", "easytier", "web_webhook_url") or "",
		web_webhook_secret = uci:get_first("easytier", "easytier", "web_webhook_secret") or "",
		web_internal_auth_token = uci:get_first("easytier", "easytier", "web_internal_auth_token") or "",
		web_web_instance_id = uci:get_first("easytier", "easytier", "web_web_instance_id") or "",
		web_web_instance_api_base_url = uci:get_first("easytier", "easytier", "web_web_instance_api_base_url") or ""
	}
	
	luci.http.write_json(config)
end

function save_web_config()
	local uci = require "luci.model.uci".cursor()
	local http = require "luci.http"
	
	local web_enabled = http.formvalue("web_enabled") or "0"
	local web_db_path = http.formvalue("web_db_path") or "/etc/easytier/et.db"
	local web_protocol = http.formvalue("web_protocol") or "udp"
	local web_port = http.formvalue("web_port") or "22020"
	local web_fw_web = http.formvalue("web_fw_web") or "0"
	local web_api_port = http.formvalue("web_api_port") or "11211"
	local web_html_port = http.formvalue("web_html_port") or "11211"
	local web_api_addr = http.formvalue("web_api_addr") or "0.0.0.0"
	local web_html_addr = http.formvalue("web_html_addr") or "0.0.0.0"
	local web_fw_api = http.formvalue("web_fw_api") or "0"
	local web_api_host = http.formvalue("web_api_host") or ""
	local web_geoip_db = http.formvalue("web_geoip_db") or ""
	local web_disable_registration = http.formvalue("web_disable_registration") or "0"
	local web_allow_auto_create_user = http.formvalue("web_allow_auto_create_user") or "0"
	local web_weblog = http.formvalue("web_weblog") or "off"
	-- OIDC
	local web_oidc_enabled = http.formvalue("web_oidc_enabled") or "0"
	local web_oidc_issuer_url = http.formvalue("web_oidc_issuer_url") or ""
	local web_oidc_client_id = http.formvalue("web_oidc_client_id") or ""
	local web_oidc_client_secret = http.formvalue("web_oidc_client_secret") or ""
	local web_oidc_redirect_url = http.formvalue("web_oidc_redirect_url") or ""
	local web_oidc_username_claim = http.formvalue("web_oidc_username_claim") or "preferred_username"
	local web_oidc_scopes = http.formvalue("web_oidc_scopes") or "openid profile"
	local web_oidc_frontend_base_url = http.formvalue("web_oidc_frontend_base_url") or ""
	local web_oidc_disable_pkce = http.formvalue("web_oidc_disable_pkce") or "0"
	-- Webhook
	local web_webhook_enabled = http.formvalue("web_webhook_enabled") or "0"
	local web_webhook_url = http.formvalue("web_webhook_url") or ""
	local web_webhook_secret = http.formvalue("web_webhook_secret") or ""
	local web_internal_auth_token = http.formvalue("web_internal_auth_token") or ""
	local web_web_instance_id = http.formvalue("web_web_instance_id") or ""
	local web_web_instance_api_base_url = http.formvalue("web_web_instance_api_base_url") or ""
	
	uci:set("easytier", "@easytier[0]", "web_enabled", web_enabled)
	uci:set("easytier", "@easytier[0]", "web_db_path", web_db_path)
	uci:set("easytier", "@easytier[0]", "web_protocol", web_protocol)
	uci:set("easytier", "@easytier[0]", "web_port", web_port)
	uci:set("easytier", "@easytier[0]", "web_fw_web", web_fw_web)
	uci:set("easytier", "@easytier[0]", "web_api_port", web_api_port)
	uci:set("easytier", "@easytier[0]", "web_html_port", web_html_port)
	uci:set("easytier", "@easytier[0]", "web_api_addr", web_api_addr)
	uci:set("easytier", "@easytier[0]", "web_html_addr", web_html_addr)
	uci:set("easytier", "@easytier[0]", "web_fw_api", web_fw_api)
	uci:set("easytier", "@easytier[0]", "web_api_host", web_api_host)
	uci:set("easytier", "@easytier[0]", "web_geoip_db", web_geoip_db)
	uci:set("easytier", "@easytier[0]", "web_disable_registration", web_disable_registration)
	uci:set("easytier", "@easytier[0]", "web_allow_auto_create_user", web_allow_auto_create_user)
	uci:set("easytier", "@easytier[0]", "web_weblog", web_weblog)
	-- OIDC
	uci:set("easytier", "@easytier[0]", "web_oidc_enabled", web_oidc_enabled)
	uci:set("easytier", "@easytier[0]", "web_oidc_issuer_url", web_oidc_issuer_url)
	uci:set("easytier", "@easytier[0]", "web_oidc_client_id", web_oidc_client_id)
	uci:set("easytier", "@easytier[0]", "web_oidc_client_secret", web_oidc_client_secret)
	uci:set("easytier", "@easytier[0]", "web_oidc_redirect_url", web_oidc_redirect_url)
	uci:set("easytier", "@easytier[0]", "web_oidc_username_claim", web_oidc_username_claim)
	uci:set("easytier", "@easytier[0]", "web_oidc_scopes", web_oidc_scopes)
	uci:set("easytier", "@easytier[0]", "web_oidc_frontend_base_url", web_oidc_frontend_base_url)
	uci:set("easytier", "@easytier[0]", "web_oidc_disable_pkce", web_oidc_disable_pkce)
	-- Webhook
	uci:set("easytier", "@easytier[0]", "web_webhook_enabled", web_webhook_enabled)
	uci:set("easytier", "@easytier[0]", "web_webhook_url", web_webhook_url)
	uci:set("easytier", "@easytier[0]", "web_webhook_secret", web_webhook_secret)
	uci:set("easytier", "@easytier[0]", "web_internal_auth_token", web_internal_auth_token)
	uci:set("easytier", "@easytier[0]", "web_web_instance_id", web_web_instance_id)
	uci:set("easytier", "@easytier[0]", "web_web_instance_api_base_url", web_web_instance_api_base_url)
	
	uci:commit("easytier")
	
	http.prepare_content("application/json")
	http.write_json({success = true})
end

function reset_database()
	luci.http.prepare_content("application/json")
	
	local json = require "luci.jsonc"
	local nixio = require "nixio"
	
	-- 从请求中获取数据库路径
	local req_data = json.parse(luci.http.content())
	if not req_data or not req_data.db_path then
		luci.http.write_json({success = false, message = "Missing db_path parameter"})
		return
	end
	
	local db_path = req_data.db_path
	
	-- 安全检查：路径必须是绝对路径且不能是根目录或系统关键目录
	if not db_path:match("^/") or db_path == "/" or 
	   db_path:match("^/bin") or db_path:match("^/sbin") or 
	   db_path:match("^/usr/bin") or db_path:match("^/usr/sbin") or
	   db_path:match("^/lib") or db_path:match("^/boot") then
		luci.http.write_json({success = false, message = "Invalid database path"})
		return
	end
	
	-- 构建要删除的文件列表
	local files_to_delete = {
		db_path,
		db_path .. "-wal",
		db_path .. "-shm"
	}
	
	local deleted_files = {}
	
	-- 删除文件
	for _, file in ipairs(files_to_delete) do
		if nixio.fs.access(file) then
			local result = os.remove(file)
			if result then
				table.insert(deleted_files, file)
			end
		end
	end
	
	if #deleted_files > 0 then
		luci.http.write_json({
			success = true,
			deleted_files = deleted_files,
			message = "Database reset successfully"
		})
	else
		luci.http.write_json({
			success = false,
			message = "No database files found or deletion failed"
		})
	end
end

function check_web_status()
	local running = luci.sys.call("pgrep easytier-web >/dev/null") == 0
	local uci = require "luci.model.uci".cursor()
	local port = uci:get_first("easytier", "easytier", "web_html_port") or "11211"
	
	luci.http.prepare_content("application/json")
	luci.http.write_json({
		running = running,
		port = port
	})
end

function restart_service()
	luci.http.prepare_content("application/json")
	luci.sys.exec("/etc/init.d/easytier restart >/dev/null 2>&1 &")
	luci.http.write_json({success = true})
end

function toggle_core()
	local enabled = luci.http.formvalue("enabled")
	local uci = require "luci.model.uci".cursor()
	uci:set("easytier", uci:get_first("easytier", "easytier"), "enabled", enabled)
	uci:commit("easytier")
	
	if enabled == "1" then
		luci.sys.exec("/etc/init.d/easytier start >/dev/null 2>&1 &")
	else
		luci.sys.exec("/etc/init.d/easytier restart >/dev/null 2>&1 &")
	end
	luci.http.prepare_content("application/json")
	luci.http.write_json({success = true})
end

function toggle_web()
	local enabled = luci.http.formvalue("enabled")
	local uci = require "luci.model.uci".cursor()
	uci:set("easytier", uci:get_first("easytier", "easytier"), "web_enabled", enabled)
	uci:commit("easytier")
	
	if enabled == "1" then
		luci.sys.exec("/etc/init.d/easytier start >/dev/null 2>&1 &")
	else
		luci.sys.exec("/etc/init.d/easytier restart >/dev/null 2>&1 &")
	end
	luci.http.prepare_content("application/json")
	luci.http.write_json({success = true})
end
-- 检测CPU架构
local function detect_arch()
	local cputype = safe_exec("uname -ms | tr ' ' '_' | tr '[A-Z]' '[a-z]'")
	local cpucore = ""
	
	if cputype:match("linux.*armv.*") then
		cpucore = "arm"
	end
	if cputype:match("linux.*armv7.*") and safe_exec("cat /proc/cpuinfo | grep vfp") ~= "" then
		cpucore = "armv7"
	end
	if cputype:match("linux.*aarch64.*") or cputype:match("linux.*armv8.*") then
		cpucore = "aarch64"
	end
	if cputype:match("linux.*86.*") then
		cpucore = "i386"
	end
	if cputype:match("linux.*86_64.*") then
		cpucore = "x86_64"
	end
	if cputype:match("linux.*mips.*") then
		local mipstype = safe_exec("echo -n I | hexdump -o 2>/dev/null | awk '{ print substr($2,6,1); exit}'")
		if mipstype == "0" then
			cpucore = "mips"
		else
			cpucore = "mipsel"
		end
	end
	
	return cpucore
end

-- 检查依赖
local function check_dependencies()
	local arch = detect_arch()
	if arch == "" then
		return false, i18n.translate("Unable to detect CPU architecture")
	end
	if arch == "i386" then
		return false, i18n.translate("No x86-32bit program available")
	end
	if safe_exec("which unzip") == "" then
		return false, i18n.translate("System lacks unzip, cannot download and extract")
	end
	return true, arch
end

-- 获取GitHub镜像列表
local function get_github_proxies()
	local uci = require "luci.model.uci".cursor()
	local proxies = {}
	
	-- 从UCI配置读取代理列表
	local proxy_list = uci:get("easytier", "@easytier[0]", "github_proxys")
	
	if proxy_list then
		if type(proxy_list) == "table" then
			-- 多个代理
			for _, proxy in ipairs(proxy_list) do
				if proxy and proxy ~= "" then
					table.insert(proxies, proxy)
				end
			end
		else
			-- 单个代理
			if proxy_list ~= "" then
				table.insert(proxies, proxy_list)
			end
		end
	end
	
	-- 如果没有配置代理，使用默认值
	if #proxies == 0 then
		proxies = {
			"https://ghproxy.net/",
			"https://gh-proxy.com/",
			"https://cdn.gh-proxy.com/",
			"https://ghfast.top/"
		}
	end
	
	-- 添加不使用代理的选项（空字符串表示直连）
	table.insert(proxies, "")
	
	return proxies
end

-- 下载文件
local function download_file(url, output_path, progress_callback)
	local download_tools = {"curl", "wget"}
	
	for _, tool in ipairs(download_tools) do
		if safe_exec("which " .. tool) ~= "" then
			local cmd = ""
			if tool == "curl" then
				cmd = string.format("curl -L -k --connect-timeout 30 --max-time 300 -o '%s' '%s'", output_path, url)
			elseif tool == "wget" then
				cmd = string.format("wget --no-check-certificate --timeout=30 --tries=3 -O '%s' '%s'", output_path, url)
			end
			
			if progress_callback then
				progress_callback(50, i18n.translate("Downloading with") .. " " .. tool .. "...")
			end
			
			local result = os.execute(cmd)
			if result == 0 and nixio.fs.access(output_path) then
				-- 检查文件大小，确保下载完整
				local stat = nixio.fs.stat(output_path)
				if stat and stat.size > 3 * 1024 * 1024 then -- 至少3MB
					return true
				end
			end
		end
	end
	
	return false
end

function download_easytier()
	luci.http.prepare_content("application/json")
	
	local json = require "luci.jsonc"
	local progress_file = "/tmp/easytier_download_progress"
	
	-- 检查是否已有下载任务
	local existing_progress = safe_read_file(progress_file)
	if existing_progress then
		local progress_data = json.parse(existing_progress)
		if progress_data and progress_data.progress > 0 and progress_data.progress < 100 and not progress_data.error then
			luci.http.write_json({
				success = true,
				progress = progress_data.progress,
				message = i18n.translate("Download task already exists"),
				url = progress_data.url or ""
			})
			return
		end
	end
	
	local req_data = json.parse(luci.http.content())
	if not req_data or not req_data.version then
		luci.http.write_json({success = false, message = i18n.translate("Missing version parameter")})
		return
	end
	
	local version = req_data.version
	
	-- 1. 检查依赖和架构
	local ok, arch_or_error = check_dependencies()
	if not ok then
		luci.http.write_json({success = false, message = arch_or_error})
		return
	end
	
	local arch = arch_or_error
	local proxies = get_github_proxies()
	local download_dir = "/tmp/easytier_download"
	local zip_file = download_dir .. "/easytier-linux-" .. arch .. "-" .. version .. ".zip"
	
	-- 创建下载目录
	os.execute("mkdir -p " .. download_dir)
	
	-- 创建取消标志文件
	local cancel_file = "/tmp/easytier_download_cancel"
	os.execute("rm -f " .. cancel_file)
	
	-- 创建进度文件标记任务开始
	local f = io.open(progress_file, "w")
	if f then
		f:write(json.stringify({
			progress = 1,
			message = "Downloading...",
			url = "",
			error = false
		}))
		f:close()
	end
	
	-- 检查是否被取消
	local function check_cancelled()
		return nixio.fs.access(cancel_file)
	end
	
	-- 2. 循环尝试不同的镜像地址下载、解压、验证
	local download_success = false
	local download_url = ""
	local core_file, cli_file, web_file
	
	for _, proxy in ipairs(proxies) do
		-- 检查是否被取消
		if check_cancelled() then
			os.execute("rm -rf " .. download_dir)
			os.execute("rm -f " .. progress_file)
			luci.http.write_json({success = false, message = i18n.translate("Download cancelled")})
			return
		end
		
		download_url = proxy .. "https://github.com/EasyTier/EasyTier/releases/download/" .. version .. "/easytier-linux-" .. arch .. "-" .. version .. ".zip"
		
		-- 删除之前的失败文件
		os.execute("rm -f " .. zip_file)
		os.execute("rm -rf " .. download_dir .. "/extracted")
		
		-- 下载
		if download_file(download_url, zip_file) then
			local stat = nixio.fs.stat(zip_file)
			if stat and stat.size > 10240 then
				-- 检查是否被取消
				if check_cancelled() then
					os.execute("rm -rf " .. download_dir)
					os.execute("rm -f " .. progress_file)
					luci.http.write_json({success = false, message = i18n.translate("Download cancelled")})
					return
				end
				
				-- 解压
				local extract_dir = download_dir .. "/extracted"
				os.execute("mkdir -p " .. extract_dir)
				local unzip_result = os.execute("cd " .. extract_dir .. " && unzip -o " .. zip_file .. " >/dev/null 2>&1")
				
				if unzip_result == 0 then
					-- 检查是否被取消
					if check_cancelled() then
						os.execute("rm -rf " .. download_dir)
						os.execute("rm -f " .. progress_file)
						luci.http.write_json({success = false, message = i18n.translate("Download cancelled")})
						return
					end
					
					-- 查找解压后的目录（使用通配符）
					local find_cmd = "find " .. extract_dir .. " -maxdepth 1 -type d -name 'easytier-linux-*' 2>/dev/null | head -1"
					local handle = io.popen(find_cmd)
					local subdir = handle:read("*a"):match("^%s*(.-)%s*$")
					handle:close()
					
					if subdir and subdir ~= "" then
						core_file = subdir .. "/easytier-core"
						cli_file = subdir .. "/easytier-cli"
						web_file = subdir .. "/easytier-web-embed"
						
						local files_ok = nixio.fs.access(core_file) and nixio.fs.access(cli_file)
						if arch ~= "mips" and arch ~= "mipsel" then
							files_ok = files_ok and nixio.fs.access(web_file)
						end
						
						if files_ok then
							-- 检查是否被取消
							if check_cancelled() then
								os.execute("rm -rf " .. download_dir)
								os.execute("rm -f " .. progress_file)
								luci.http.write_json({success = false, message = i18n.translate("Download cancelled")})
								return
							end
							
							-- 先赋予执行权限，再测试程序
							local test_files = {core_file, cli_file}
							if arch ~= "mips" and arch ~= "mipsel" then
								table.insert(test_files, web_file)
							end
							
							local test_ok = true
							for _, file in ipairs(test_files) do
								os.execute("chmod +x " .. file)
								if not test_binary(file) then
									test_ok = false
									break
								end
							end
							
							if test_ok then
								download_success = true
								break
							end
						end
					end
				end
			end
		end
		
		-- 删除失败的文件，继续下一个地址
		os.execute("rm -f " .. zip_file)
	end
	
	if not download_success then
		os.execute("rm -rf " .. download_dir)
		os.execute("rm -f " .. progress_file)
		luci.http.write_json({success = false, message = i18n.translate("All download attempts failed")})
		return
	end
	
	-- 检查是否被取消（替换前）
	if check_cancelled() then
		os.execute("rm -rf " .. download_dir)
		os.execute("rm -f " .. progress_file)
		luci.http.write_json({success = false, message = i18n.translate("Download cancelled")})
		return
	end
	
	-- 3. 从UCI获取路径并安装
	local uci = require "luci.model.uci".cursor()
	local easytierbin = uci:get_first("easytier", "easytier", "easytierbin") or "/usr/bin/easytier-core"
	local easytierwebbin = uci:get_first("easytier", "easytier", "webbin") or "/usr/bin/easytier-web"
	
	local core_dir = easytierbin:match("^(.*/)[^/]+$") or "/usr/bin/"
	
	local programs = {
		{src = core_file, dest = easytierbin},
		{src = cli_file, dest = core_dir .. "easytier-cli"}
	}
	
	if arch ~= "mips" and arch ~= "mipsel" then
		table.insert(programs, {src = web_file, dest = easytierwebbin})
	end
	
	-- 安装并验证
	for _, prog in ipairs(programs) do
		local result = os.execute("cp " .. prog.src .. " " .. prog.dest .. " 2>/dev/null")
		if result ~= 0 then
			os.execute("rm -rf " .. download_dir)
			os.execute("rm -f " .. progress_file)
			luci.http.write_json({success = false, message = i18n.translate("Failed to install program") .. ": " .. prog.dest})
			return
		end
		
		os.execute("chmod +x " .. prog.dest)
		
		-- 再次验证安装后的程序
		if not test_binary(prog.dest) then
			os.execute("rm -rf " .. download_dir)
			os.execute("rm -f " .. progress_file)
			luci.http.write_json({success = false, message = i18n.translate("Program is incomplete or architecture mismatch")})
			return
		end
	end
	
	-- 7. 清理临时文件和版本缓存
	os.execute("rm -rf " .. download_dir)
	os.execute("rm -f " .. cancel_file)
	os.execute("rm -f " .. progress_file)
	nixio.fs.remove("/tmp/easytier.tag")
	nixio.fs.remove("/tmp/easytierweb.tag")
	
	luci.http.write_json({
		success = true,
		progress = 100,
		message = i18n.translate("Download and installation completed")
	})
end

function download_progress()
	luci.http.prepare_content("application/json")
	
	local progress_file = "/tmp/easytier_download_progress"
	local content = safe_read_file(progress_file)
	
	if content then
		local json = require "luci.jsonc"
		local progress_data = json.parse(content)
		if progress_data then
			luci.http.write_json({
				success = true,
				progress = progress_data.progress or 0,
				message = progress_data.message or "",
				url = progress_data.url or "",
				error = progress_data.error or false
			})
			return
		end
	end
	
	luci.http.write_json({
		success = true,
		progress = 0,
		message = i18n.translate("Preparing..."),
		url = "",
		error = false
	})
end
function cancel_download()
	luci.http.prepare_content("application/json")
	
	-- 创建取消标志文件
	os.execute("touch /tmp/easytier_download_cancel")
	
	luci.http.write_json({success = true})
end
