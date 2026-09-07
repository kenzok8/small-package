local sys = require "luci.sys"
local http = require "luci.http"
local nixio = require "nixio"

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
	entry({"admin", "services", "honk", "log"}, cbi("honk/log"), _("Logs"), 5)
	entry({"admin", "services", "honk", "get_log"}, call("get_log"))
	entry({"admin", "services", "honk", "clear_log"}, call("clear_log"))
end

function act_status()
	local fs   = require "nixio.fs"
	local e = { }
	local pid = sys.exec("pidof honk-core | cut -d' ' -f1"):gsub("\n", "")
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

