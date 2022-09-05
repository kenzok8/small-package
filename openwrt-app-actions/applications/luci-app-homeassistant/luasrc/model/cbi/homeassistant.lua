--[[
LuCI - Lua Configuration Interface
]]--

local taskd = require "luci.model.tasks"
local m, s, o

m = taskd.docker_map("homeassistant", "homeassistant", "/usr/libexec/istorec/homeassistant.sh",
	translate("Home Assistant"),
	translate("Open source home automation that puts local control and privacy first. Powered by a worldwide community of tinkerers and DIY enthusiasts.")
		.. translate("Official website:") .. ' <a href=\"https://www.home-assistant.io/\" target=\"_blank\">https://www.home-assistant.io/</a>')

s = m:section(SimpleSection, translate("Service Status"), translate("Home Assistant status:"))
s:append(Template("homeassistant/status"))

s = m:section(TypedSection, "homeassistant", translate("Setup"), translate("The following parameters will only take effect during installation or upgrade:"))
s.addremove=false
s.anonymous=true

o = s:option(Value, "config_path", translate("Config path").."<b>*</b>")
o.rmempty = false
o.default = "/root/homeassistant/config"
o.datatype = "string"

return m
