--[[
LuCI - Lua Configuration Interface
]]--

local taskd = require "luci.model.tasks"
local xteve_model = require "luci.model.xteve"
local m, s, o

m = taskd.docker_map("xteve", "xteve", "/usr/libexec/istorec/xteve.sh",
	translate("Xteve"),
	translate("Xteve is M3U Proxy for Plex DVR and Emby Live TV.")
		.. translate("Official website:") .. ' <a href=\"https://github.com/xteve-project/xTeVe\" target=\"_blank\">https://github.com/xteve-project/xTeVe</a>')

s = m:section(SimpleSection, translate("Service Status"), translate("Xteve status:"))
s:append(Template("xteve/status"))

s = m:section(TypedSection, "main", translate("Setup"), translate("The following parameters will only take effect during installation or upgrade:"))
s.addremove=false
s.anonymous=true

o = s:option(Value, "port", translate("Port").."<b>*</b>")
o.default = "32400"
o.datatype = "port"
o:depends("hostnet", 0)

o = s:option(Value, "image_name", translate("Image").."<b>*</b>")
o.rmempty = false
o.datatype = "string"
o:value("alturismo/xteve_guide2go", "alturismo/xteve_guide2go")
o.default = "alturismo/xteve_guide2go"

local blocks = xteve_model.blocks()
local home = xteve_model.home()

o = s:option(Value, "config_path", translate("Config path").."<b>*</b>")
o.rmempty = false
o.datatype = "string"

local paths, default_path = xteve_model.find_paths(blocks, home, "Configs")
for _, val in pairs(paths) do
  o:value(val, val)
end
o.default = default_path

o = s:option(Value, "time_zone", translate("Timezone"))
o.datatype = "string"
o:value("Asia/Shanghai", "Asia/Shanghai")

return m
