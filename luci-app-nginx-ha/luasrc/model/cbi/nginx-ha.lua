local m, s, o

if luci.sys.call("pgrep nginx >/dev/null") == 0 then
	m = Map("nginx-ha", translate("Nginx High Availability"), "%s - %s" %{translate("Nginx High Availability"), translate("RUNNING")})
else
	m = Map("nginx-ha", translate("Nginx High Availability"), "%s - %s" %{translate("Nginx High Availability"), translate("NOT RUNNING")})
end

s = m:section(TypedSection, "nginxha", translate("Settings"))
s.addremove = true

o = s:option(Flag, "enable", translate("Enable"))
o.rmempty     = false

o = s:option(Value, "listen", translate("Listen Address:Port"))
o.placeholder = "0.0.0.0:6666"
o.default     = "0.0.0.0:6666"
o.rmempty     = false

o = s:option(Value, "timeout", translate("Timeout Connect (ms)"))
o.placeholder = "1000"
o.default     = "1000"
o.datatype    = "range(33, 10000)"
o.rmempty     = false

o = s:option(Value, "retries", translate("Retries"))
o.placeholder = "1"
o.default     = "1"
o.datatype    = "range(1, 10)"
o.rmempty     = false


o = s:option(DynamicList, "upstreams", translate("UpStream Server"), translate("e.g. [123.123.123.123:65101 weight=1 max_fails=3 fail_timeout=30s]"))
o.placeholder = "123.123.123.123:65101 weight=1 max_fails=3 fail_timeout=30s"
o.rmempty     = false

return m
