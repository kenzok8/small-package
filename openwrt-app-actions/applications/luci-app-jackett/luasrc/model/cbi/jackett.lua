--[[
LuCI - Lua Configuration Interface
]]--

local taskd = require "luci.model.tasks"
local m, s, o

m = taskd.docker_map("jackett", "jackett", "/usr/libexec/istorec/jackett.sh",
	translate("Jackett"),
	translate("Jackett is a single repository of maintained indexer scraping & translation logic - removing the burden from other apps.")
		.. translate("Official website:") .. ' <a href=\"https://github.com/Jackett/Jackett\" target=\"_blank\">https://github.com/Jackett/Jackett</a>')

s = m:section(SimpleSection, translate("Service Status"), translate("Jackett status:"))
s:append(Template("jackett/status"))

s = m:section(TypedSection, "jackett", translate("Setup"), translate("The following parameters will only take effect during installation or upgrade:"))
s.addremove=false
s.anonymous=true

o = s:option(Value, "port", translate("Port").."<b>*</b>")
o.rmempty = false
o.default = "9117"
o.datatype = "port"

o = s:option(Value, "config_path", translate("Config path").."<b>*</b>")
o.rmempty = false
o.datatype = "string"

o = s:option(Value, "save_path", translate("Torrent save path").."<b>*</b>", translate("Usually use the monitoring folder of the torrent download tool"))
o.rmempty = false
o.datatype = "string"

o = s:option(Flag, "auto_update", translate("Auto update"))
o.default = 1
o.rmempty = false

return m
