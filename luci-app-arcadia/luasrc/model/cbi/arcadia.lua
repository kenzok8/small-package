--[[
LuCI - Lua Configuration Interface
]]--

local taskd = require "luci.model.tasks"
local arcadia_model = require "luci.model.arcadia"
local m, s, o

m = taskd.docker_map("arcadia", "arcadia", "/usr/libexec/istorec/arcadia.sh",
	translate("Arcadia"),
	translate("Arcadia · One-Stop Code Automation & DevOps Platform.")
		.. translate("Official website:") .. ' <a href=\"https://arcadia.cool\" target=\"_blank\">https://arcadia.cool</a>'
		.. "<dl><dt>" .. translate("Arcadia is designed for script-based programming and operations scenarios. It provides capabilities including scheduled task scheduling, multi-language code execution, a comprehensive file system, and well-designed underlying CLI commands. It is suitable for individual developers and small to medium-sized teams who seek to improve development and operations efficiency through automated scripting.") .. "</dt>"
		.. "<dt>" .. translate("The initial username and password are 'useradmin' and 'passwd' respectively.") .. "</dt>"
		.. "</dl>")

s = m:section(SimpleSection, translate("Service Status"), translate("Arcadia status:"))
s:append(Template("arcadia/status"))

s = m:section(TypedSection, "arcadia", translate("Setup"),
		translate("The initial installation of Arcadia requires at least 2GB of space, please make sure that the Docker data directory has enough space. It is recommended to migrate Docker to a hard drive before installing Arcadia.") 
		.. "<br>" .. translate("The following parameters will only take effect during installation or upgrade:"))
s.addremove=false
s.anonymous=true

o = s:option(Value, "image", translate("Docker Image"))
o.datatype = "string"
o:value("", translate("Default"))
o:value("supermanito/arcadia", "supermanito/arcadia")
o:value("registry.cn-hangzhou.aliyuncs.com/supermanito/arcadia", "registry.cn-hangzhou.aliyuncs.com/supermanito/arcadia")
o:value("docker.m.daocloud.io/supermanito/arcadia", "docker.m.daocloud.io/supermanito/arcadia")
o:value("docker.1ms.run/supermanito/arcadia", "docker.1ms.run/supermanito/arcadia")
o:value("docker.xuanyuan.me/supermanito/arcadia", "docker.xuanyuan.me/supermanito/arcadia")

o = s:option(Flag, "hostnet", translate("Host network"), translate("Arcadia running in host network, port is always 5678 if enabled"))
o.default = 0
o.rmempty = false

o = s:option(Value, "port", translate("Port").."<b>*</b>")
o.default = "5678"
o.datatype = "port"
o:depends("hostnet", 0)

local blocks = arcadia_model.blocks()
local home = arcadia_model.home()

o = s:option(Value, "config_path", translate("Config path").."<b>*</b>")
o.rmempty = false
o.datatype = "string"

local paths, default_path = arcadia_model.find_paths(blocks, home, "Configs")
for _, val in pairs(paths) do
  o:value(val, val)
end
o.default = default_path

return m
