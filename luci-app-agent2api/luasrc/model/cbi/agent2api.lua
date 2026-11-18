--[[
LuCI - Lua Configuration Interface
]]--

local taskd = require "luci.model.tasks"
local agent2api_model = require "luci.model.agent2api"
local m, s, o

m = taskd.docker_map("agent2api", "agent2api", "/usr/libexec/istorec/agent2api.sh",
  translate("Agent2API"),
  translate("Agent2API is an AI routing gateway with Agent client takeover.")
    .. translate("Official website:") .. ' <a href="https://github.com/aimod-cc/Agent2API" target="_blank">https://github.com/aimod-cc/Agent2API</a>')

s = m:section(SimpleSection, translate("Service Status"), translate("Agent2API status:"))
s:append(Template("agent2api/status"))

s = m:section(TypedSection, "main", translate("Setup"), translate("The following parameters will only take effect during installation or upgrade:"))
s.addremove=false
s.anonymous=true

o = s:option(Value, "http_port", translate("HTTP Port").."<b>*</b>")
o.rmempty = false
o.default = "3065"
o.datatype = "port"

o = s:option(Value, "image_name", translate("Docker Image").."<b>*</b>")
o.rmempty = false
o.datatype = "string"
o:value("aimodcc/agent2api:latest", "aimodcc/agent2api:latest")
o.default = "aimodcc/agent2api:latest"

o = s:option(Flag, "install_accelerated", translate("KSpeeder accelerated install"), translate("Use KSpeeder/iStoreEnhance to accelerate image pull when enabled"))
o.default = 1
o.rmempty = false

local blocks = agent2api_model.blocks()
local home = agent2api_model.home()

o = s:option(Value, "config_path", translate("Config path").."<b>*</b>")
o.rmempty = false
o.datatype = "string"

local paths, default_path = agent2api_model.find_paths(blocks, home, "Configs")
for _, val in pairs(paths) do
  o:value(val, val)
end
o.default = default_path

return m
