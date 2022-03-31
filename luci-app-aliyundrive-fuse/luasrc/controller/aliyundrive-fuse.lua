module("luci.controller.aliyundrive-fuse", package.seeall)

function index()
	if not nixio.fs.access("/etc/config/aliyundrive-fuse") then
		return
	end

	local page
	page = entry({"admin", "services", "aliyundrive-fuse"}, alias("admin", "services", "aliyundrive-fuse", "client"), _("AliyunDrive FUSE"), 10) -- 首页
	page.dependent = true
	page.acl_depends = { "luci-app-aliyundrive-fuse" }

	entry({"admin", "services", "aliyundrive-fuse", "client"}, cbi("aliyundrive-fuse/client"), _("Settings"), 10).leaf = true -- 客户端配置
	entry({"admin", "services", "aliyundrive-fuse", "log"}, form("aliyundrive-fuse/log"), _("Log"), 30).leaf = true -- 日志页面

	entry({"admin", "services", "aliyundrive-fuse", "status"}, call("action_status")).leaf = true
	entry({"admin", "services", "aliyundrive-fuse", "logtail"}, call("action_logtail")).leaf = true
end

function action_status()
	local e = {}
	e.running = luci.sys.call("pidof aliyundrive-fuse >/dev/null") == 0
	e.application = luci.sys.exec("aliyundrive-fuse --version")
	luci.http.prepare_content("application/json")
	luci.http.write_json(e)
end

function action_logtail()
	local fs = require "nixio.fs"
	local log_path = "/var/log/aliyundrive-fuse.log"
	local e = {}
	e.running = luci.sys.call("pidof aliyundrive-fuse >/dev/null") == 0
	if fs.access(log_path) then
		e.log = luci.sys.exec("tail -n 100 %s | sed 's/\\x1b\\[[0-9;]*m//g'" % log_path)
	else
		e.log = ""
	end
	luci.http.prepare_content("application/json")
	luci.http.write_json(e)
end
