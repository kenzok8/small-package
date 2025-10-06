m = Map("banmac", translate("BanMac"))

local banlist = m:section(TypedSection, "banlist", translate("log"))
banlist.anonymous = true

local bmdetails = "/etc/banmaclog"
local BMNXFS = require "nixio.fs"
bmd = banlist:option(TextValue, "details")
bmd.rows = 6
bmd.wrap = "off"
bmd.cfgvalue = function(self, section)
	return BMNXFS.readfile(bmdetails) or ""
end
bmd.write = function(self, section, value)
	BMNXFS.writefile(bmdetails, value:gsub("\r\n", "\n"))
end

s = m:section(TypedSection, "banmac", "")
s.anonymous = false
s.addremove = true

s:tab("banmactab", translate("BanMac Menu"))

banlist_mac = s:taboption("banmactab", Value, "banlist_mac", translate("MAC address")) 
banlist_mac.rmempty = true
banlist_mac.datatype = "macaddr"
luci.sys.net.mac_hints(function(mac, name)
	banlist_mac:value(mac, "%s (%s)" %{ mac, name })
end)

ban_mac = s:taboption("banmactab", Button, "ban_mac", translate("One-Click BAN")) 
ban_mac.rmempty = false
ban_mac.inputstyle = "apply"
function ban_mac.write(self, section)
	luci.util.exec("cp /usr/banmac/ban.sh /tmp/ban_OO!%!OO" ..section.. "_.sh >/dev/null 2>&1 &")
	luci.util.exec("/tmp/ban_OO!%!OO" ..section.. "_.sh >/dev/null 2>&1 &")
end

unban_mac = s:taboption("banmactab", Button, "unban_mac", translate("One-Click UnBAN")) 
unban_mac.rmempty = false
unban_mac.inputstyle = "apply"
function unban_mac.write(self, section)
	luci.util.exec("cp /usr/banmac/unban.sh /tmp/unban_OO!%!OO" ..section.. "_.sh >/dev/null 2>&1 &")
	luci.util.exec("/tmp/unban_OO!%!OO" ..section.. "_.sh >/dev/null 2>&1 &")
end

return m
