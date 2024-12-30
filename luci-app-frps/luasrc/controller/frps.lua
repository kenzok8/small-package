-- Copyright 2020 lwz322 <lwz322@qq.com>
-- Licensed to the public under the MIT License.

local http = require "luci.http"
local uci = require "luci.model.uci".cursor()
local sys = require "luci.sys"

-- 查看配置文件所需
local e=require"nixio.fs"
local t=require"luci.sys"
local a=require"luci.template"
local t=require"luci.i18n"

module("luci.controller.frps", package.seeall)

function index()
	if not nixio.fs.access("/etc/config/frps") then
		return
	end

	entry({"admin", "services", "frps"}, firstchild(), _("Frps")).dependent = false

	entry({"admin", "services", "frps", "common"}, cbi("frps/common"), _("设置"), 1)

	entry({"admin", "services", "frps", "status"}, call("action_status"))
	
	entry({"admin", "services", "frps", "configuration"}, call("view_conf"), _("查看配置"), 3).leaf = true
	
	entry({"admin", "services", "frps", "get_log"}, call("get_log")).leaf = true
	entry({"admin", "services", "frps", "clear_log"}, call("clear_log")).leaf = true
	entry({"admin", "services", "frps", "log"}, cbi("frps/log"), _("查看日志"), 6).leaf = true
end


function action_status()
	local running = false

	local client = uci:get("frps", "main", "client_file")
	if client and client ~= "" then
		local file_name = client:match(".*/([^/]+)$") or ""
		if file_name ~= "" then
			running = sys.call("pidof %s >/dev/null" % file_name) == 0
		end
	end

	http.prepare_content("application/json")
	http.write_json({
		running = running
	})
end

function view_conf()
local e=e.readfile("/var/etc/frps/frps.main.toml")or""
a.render("frps/file_viewer",
{title=t.translate("Frps - 查看配置文件"),content=e})
end

function get_log()
    luci.http.write(luci.sys.exec("cat /tmp/frps_log_link.txt"))
end
function clear_log()
    luci.sys.call("true > /tmp/frps_log_link.txt")
end
