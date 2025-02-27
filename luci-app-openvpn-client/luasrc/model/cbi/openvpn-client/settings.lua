local d = require "luci.dispatcher"
local sys = require "luci.sys"

m = Map("luci-app-openvpn-client", translate("OpenVPN Client"))
m.apply_on_parse = true

s = m:section(TypedSection, "clients", translate("Client List"))
s.addremove = true
s.anonymous = true
s.template = "cbi/tblsection"
s.extedit = d.build_url("admin", "vpn", "openvpn-client", "client", "%s")
function s.create(e, t)
    t = TypedSection.create(e, t)
    luci.http.redirect(e.extedit:format(t))
end

o = s:option(Flag, "enabled", translate("Enabled"))
o.default = 1
o.rmempty = false

function s.getPID(section) -- Universal function which returns valid pid # or nil
	local pid = sys.exec("top -bn1 | grep -v 'grep' | grep '/var/etc/openvpn-client/%s'" % { section })
	if pid and #pid > 0 then
		return tonumber(pid:match("^%s*(%d+)"))
	else
		return nil
	end
end

local active = s:option(DummyValue, "_active", translate("Status"))
function active.cfgvalue(self, section)
	local pid = s.getPID(section)
	if pid ~= nil then
		if sys.process.signal(pid, 0) then
			active.rawhtml = true
			local onclick = string.format("window.open('%s', '_blank')", d.build_url("admin", "vpn", "openvpn-client", "log") .. "?id=" .. section)
			return translate("RUNNING") .. " (" .. pid .. ")" .. '&nbsp&nbsp<a href="#" onclick="' .. onclick .. '">' .. translate("Log") .. '</a>'
		end
	end
	return translate("NOT RUNNING")
end

local updown = s:option(Button, "_updown", translate("Start/Stop"))
updown._state = false
updown.redirect = d.build_url(
	"admin", "vpn", "openvpn-client"
)
function updown.cbid(self, section)
	local pid = s.getPID(section)
	self._state = pid ~= nil and sys.process.signal(pid, 0)
	self.option = self._state and "stop" or "start"
	return AbstractValue.cbid(self, section)
end
function updown.cfgvalue(self, section)
	self.title = self._state and translate("stop") or translate("start")
	self.inputstyle = self._state and "reset" or "reload"
end
function updown.write(self, section, value)
	if self.option == "stop" then
		-- RUNNING
		sys.call("/etc/init.d/luci-app-openvpn-client stop %s" % section)
	else
		-- NOT RUNNING
		sys.call("/etc/init.d/luci-app-openvpn-client start %s" % section)
	end
	luci.http.redirect( self.redirect )
end

o = s:option(DummyValue, "server", translate("Server IP/Host"))

o = s:option(DummyValue, "port", translate("Port"))

o = s:option(DummyValue, "proto", translate("Protocol"))

function s.remove(self, section)
	sys.call("/etc/init.d/luci-app-openvpn-client stop %s" % section)
	return TypedSection.remove(self, section)
end

return m
