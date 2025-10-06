--[[
LuCI - Lua Configuration Interface
]]--

local taskd = require "luci.model.tasks"
local docker = require "luci.docker"
local istorepanel_model = require "luci.model.istorepanel"
local m, s, o

m = taskd.docker_map("istorepanel", "istorepanel", "/usr/libexec/istorec/istorepanel.sh",
	translate("1Panel"),
	translate("1Panel is the new generation Linux server maintenance panel.")
		.. translate("Official website:") .. ' <a href=\"https://1panel.cn/\" target=\"_blank\">https://1panel.cn/</a>')

local dk = docker.new({socket_path="/var/run/docker.sock"})
local dockerd_running = dk:_ping().code == 200
local docker_info = dockerd_running and dk:info().body or {}
local docker_aspace = 0
if docker_info.DockerRootDir then
	local statvfs = nixio.fs.statvfs(docker_info.DockerRootDir)
	docker_aspace = statvfs and (statvfs.bavail * statvfs.bsize) or 0
end

s = m:section(SimpleSection, translate("Service Status"), translate("1Panel status:"))
s:append(Template("istorepanel/status"))

s = m:section(TypedSection, "main", translate("Setup"),
		(docker_aspace < 2147483648 and
		(translate("The free space of Docker is less than 2GB, which may cause the installation to fail.") 
		.. "<br>") or "") .. translate("The following parameters will only take effect during installation or upgrade:"))
s.addremove=false
s.anonymous=true

o = s:option(Value, "port", translate("Port").."<b>*</b>")
o.default = "8063"
o.datatype = "port"
o:depends("hostnet", 0)

o = s:option(Value, "username", "username")
o.datatype = "string"
o.default = '1panel'

o = s:option(Value, "password", "password")
o.password = true
o.datatype = "string"
o.default = "password"

o = s:option(Value, "ver", "version")
o.datatype = "string"
o:value("v1.10.10-lts", "v1.10.10-lts")
o:value("v1.10.11-lts", "v1.10.11-lts")
o:value("v1.10.28-lts", "v1.10.28-lts")
o.default = 'v1.10.28-lts'

o = s:option(Value, "image_name", translate("Image").."<b>*</b>")
o.rmempty = false
o.datatype = "string"
o:value("linkease/istorepanel:latest", "linkease/istorepanel:latest")
o.default = "linkease/istorepanel:latest"

local blocks = istorepanel_model.blocks()
local home = istorepanel_model.home()

o = s:option(Value, "config_path", translate("Config path").."<b>*</b>")
o.rmempty = false
o.datatype = "string"

local paths, default_path = istorepanel_model.find_paths(blocks, home, "Configs")
for _, val in pairs(paths) do
  o:value(val, val)
end
o.default = default_path

o = s:option(Flag, "include_host", translate("Include root path"))
o.rmempty = false

return m
