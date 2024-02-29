-- Copyright (C)  2018-2022 sirpdboy  <herboy2008@gmail.com> https://github.com/sirpdboy/luci-app-netdata
-- Licensed to the public under the Apache License 2.0.

module("luci.controller.netdata", package.seeall)

function index()
	if not nixio.fs.access("/etc/config/netdata") then
		return
	end
	local e = entry({"admin", "status", "netdata"}, alias("admin", "status", "netdata", "setting"),_("NetData"), 10)
	e.dependent = false
	e.acl_depends = { "luci-app-netdata" }
	entry({"admin", "status", "netdata", "setting"}, cbi("netdata/netdata"), _("Base Setting"), 20).leaf=true
	entry({"admin", "status", "netdata", "netdata"}, template("netdata"), _("NetData"), 30).leaf = true
	entry({"admin", "status", "netdata_status"}, call("act_status"))
end

function act_status()
	local sys  = require "luci.sys"
	local e = { }
	e.running = sys.call("pidof netdata >/dev/null") == 0
	luci.http.prepare_content("application/json")
	luci.http.write_json(e)
end
