local o = require "luci.sys"

a = Map("weburl", translate("URL Filter"), translate("Set keyword filtering here, can be any character in the URL, can filter such as video sites, QQ, thunder, Taobao..."))
a.template = "weburl/index"

t = a:section(TypedSection, "basic", translate("Running Status"))
t.anonymous = true

e = t:option(DummyValue, "weburl_status", translate("Running Status"))
e.template = "weburl/weburl"
e.value = translate("Collecting data...")

t = a:section(TypedSection, "basic", translate("Basic setting"), translate("In general, normal filtering works fine, but forced filtering uses more complex algorithms and leads to higher CPU usage."))
t.anonymous = true

e = t:option(Flag, "enable", translate("Enable"))
e.rmempty = false

e = t:option(Flag, "algos", translate("Forced filter"))
e.rmempty = false

t = a:section(TypedSection, "macbind", translate("Keyword setting"), translate("MAC addresses do not filter out all clients. For example, only specified clients are filtered out. Filtering time is optional."))
t.template = "cbi/tblsection"
t.anonymous = true
t.addremove = true

e = t:option(Flag, "enable", translate("Enable"))
e.rmempty = false

e = t:option(Value, "macaddr", translate("MAC Address"))
e.rmempty = true

o.net.mac_hints(function(t, a) e:value(t, "%s (%s)" % {t, a}) end)

e = t:option(Value, "timeon", translate("Start time"))
e.placeholder = "00:00"
e.rmempty = true

e = t:option(Value, "timeoff", translate("End time"))
e.placeholder = "23:59"
e.rmempty = true

e = t:option(Value, "keyword", translate("Keyword"))
e.rmempty = false

return a
