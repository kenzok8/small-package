--[[
LuCI - Lua Configuration Interface
]]--

local taskd = require "luci.model.tasks"
local mfun_model = require "luci.model.mfun"
local m, s, o

m = taskd.docker_map("mfun", "mfun", "/usr/libexec/istorec/mfun.sh",
	translate("Mfun"),
	translate("Mfun is an multimedia program.")
	.. '<br/>'
	.. translate("Default User") 
	.. ': admin password')

s = m:section(SimpleSection, translate("Service Status"), translate("Mfun status:"))
s:append(Template("mfun/status"))

s = m:section(TypedSection, "mfun", translate("Setup"), translate("The following parameters will only take effect during installation or upgrade:"))
s.addremove=false
s.anonymous=true

o = s:option(Value, "port", translate("HTTP Port").."<b>*</b>")
o.rmempty = false
o.default = "8990"
o.datatype = "port"

local blocks = mfun_model.blocks()
local home = mfun_model.home()

o = s:option(Value, "config_path", translate("Config path").."<b>*</b>")
o.rmempty = false
o.datatype = "string"

local paths, default_path = mfun_model.find_paths(blocks, home, "Configs")
for _, val in pairs(paths) do
  o:value(val, val)
end
o.default = default_path

o = s:option(Value, "tmp_path", translate("Tmp path").."<b>*</b>")
o.rmempty = false
o.datatype = "string"

local paths, default_path = mfun_model.find_paths(blocks, home, "Caches")
for _, val in pairs(paths) do
  o:value(val, val)
end
o.default = default_path

return m
