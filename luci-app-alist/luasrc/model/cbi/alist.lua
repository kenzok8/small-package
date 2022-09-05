local m, s
local sys  = require "luci.sys"

if sys.call("pidof alist >/dev/null") == 0 then
	local password = sys.exec("/usr/bin/alist --conf /etc/alist/config.json -password | awk '{print $3}'")
	m = Map("alist", translate("Alist"), translate("A file list program that supports multiple storage.") .. " " .. translate("manage password:") .. "<font color=\"green\">" .. password .. "</font>" .. "<br/>" .. [[<a href="https://alist-doc.nn.ci/docs/driver/native" target="_blank">]] .. translate("User Manual") .. [[</a>]])
else
	m = Map("alist", translate("Alist"), translate("A file list program that supports multiple storage.") .. "<br/>" .. [[<a href="https://alist-doc.nn.ci/docs/driver/native" target="_blank">]] .. translate("User Manual") .. [[</a>]])
end

m:section(SimpleSection).template  = "alist_status"

s = m:section(TypedSection, "alist", translate("Global settings"))
s.addremove = false
s.anonymous = true

o = s:option(Flag, "enabled", translate("Enable"))
o.rmempty = false

o = s:option(Value, "port", translate("Port"))
o.datatype = "and(port,min(1))"
o.rmempty = false

o = s:option(Flag, "ssl", translate("Enable SSL"))
o.rmempty=false

o = s:option(Value,"ssl_cert", translate("SSL cert"), translate("SSL certificate file path"))
o:depends("ssl", "1")
o.datatype = "string"
o.rmempty = true

o = s:option(Value,"ssl_key", translate("SSL key"), translate("SSL key file path"))
o:depends("ssl", "1")
o.datatype = "string"
o.rmempty = true

s = m:section(TypedSection, "alist", translate("Cache settings"))
s.addremove = false
s.anonymous = true

o = s:option(Value, "expiration", translate("Cache invalidation time (unit: minutes)"))
o.datatype = "and(uinteger,min(1))"
o.rmempty = false

o = s:option(Value, "cleanup_interval", translate("Clear the invalidation cache interval (unit: minutes)"))
o.datatype = "and(uinteger,min(1))"
o.rmempty = false

o = s:option(Value, "temp_dir", translate("Cache directory"))
o.datatype = "string"
o.rmempty = false

return m
