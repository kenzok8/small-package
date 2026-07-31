local m, s

m = Map("ghttpd", translate("Ghttpd"), translate("Ghttpd"))
m:section(SimpleSection).template  = "ghttpd/status"

s=m:section(TypedSection, "ghttpd", translate("Global settings"))
s.addremove=false
s.anonymous=true

e = s:option(Flag, "enabled", translate("Enable"))
e.rmempty=false
e.default="1"


o = s:option(Value, "port", translate("HTTP Port").."<b>*</b>")
o.rmempty = false
o.default = "80"
o.datatype = "port"

return m
