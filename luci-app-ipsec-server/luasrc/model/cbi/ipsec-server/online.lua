local d = require "luci.dispatcher"
local fs = require "nixio.fs"
local jsonc = require "luci.jsonc"
local sys = require "luci.sys"
local util = require "luci.util"
local uci = require "luci.model.uci".cursor()

f = SimpleForm("processes")
f.reset = false
f.submit = false

local firewall_user_path = "/etc/firewall.user"

if uci:get("luci-app-ipsec-server", "ipsec", "type") ~= "L2TP" then
	local sessions = {}
	local status_dump = io.popen('ipsec status 2>&1 | grep "ESTABLISHED"')
	if status_dump then
		local line
		for line in status_dump:lines() do
			local line = string.split(line, ",")
			local s1 = string.split(line[1], " ")
			local type_count = s1[1]
			local user = line[2]
			local user_split = string.split(user, "...")
			if #user_split == 2 then
				local leftid = string.match(user_split[1], "%[(.-)%]")
				local username = string.match(user_split[2], "%[(.-)%]")
				local remote_ip = string.split(user_split[2], "[")[1]
				local a = {}
				for i, v in ipairs(s1) do
					if i > 2 then
						a[#a + 1] = v
					end
				end
				local login_time = table.concat(a, " ")
				sessions[#sessions + 1] = {
					username = username,
					remote_ip = remote_ip,
					login_time = login_time
				}
			end
		end
	end
	for i, v in ipairs(sessions) do
		local ip = util.exec("ipsec leases 2>/dev/null | grep 'online' | grep '%s' | awk '{print $1}'" % { v.username })
		v.ip = ip
	end
	t = f:section(Table, sessions, translate("Online Users"))
	t:option(DummyValue, "username", translate("Username") .. "/" .. translate("Identifier"))
	t:option(DummyValue, "ip", translate("Client IP"))
	t:option(DummyValue, "login_time", translate("Login Time"))
	t:option(DummyValue, "remote_ip", translate("IP address"))
	add_blacklist = t:option(Button, "add_blacklist", translate("Blacklist"))
	function add_blacklist.render(e, t, a)
		e.title = translate("Add to Blacklist")
		e.inputstyle = "remove"
		Button.render(e, t, a)
	end
	function add_blacklist.write(t, s)
		local e = t.map:get(s, "remote_ip")
		util.execi("echo 'iptables -I INPUT -s %s -p udp -m multiport --dports 500,4500 -j DROP ## ipsec-blacklist-%s' >> %s" % {e, e, firewall_user_path})
		util.execi("iptables -I INPUT -s %s -p udp -m multiport --dports 500,4500 -j DROP" % {e})
		luci.http.redirect(d.build_url("admin/vpn/ipsec-server/online"))
	end
else
	local l2tp_sessions = {}
	local l2tp_session_path = "/var/etc/xl2tpd/session"
	if fs.access(l2tp_session_path) then
		for filename in fs.dir(l2tp_session_path) do
			local session_file = l2tp_session_path .. "/" .. filename
			local file = io.open(session_file, "r")
			local t = jsonc.parse(file:read("*a"))
			if t then
				t.session_file = session_file
				l2tp_sessions[#l2tp_sessions + 1] = t
			end
			file:close()
		end
	end

	t = f:section(Table, l2tp_sessions, translate("L2TP Online Users"))
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
		util.execi("echo 'iptables -I INPUT -s %s -p udp -m multiport --dports 500,4500,1701 -j DROP ## xl2tpd-blacklist-%s' >> %s" % {e, e, firewall_user_path})
		util.execi("iptables -I INPUT -s %s -p udp -m multiport --dports 500,4500,1701 -j DROP" % {e})
		util.execi("rm -f " .. t.map:get(s, "session_file"))
		null, t.tag_error[s] = sys.process.signal(t.map:get(s, "pid"), 9)
		luci.http.redirect(d.build_url("admin/vpn/ipsec-server/online"))
	end

	_kill = t:option(Button, "_kill", translate("Forced offline"))
	_kill.inputstyle = "remove"
	function _kill.write(t, s)
		util.execi("rm -f " .. t.map:get(s, "session_file"))
		null, t.tag_error[t] = sys.process.signal(t.map:get(s, "pid"), 9)
		luci.http.redirect(d.build_url("admin/vpn/ipsec-server/online"))
	end
end

local blacklist = {}
if fs.access(firewall_user_path) then
	for line in io.lines(firewall_user_path) do
		local m = line:match('ipsec%-blacklist%-([^\n]+)')
		if m then
			local t = {}
			t.ip = m
			blacklist[#blacklist + 1] = t
		end
		local m = line:match('xl2tpd%-blacklist%-([^\n]+)')
		if m then
			local t = {}
			t.ip = m
			blacklist[#blacklist + 1] = t
		end
	end
end

t = f:section(Table, blacklist, translate("Blacklist"))
t:option(DummyValue, "ip", translate("IP address"))

remove_blacklist = t:option(Button, "remove_blacklist", translate("Blacklist"))
function remove_blacklist.render(e, t, a)
	e.title = translate("Remove from Blacklist")
	e.inputstyle = "apply"
	Button.render(e, t, a)
end
function remove_blacklist.write(t, s)
	local e = t.map:get(s, "ip")
	util.execi("sed -i -e '/## ipsec-blacklist-%s/d' %s" % {e, firewall_user_path})
	util.execi("sed -i -e '/## xl2tpd-blacklist-%s/d' %s" % {e, firewall_user_path})
	util.execi("iptables -D INPUT -s %s -p udp -m multiport --dports 500,4500 -j DROP 2>/dev/null" % {e})
	util.execi("iptables -D INPUT -s %s -p udp -m multiport --dports 500,4500,1701 -j DROP 2>/dev/null" % {e})
	luci.http.redirect(d.build_url("admin/vpn/ipsec-server/online"))
end

return f
