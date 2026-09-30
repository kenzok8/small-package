-- Copyright 2020-2026 Richard <xiaoqingfengatgm@gmail.com>
-- feed site : https://github.com/xiaoqingfengATGH/feeds-xiaoqingfeng
module("luci.controller.homeredirect", package.seeall)
local appname = "homeredirect"
local ucic = luci.model.uci.cursor()
local http = require "luci.http"

function index()
	entry({"admin", "services", "homeredirect", "show"}, call("show_menu")).leaf = true
	entry({"admin", "services", "homeredirect", "hide"}, call("hide_menu")).leaf = true

	if nixio.fs.access("/etc/config/homeredirect") and
		nixio.fs.access("/etc/config/homeredirect_show") then
		entry({"admin", "services", "homeredirect"},
			alias("admin", "services", "homeredirect", "settings"),
			_("Home Redirect"), 50).dependent = true
	end

	entry({"admin", "services", "homeredirect", "settings"},
		cbi("homeredirect/settings")).leaf = true
	entry({"admin", "services", "homeredirect", "status"}, call("status")).leaf = true
end

local function http_write_json(content)
	http.prepare_content("application/json")
	http.write_json(content or {code = 1})
end

function status()
	-- per-rule running state via procd service instances: each redirect runs
	-- as its own procd instance named after the uci section id
	local e = {}
	local running = {}
	local stats = luci.util.ubus("service", "list", {name = appname, verbose = true}) or {}
	local instances = (stats[appname] or {}).instances or {}
	for _, inst in pairs(instances) do
		if inst.running == true then
			-- instance command carries the log path /tmp/hr/<id>.log
			local cmd = table.concat(inst.command or {}, " ")
			local id = cmd:match("/tmp/hr/([%w_]+)%.log")
			if id then running[id] = 1 end
		end
	end

	e.enabled = ucic:get(appname, "@global[0]", "enabled")
	ucic:foreach(appname, "redirect", function(redirect)
		local id = redirect['.name']
		local state = -1
		if redirect['enabled'] == "1" then
			state = running[id] and 1 or 0
		end
		e[id] = state
	end)
	http_write_json(e)
end

function show_menu()
	luci.sys.call("touch /etc/config/homeredirect_show")
	luci.http.redirect(luci.dispatcher.build_url("admin", "services", "homeredirect"))
end

function hide_menu()
	luci.sys.call("rm -rf /etc/config/homeredirect_show")
	luci.http.redirect(luci.dispatcher.build_url("admin", "status", "overview"))
end
