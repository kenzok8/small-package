local sys = require "luci.sys"

m = Map("luci-app-ipsec-server", translate("IPSec VPN Server"))
m.template = "ipsec-server/ipsec-server_status"

s = m:section(TypedSection, "service")
s.anonymous = true

o = s:option(DummyValue, "ipsec-server_status", translate("Current Condition"))
o.rawhtml = true
o.cfgvalue = function(t, n)
	return '<font class="ipsec-server_status"></font>'
end

o = s:option(Flag, "enabled", translate("Enable"))
o.default = 0
o.rmempty = false

type = s:option(ListValue, "type", translate("Type"))
type:value("IKEv2", "IKEv2/IPSec PSK")
type:value("IKEv1", "IPSec Xauth PSK")
type.default = "IKEv2"

o = s:option(Value, "clientip", translate("VPN Client IP"))
o.description = translate("VPN Client reserved started IP addresses with the same subnet mask, such as: 192.168.100.10/24")
o.datatype = "ip4addr"
o.optional = false
o:depends("type", "IKEv2")
o:depends("type", "IKEv1")

secret = s:option(Value, "secret", translate("Preshared Key"))
secret.default = "ipsec"
secret.password = true
secret:depends("type", "IKEv1")

if sys.call("command -v xl2tpd > /dev/null") == 0 then
	type:value("L2TP", "L2TP/IPSec PSK")
	secret:depends("type", "L2TP")

	o = s:option(DummyValue, "l2tp_status", "L2TP " .. translate("Current Condition"))
	o.rawhtml = true
	o.cfgvalue = function(t, n)
		return '<font class="l2tp_status"></font>'
	end
	o:depends("type", "L2TP")

	o = s:option(Value, "l2tp_localip", "L2TP " .. translate("Server IP"))
	o.description = translate("VPN Server IP address, such as: 192.168.101.1")
	o.datatype = "ip4addr"
	o.default = "192.168.101.1"
	o.placeholder = o.default
	o:depends("type", "L2TP")

	o = s:option(Value, "l2tp_remoteip", "L2TP " .. translate("Client IP"))
	o.description = translate("VPN Client IP address range, such as: 192.168.101.10-20")
	o.default = "192.168.101.10-20"
	o.placeholder = o.default
	o:depends("type", "L2TP")

--[[
	if sys.call("ls -L /usr/lib/ipsec/libipsec* 2>/dev/null >/dev/null") == 0 then 
		o = s:option(DummyValue, "_o", " ")
		o.rawhtml = true
		o.cfgvalue = function(t, n)
			return string.format('<a style="color: red">%s</a>', translate("L2TP/IPSec is not compatible with kernel-libipsec, which will disable this module."))
		end
		o:depends("type", "L2TP")
	end
]]--
end

return m
