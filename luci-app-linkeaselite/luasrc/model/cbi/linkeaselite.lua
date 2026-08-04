local m, s
local sys = require "luci.sys"

m = Map("linkeaselite", translate("LinkEaseLite"), translate("LinkEaseLite is an efficient data transfer tool for small-memory devices."))
m:section(SimpleSection).template = "linkeaselite_status"

m.on_after_commit = function(self)
	sys.call("/etc/init.d/linkeaselite restart >/dev/null 2>&1")
end

s = m:section(TypedSection, "linkeaselite", translate("Global settings"))
s.addremove = false
s.anonymous = true

s:option(Flag, "enabled", translate("Enable")).rmempty = false

local port = s:option(Value, "port", translate("Port"))
port.rmempty = false
port.datatype = "port"
port.default = "8897"

s:option(Flag, "allowPublic", translate("AllowPublic"), translate("Allowing access via public IP addresses can lead to insufficient security.")).rmempty = false

return m
