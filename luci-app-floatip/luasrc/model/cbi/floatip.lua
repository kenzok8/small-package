local m, s, o

m = Map("floatip", translate("FloatingGateway"), translate("FloatingGateway allows two gateway within one lan which can switch between each other in case of a failure.")
	.. "<br>" .. translate("Before using the FloatingGateway, ensure that the LAN interface is static address.")
	.. "<br>" .. translate("Note that this service is actually a floating IP implementation. It only configures the IP address and does not modify the gateway advertised by the DHCP service, because the DHCP service is not necessarily provided by the local machine. It is named floating gateway because this is the most common usage scenario."))

m:section(SimpleSection).template  = "floatip_status"

s=m:section(NamedSection, "main", translate("Global settings"))
s.anonymous=true

o = s:option(Flag, "enabled", translate("Enable"))
o.rmempty = false

o = s:option(ListValue, "role", translate("Node Role"))
o.rmempty = false
o.widget = "select"
o:value("main", translate("FG Preempt Node"))
o:value("fallback", translate("FG Fallback Node"))

o = s:option(Value, "set_ip", translate("Floating Gateway IP"), translate("This IP must be within any subnet of the LAN interface"))
o.rmempty = false
o.datatype = "or(ip4addr,cidr4)"

o = s:option(Value, "check_ip", translate("FG Preempt Node IP"))
o.datatype = "ip4addr"
o:depends("role", "fallback")

o = s:option(Value, "check_url", translate("Check URL"), translate("If status code of the URL is not 2xx, then release the floating IP and disable LAN port pinging"))
o:depends("role", "main")

o = s:option(Value, "check_url_timeout", translate("Check URL Timeout (s)"), translate("Default is 5 seconds if not set"))
o.datatype = "uinteger"
o:depends("role", "main")

return m
