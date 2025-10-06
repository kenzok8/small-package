local o = require "luci.dispatcher"
local fs = require "nixio.fs"
local jsonc = require "luci.jsonc"
local uci = require "luci.model.uci":cursor()

local sessions = {}
local session_path = "/var/etc/openvpn-server/session"
if fs.access(session_path) then
    for filename in fs.dir(session_path) do
        local session_file = session_path .. "/" .. filename
        local file = io.open(session_file, "r")
        local t = jsonc.parse(file:read("*a"))
        if t then
            t.session_file = session_file
            sessions[#sessions + 1] = t
        end
        file:close()
    end
end

local blacklist = {}
local firewall_user_path = "/etc/firewall.user"
if fs.access(firewall_user_path) then
    for line in io.lines(firewall_user_path) do
        local m = line:match('openvpn%-server%-blacklist%-([^\n]+)')
        if m then
            local t = {}
            t.ip = m
            blacklist[#blacklist + 1] = t
        end
    end
end

f = SimpleForm("processes", translate("OpenVPN Server"))
f.reset = false
f.submit = false

t = f:section(Table, sessions, translate("Online Users"))
t:option(DummyValue, "common_name", translate("Username"))
t:option(DummyValue, "ifconfig_pool_remote_ip", translate("Client IP"))
t:option(DummyValue, "remote_ip", translate("IP address"))
t:option(DummyValue, "login_time", translate("Login Time"))

_blacklist = t:option(Button, "_blacklist", translate("Blacklist"))
function _blacklist.render(e, t, a)
    e.title = translate("Add to Blacklist")
    e.inputstyle = "remove"
    Button.render(e, t, a)
end
function _blacklist.write(t, s)
    local common_name = t.map:get(s, "common_name")
    luci.util.execi('echo "kill %s" | nc 127.0.0.1 17777 >/dev/null 2>&1' % common_name)
    local ip = t.map:get(s, "remote_ip")
    local port = uci:get("luci-app-openvpn-server", "server", "port") or "1194"
    local proto = uci:get("luci-app-openvpn-server", "server", "proto") or "tcp"
    luci.util.execi("echo 'iptables -I INPUT -s %s -p %s --dport %s -j DROP ## openvpn-server-blacklist-%s' >> /etc/firewall.user" % { ip, proto, port, ip })
    luci.util.execi("iptables -I INPUT -s %s -p %s --dport %s -j DROP" % { ip, proto, port })
    luci.util.execi("rm -f " .. t.map:get(s, "session_file"))
    luci.http.redirect(o.build_url("admin/vpn/openvpn-server/online"))
end

_kill = t:option(Button, "_kill", translate("Forced offline"))
_kill.inputstyle = "reset"
function _kill.write(t, s)
    local common_name = t.map:get(s, "common_name")
    luci.util.execi('echo "kill %s" | nc 127.0.0.1 17777 >/dev/null 2>&1' % common_name)
    luci.http.redirect(o.build_url("admin/vpn/openvpn-server/online"))
end

t = f:section(Table, blacklist, translate("Blacklist"))
t:option(DummyValue, "ip", translate("IP address"))

_blacklist2 = t:option(Button, "_blacklist2", translate("Blacklist"))
function _blacklist2.render(e, t, a)
    e.title = translate("Remove from Blacklist")
    e.inputstyle = "apply"
    Button.render(e, t, a)
end
function _blacklist2.write(t, s)
    local ip = t.map:get(s, "ip")
    local port = uci:get("luci-app-openvpn-server", "server", "port") or "1194"
    local proto = uci:get("luci-app-openvpn-server", "server", "proto") or "tcp"
    luci.util.execi("sed -i -e '/## openvpn-server-blacklist-%s/d' /etc/firewall.user" % { ip })
    luci.util.execi("iptables -D INPUT -s %s -p %s --dport %s -j DROP" % { ip, proto, port })
    luci.http.redirect(o.build_url("admin/vpn/openvpn-server/online"))
end

return f
