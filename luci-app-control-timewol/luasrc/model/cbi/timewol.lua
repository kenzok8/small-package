local i = require "luci.sys"

t = Map("timewol", translate("Timed network wake-up"), translate("Wake up your LAN device regularly"))

e = t:section(TypedSection, "basic", translate("Basic setting"))
e.anonymous = true

o = e:option(Flag, "enable", translate("Enable"))
o.rmempty = false

e = t:section(TypedSection, "macclient", translate("Client setting"))
e.template = "cbi/tblsection"
e.anonymous = true
e.addremove = true

nolimit_mac = e:option(Value, "macaddr", translate("MAC Address"))
nolimit_mac.rmempty = false
i.net.mac_hints(function(e, t) nolimit_mac:value(e, "%s (%s)" % {e, t}) end)
nolimit_eth = e:option(Value, "maceth", translate("Network interface"))
nolimit_eth.rmempty = false
for t, e in ipairs(i.net.devices()) do if e ~= "lo" then nolimit_eth:value(e) end end

a = e:option(Value, "minute", translate("minutes"))
a.optional = false

a = e:option(Value, "hour", translate("hour"))
a.optional = false

a = e:option(Value, "day", translate("day"))
a.optional = false

a = e:option(Value, "month", translate("month"))
a.optional = false

a = e:option(Value, "weeks", translate("weeks"))
a.optional = false

return t
