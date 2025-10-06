-- Copyright 2021-2025 Lienol <lawlienol@gmail.com>
module("luci.controller.openvpn-server", package.seeall)

function index()
    if not nixio.fs.access("/etc/config/luci-app-openvpn-server") then return end

    entry({"admin", "vpn"}, firstchild(), "VPN", 45).dependent = false
    entry({"admin", "vpn", "openvpn-server"}, alias("admin", "vpn", "openvpn-server", "settings"), _("OpenVPN Server"), 50).acl_depends = { "luci-app-openvpn-server" }
    entry({"admin", "vpn", "openvpn-server", "settings"}, cbi("openvpn-server/settings"), _("Server"), 10).leaf = true
    entry({"admin", "vpn", "openvpn-server", "user"}, cbi("openvpn-server/user")).leaf = true
    entry({"admin", "vpn", "openvpn-server", "online"}, cbi("openvpn-server/online"), _("Online Users"), 11).leaf = true
    entry({"admin", "vpn", "openvpn-server", "log"}, form("openvpn-server/log"), _("Logs"), 99).leaf = true
    entry({"admin", "vpn", "openvpn-server", "status"}, call("status")).leaf = true
    entry({"admin", "vpn", "openvpn-server", "get_log"}, call("get_log")).leaf = true
end

function status()
    local e = {}
    e.status = luci.sys.call("top -bn1 | grep -v grep | grep '/var/etc/openvpn-server' >/dev/null") == 0
    luci.http.prepare_content("application/json")
    luci.http.write_json(e)
end

function get_log()
    local e = {}
    e.app_log = luci.sys.exec("[ -f '/tmp/etc/openvpn-server/openvpn.log' ] && cat /tmp/etc/openvpn-server/openvpn.log")
    e.auth_log = luci.sys.exec("[ -f '/tmp/etc/openvpn-server/client.log' ] && cat /tmp/etc/openvpn-server/client.log")
    luci.http.prepare_content("application/json")
    luci.http.write_json(e)
end
