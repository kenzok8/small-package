local o = require "luci.sys"

a = Map("webrestriction", translate("Access Control"), translate("Use the blacklist or whitelist mode to control whether a client in the list can connect to the Internet."))
a.template = "webrestriction/index"

e = a:section(TypedSection, "basic", translate("Running Status"))
e.anonymous = true

t = e:option(DummyValue, "webrestriction_status", translate("Running Status"))
t.template = "webrestriction/webrestriction"
t.value = translate("Collecting data...")

e = a:section(TypedSection, "basic", translate("Global setting"))
e.anonymous = true

t = e:option(Flag, "enable", translate("Enable"))
t.rmempty = false

t = e:option(ListValue, "limit_type", translate("Limit mode"))
t.default = "blacklist"
t:value("whitelist", translate("Whitelist"))
t:value("blacklist", translate("Blacklist"))

e = a:section(TypedSection, "macbind", translate("List setting"), translate("In blacklist mode, the client in the list is prohibited from connecting to the Internet. In whitelist mode, only the clients in the list can connect to the Internet."))
e.template = "cbi/tblsection"
e.anonymous = true
e.addremove = true

t = e:option(Flag, "enable", translate("Enable"))
t.rmempty = false

t = e:option(Value, "macaddr", translate("MAC Address"))
t.rmempty = true

o.net.mac_hints(function(e, a) t:value(e, "%s (%s)" % {e, a}) end)
return a
