local d = require "luci.dispatcher"

m = Map("luci-app-pptp-server", translate("Users Manager"))
m.redirect = d.build_url("admin", "vpn", "pptpd", "users")

s = m:section(NamedSection, arg[1], "users", "")
s.addremove = false
s.anonymous = true

o = s:option(Flag, "enabled", translate("Enabled"))
o.default = 1
o.rmempty = false

o = s:option(Value, "username", translate("Username"))
o.placeholder = translate("Username")
o.rmempty = false

o = s:option(Value, "password", translate("Password"))
o.placeholder = translate("Password")
o.rmempty = false

o = s:option(Value, "ipaddress", translate("IP address"))
o.placeholder = translate("Automatically")
o.datatype = "ip4addr"
o.rmempty = true

o = s:option(DynamicList, "routes", translate("Static Routes"))
o.placeholder = "192.168.10.0/24"
o.datatype = "ipmask4"
o.rmempty = true

return m
