--[[
LuCI - Lua Configuration Interface
]]--

local taskd = require "luci.model.tasks"
local kodexplorer_model = require "luci.model.kodexplorer"
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

o = s:option(Value, "image_name", translate("Image").."<b>*</b>")
o.rmempty = false
o.datatype = "string"
o:value("kodcloud/kodbox:latest", "kodcloud/kodbox:latest")
o.default = "kodcloud/kodbox:latest"

local blocks = kodexplorer_model.blocks()
local home = kodexplorer_model.home()

o = s:option(Value, "cache_path", translate("Config path").."<b>*</b>")
o.rmempty = false
o.datatype = "string"

local paths, default_path = kodexplorer_model.find_paths(blocks, home, "Configs")
for _, val in pairs(paths) do
  o:value(val, val)
end
o.default = default_path

return m
