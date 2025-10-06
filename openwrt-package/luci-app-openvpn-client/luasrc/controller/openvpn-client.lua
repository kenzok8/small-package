-- Copyright 2021-2025 Lienol <lawlienol@gmail.com>
module("luci.controller.openvpn-client", package.seeall)

function index()
    if not nixio.fs.access("/etc/config/luci-app-openvpn-client") then return end

    entry({"admin", "vpn"}, firstchild(), "VPN", 45).dependent = false
    entry({"admin", "vpn", "openvpn-client"}, cbi("openvpn-client/settings"), _("OpenVPN Client"), 50).acl_depends = { "luci-app-openvpn-client" }
    entry({"admin", "vpn", "openvpn-client", "client"}, cbi("openvpn-client/client")).leaf = true

    entry({"admin", "vpn", "openvpn-client", "log"}, call("get_log")).leaf = true
end

function get_log()
	local fs = require "nixio.fs"
	local i18n = require "luci.i18n"
	local id = luci.http.formvalue("id")
	local log_file = "/tmp/etc/openvpn-client/" .. id .. "/openvpn.log"
	if fs.access(log_file) then
		local content = luci.sys.exec("cat ".. log_file)
		content = content:gsub("\n", "<br />")
		luci.http.write(content)
	else
		luci.http.write(string.format("<script>alert('%s');window.close();</script>", i18n.translate("Not log")))
	end
end