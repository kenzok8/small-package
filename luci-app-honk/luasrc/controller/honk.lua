local sys = require "luci.sys"
local http = require "luci.http"
local nixio = require "nixio"

local honk_tools = require "luci.model.honk_tools"

module("luci.controller.honk", package.seeall)

function index()
	if not nixio.fs.access("/etc/config/honk") then
		return
	end

	-- Main page
	local page = entry({"admin", "services", "honk"}, firstchild(), _("HONK"), -1)
	page.dependent = true
	page.acl_depends = { "luci-app-honk" }

	-- Status entry
	entry({"admin", "services", "honk", "status"}, call("act_status")).leaf = true

	-- Configuration pages
	entry({"admin", "services", "honk", "global"}, cbi("honk/global"), _("Global Settings"), 1)
	entry({"admin", "services", "honk", "dns"}, cbi("honk/dns"), _("DNS Settings"), 2)
	entry({"admin", "services", "honk", "node"}, cbi("honk/node"), _("Node Settings"), 3)
	entry({"admin", "services", "honk", "route"}, cbi("honk/route"), _("Routing Settings"), 4)
	entry({"admin", "services", "honk", "zashboard"}, cbi("honk/zashboard"), _("Zashboard"), 5)
	entry({"admin", "services", "honk", "log"}, cbi("honk/log"), _("Logs"), 6)
	entry({"admin", "services", "honk", "get_log"}, call("get_log"))
	entry({"admin", "services", "honk", "clear_log"}, call("clear_log"))

	-- Zashboard APIs
	entry({"admin", "services", "honk", "zashboard_info"}, call("act_zashboard_info")).leaf = true
	entry({"admin", "services", "honk", "download_zashboard"}, call("act_download_zashboard")).leaf = true
	entry({"admin", "services", "honk", "download_status"}, call("act_download_status")).leaf = true
	entry({"admin", "services", "honk", "enable_clash_api"}, call("act_enable_clash_api")).leaf = true
end

function act_status()
	local fs   = require "nixio.fs"
	local e = { }
	local pids = sys.exec("pidof honk-core 2>/dev/null") or ""
	local pid = pids:match("(%d+)") or ""
	e.running = (pid ~= "")
	if e.running then
		local status = fs.readfile("/proc/" .. pid .. "/status")
		if status then
			local rss = status:match("VmRSS:%s+(%d+)%s+kB")
			if rss then
				e.memory = string.format("%.1f MB", tonumber(rss) / 1024)
			end
		end
	end
	luci.http.prepare_content("application/json")
	luci.http.write_json(e)
end

function get_log()
	http.write(sys.exec("tail -n 1000 /var/log/honk/honk.log 2>/dev/null"))
end

function clear_log()
	sys.call("true > /var/log/honk/honk.log")
end

function act_zashboard_info()
	local info = honk_tools.get_clash_api_config()
	http.prepare_content("application/json")
	http.write_json(info)
end

function act_download_zashboard()
	local url = http.formvalue("url")
	if not url or url == "" then
		url = "https://github.com/Zephyruso/zashboard/releases/latest/download/dist-no-fonts.zip"
	end

	-- Basic URL validation
	if not url:match("^https?://[%w%.%-%_/%?%&%=%%#:]+$") then
		http.prepare_content("application/json")
		http.write_json({ success = false, message = "Invalid URL" })
		return
	end

	local info = honk_tools.get_clash_api_config()
	local target_dir = info.external_ui
	if not target_dir or target_dir == "" then
		target_dir = "/etc/honk/zashboard"
	end

	local script = "/usr/share/honk/download_zashboard.sh"
	if not nixio.fs.access(script) then
		http.prepare_content("application/json")
		http.write_json({ success = false, message = "Script not found: " .. script })
		return
	end

	local safe_script = script:gsub("'", "'\\''")
	local safe_target = target_dir:gsub("'", "'\\''")
	local safe_url = url:gsub("'", "'\\''")

	local cmd = string.format("/bin/sh '%s' '%s' '%s' >/dev/null 2>&1 &", safe_script, safe_target, safe_url)
	sys.call(cmd)

	http.prepare_content("application/json")
	http.write_json({ success = true, target_dir = target_dir, url = url })
end

function act_download_status()
	local fs = require "nixio.fs"
	local status = fs.readfile("/tmp/honk_zashboard_download.status") or "IDLE"
	local log = fs.readfile("/tmp/honk_zashboard_download.log") or ""

	status = status:gsub("%s+", "")
	http.prepare_content("application/json")
	http.write_json({
		status = status,
		log = log
	})
end

function act_enable_clash_api()
	local ok, err = honk_tools.enable_default_clash_api()
	http.prepare_content("application/json")
	http.write_json({
		success = ok,
		message = err or "OK"
	})
end

