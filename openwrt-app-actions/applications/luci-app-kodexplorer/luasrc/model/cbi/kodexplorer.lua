--[[
LuCI - Lua Configuration Interface
]]--

local taskd = require "luci.model.tasks"
local m, s, o

m = taskd.docker_map("kodexplorer", "kodexplorer", "/usr/libexec/istorec/kodexplorer.sh",
	translate("KodExplorer"),
	translate("Private cloud online document management solution based on web technology.")
		.. translate("Official website:") .. ' <a href=\"https://kodcloud.com/\" target=\"_blank\">https://kodcloud.com/</a>')

s = m:section(SimpleSection, translate("Service Status"), translate("KodExplorer status:"))
s:append(Template("kodexplorer/status"))

s = m:section(TypedSection, "kodexplorer", translate("Setup"), translate("The following parameters will only take effect during installation or upgrade:"))
s.addremove=false
s.anonymous=true

o = s:option(Value, "port", translate("Port").."<b>*</b>")
o.rmempty = false
o.default = "8081"
o.datatype = "port"

o = s:option(Value, "cache_path", translate("Config path").."<b>*</b>")
o.rmempty = false
o.default = "/mnt/sda1/kodexplorer"
o.datatype = "string"

return m
