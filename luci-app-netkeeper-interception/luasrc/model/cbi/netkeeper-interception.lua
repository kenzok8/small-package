local sys = require "luci.sys"

m = Map("netkeeper-interception")
m.title	= translate("Netkeeper Interception")
m.description = translate("Netkeeper Account Interception Plugin")

m:section(SimpleSection).template = "netkeeper-interception/netkeeper-interception_status"

s = m:section(TypedSection, "netkeeper-interception")
s.addremove = false
s.anonymous = true

enable = s:option(Flag, "enabled", translate("Enable"), translate("If disabled, the last authentication will be kept"))
enable.optional = false
enable.rmempty = false

iface = s:option(ListValue, "iface", translate("Specifies the LAN Interface to listen"),
	translate("Specifies the Lan Interface that needs to be Listen by The PPPoE Server"))
for _, e in ipairs(sys.net.devices()) do
	if e ~= "lo" then iface:value(e) end
end
iface.optional = false
iface.rmempty = false

last_authreq = s:option(TextValue, "last_authreq", translate("Last AuthReq"),translate("Last PPPoE Server Auth Request (Live Update)"))
last_authreq.template = "netkeeper-interception/netkeeper-interception_authreq"

return m