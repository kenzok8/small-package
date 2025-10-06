--[[
LuCI - Lua Configuration Interface

Copyright 2025 LunaticKochiya<125438787@qq.com>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

$Id$
]]--
module("luci.controller.openvpn-server", package.seeall)

function index()
	if not nixio.fs.access("/etc/config/openvpn") then
		return
	end

	entry({"admin", "services", "openvpn-server"},firstchild(), _("OpenVPN Server"), 1).dependent = true

	entry({"admin", "services", "openvpn-server", "general"}, cbi("openvpn-server/openvpn-server"), _("OpenVPN Server"), 1).leaf = true
	entry({"admin", "services", "openvpn-server", "client"},cbi("openvpn-server/openvpn-server_ovpn"), _("Client"), 2).leaf = true
	entry({"admin", "services", "openvpn-server", "log"},form("openvpn-server/openvpn-server_run_log"), _("Running log"), 3).leaf = true

	entry({"admin", "services", "openvpn-server","status"},call("act_status")).leaf=true
end

function act_status()
  local e={}
  e.running=luci.sys.call("pgrep openvpn >/dev/null")==0
  luci.http.prepare_content("application/json")
  luci.http.write_json(e)
end
