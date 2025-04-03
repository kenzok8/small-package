--[[
LuCI - Lua Configuration Interface
]]--

local taskd = require "luci.model.tasks"
local docker = require "luci.docker"
local oneapi_model = require "luci.model.oneapi"
local m, s, o

m = taskd.docker_map("oneapi", "oneapi", "/usr/libexec/istorec/oneapi.sh",
	translate("OneAPI"),
	translate("OneAPI is LLM API Management & Distribution System, supporting OpenAI, Azure, Anthropic Claude, Google Gemini, and DeepSeek. login: root/123456")
		.. translate("Official website:") .. ' <a href=\"https://openai.justsong.cn/\" target=\"_blank\">https://openai.justsong.cn/</a>')

local dk = docker.new({socket_path="/var/run/docker.sock"})
local dockerd_running = dk:_ping().code == 200
local docker_info = dockerd_running and dk:info().body or {}
local docker_aspace = 0
if docker_info.DockerRootDir then
	local statvfs = nixio.fs.statvfs(docker_info.DockerRootDir)
	docker_aspace = statvfs and (statvfs.bavail * statvfs.bsize) or 0
end

s = m:section(SimpleSection, translate("Service Status"), translate("OneAPI status:"))
s:append(Template("oneapi/status"))

s = m:section(TypedSection, "main", translate("Setup"),
		(docker_aspace < 2147483648 and
		(translate("The free space of Docker is less than 2GB, which may cause the installation to fail.") 
		.. "<br>") or "") .. translate("The following parameters will only take effect during installation or upgrade:"))
s.addremove=false
s.anonymous=true

o = s:option(Value, "port", translate("Port").."<b>*</b>")
o.default = "3005"
o.datatype = "port"
o:depends("hostnet", 0)

o = s:option(Value, "image_name", translate("Image").."<b>*</b>")
o.rmempty = false
o.datatype = "string"
o:value("justsong/one-api:latest", "justsong/one-api:latest")
o:value("justsong/one-api:v0.6.10", "justsong/one-api:v0.6.10")
o.default = "justsong/one-api:v0.6.10"

local blocks = oneapi_model.blocks()
local home = oneapi_model.home()

o = s:option(Value, "config_path", translate("Config path").."<b>*</b>")
o.rmempty = false
o.datatype = "string"

local paths, default_path = oneapi_model.find_paths(blocks, home, "Configs")
for _, val in pairs(paths) do
  o:value(val, val)
end
o.default = default_path

return m
