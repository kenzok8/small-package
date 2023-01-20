--[[
LuCI - Lua Configuration Interface
]]--

local m, s, o

m = Map("airconnect", translate("AirConnect"), translate("Use AirPlay to stream to UPnP/Sonos &amp; Chromecast devices"))

s = m:section(TypedSection, "main", translate("Global Settings"))
s.addremove=false
s.anonymous=true

o = s:option(Flag, "enabled", translate("Enable"))
o.default = 0
o.rmempty = false

o = s:option(Value, "interface", translate("Interface"), translate("Network interface for serving, usually LAN"))
o.template = "cbi/network_netlist"
o.nocreate = true
o.default = "lan"
o.datatype = "string"

o = s:option(Flag, "aircast", translate("Supports Chromecast"), translate("Select this if you have Chromecast devices"))
o.default = 1
o.rmempty = false

o = s:option(Flag, "airupnp", translate("Supports UPnP/Sonos"), translate("Select this if you have UPnP/Sonos devices"))
o.default = 1
o.rmempty = false

return m
