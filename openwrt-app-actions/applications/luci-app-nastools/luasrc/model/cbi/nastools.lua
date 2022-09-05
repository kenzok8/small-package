--[[
LuCI - Lua Configuration Interface
]]--

local taskd = require "luci.model.tasks"
local m, s, o

m = taskd.docker_map("nastools", "nastools", "/usr/libexec/istorec/nastools.sh",
	translate("NasTools"),
	translate("NasTools is a tools for resource aggregation running in NAS.")
		.. translate("Official website:") .. ' <a href=\"https://github.com/jxxghp/nas-tools\" target=\"_blank\">https://github.com/jxxghp/nas-tools</a>')

s = m:section(SimpleSection, translate("Service Status"), translate("NasTools status:"))
s:append(Template("nastools/status"))

s = m:section(TypedSection, "nastools", translate("Setup"), translate("The following parameters will only take effect during installation or upgrade:"))
s.addremove=false
s.anonymous=true

o = s:option(Value, "http_port", translate("Port").."<b>*</b>")
o.rmempty = false
o.default = "3003"
o.datatype = "port"

o = s:option(Value, "config_path", translate("Config path").."<b>*</b>")
o.rmempty = false
o.datatype = "string"

o = s:option(Flag, "auto_upgrade", translate("Auto update"))
o.default = 1
o.rmempty = false

return m
