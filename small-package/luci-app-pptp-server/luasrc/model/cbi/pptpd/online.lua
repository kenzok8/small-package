local o = require "luci.dispatcher"
local fs = require "nixio.fs"
local jsonc = require "luci.jsonc"

local sessions = {}
local session_path = "/var/etc/pptpd/session"
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
        local m = line:match('pptpd%-blacklist%-([^\n]+)')
        if m then
            local t = {}
            t.ip = m
            blacklist[#blacklist + 1] = t
        end
    end
end

f = SimpleForm("processes", translate("PPTP VPN Server"))
f.reset = false
f.submit = false
f.description = translate("Simple, quick and convenient PPTP VPN, universal across the platform")

t = f:section(Table, sessions, translate("Online Users"))
t:option(DummyValue, "username", translate("Username"))
t:option(DummyValue, "interface", translate("Interface"))
t:option(DummyValue, "ip", translate("Client IP"))
t:option(DummyValue, "remote_ip", translate("IP address"))
t:option(DummyValue, "login_time", translate("Login Time"))

_blacklist = t:option(Button, "_blacklist", translate("Blacklist"))
function _blacklist.render(e, t, a)
    e.title = translate("Add to Blacklist")
    e.inputstyle = "remove"
    Button.render(e, t, a)
end
function _blacklist.write(t, s)
    local e = t.map:get(s, "remote_ip")
    luci.util.execi("echo 'iptables -I INPUT -s %s -p tcp --dport 1723 -j DROP ## pptpd-blacklist-%s' >> /etc/firewall.user" % {e, e})
    luci.util.execi("iptables -I INPUT -s %s -p tcp --dport 1723 -j DROP" % {e})
    luci.util.execi("rm -f " .. t.map:get(s, "session_file"))
    null, t.tag_error[s] = luci.sys.process.signal(t.map:get(s, "pid"), 9)
    luci.http.redirect(o.build_url("admin/vpn/pptpd/online"))
end

_kill = t:option(Button, "_kill", translate("Forced offline"))
_kill.inputstyle = "reset"
function _kill.write(t, s)
    luci.util.execi("rm -f " .. t.map:get(s, "session_file"))
    null, t.tag_error[t] = luci.sys.process.signal(t.map:get(s, "pid"), 9)
    luci.http.redirect(o.build_url("admin/vpn/pptpd/online"))
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
    local e = t.map:get(s, "ip")
    luci.util.execi("sed -i -e '/## pptpd-blacklist-%s/d' /etc/firewall.user" % {e})
    luci.util.execi("iptables -D INPUT -s %s -p tcp --dport 1723 -j DROP" % {e})
    luci.http.redirect(o.build_url("admin/vpn/pptpd/online"))
end

return f
