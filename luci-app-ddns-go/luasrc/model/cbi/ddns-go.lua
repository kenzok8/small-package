-- Copyright (C) 2021-2022  sirpdboy  <herboy2008@gmail.com> https://github.com/sirpdboy/luci-app-ddns-go

local m, s ,o

m = Map("ddns-go")
m.title = translate("DDNS-GO")
m.description = translate("DDNS-GO automatically obtains your public IPv4 or IPv6 address and resolves it to the corresponding domain name service.")..translate("</br>For specific usage, see:")..translate("<a href=\'https://github.com/sirpdboy/luci-app-ddns-go.git' target=\'_blank\'>GitHub @sirpdboy/luci-app-ddns-go </a>")

m:section(SimpleSection).template = "ddns-go_status"

s = m:section(TypedSection, "basic", translate("Global Settings"))
s.addremove = false
s.anonymous = true

o = s:option(Flag,"enabled",translate("Enable"))
o.default = 0

o = s:option(Value, "port",translate("Set the DDNS-TO access port"))
o.datatype = "uinteger"
o.default=9876

o = s:option(Value, "time",translate("update interval"))
o.default=300

m.apply_on_parse = true
m.on_after_apply = function(self,map)
	luci.sys.exec("/etc/init.d/ddns-go restart")
end

return m
