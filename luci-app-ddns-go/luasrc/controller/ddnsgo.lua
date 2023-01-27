-- Copyright (C) 2021-2022  sirpdboy  <herboy2008@gmail.com> https://github.com/sirpdboy/luci-app-ddnsgo 
-- Licensed to the public under the Apache License 2.0.

module("luci.controller.ddnsgo", package.seeall)

function index()
	if not nixio.fs.access("/etc/config/ddnsgo") then
		return
	end

	entry({"admin",  "services", "ddnsgo"}, alias("admin", "services", "ddnsgo", "setting"),_("DDNS-GO"), 58).dependent = true
	entry({"admin", "services", "ddnsgo", "setting"}, cbi("ddnsgo"), _("Base Setting"), 20).leaf=true
	entry({"admin",  "services", "ddnsgo", "ddnsgo"}, template("ddnsgo"), _("DDNS-GO"), 30).leaf = true
	entry({"admin", "services", "ddnsgo_status"}, call("act_status"))
end

function act_status()
	local sys  = require "luci.sys"
	local e = { }
	e.running = sys.call("pidof ddns-go >/dev/null") == 0
	luci.http.prepare_content("application/json")
	luci.http.write_json(e)
end
