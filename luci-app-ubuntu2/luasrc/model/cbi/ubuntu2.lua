--[[
LuCI - Lua Configuration Interface
]]--

local taskd = require "luci.model.tasks"
local docker = require "luci.docker"
local ubuntu2_model = require "luci.model.ubuntu2"
local m, s, o

m = taskd.docker_map("ubuntu2", "ubuntu2", "/usr/libexec/istorec/ubuntu2.sh",
	translate("Ubuntu2"),
	translate("Ubuntu2 is a high-Performance ubuntu with web remote desktop. [username: abc, password is empty]")
		.. translate("Official website:") .. ' <a href=\"https://www.kasmweb.com\" target=\"_blank\">https://www.kasmweb.com</a>')

local dk = docker.new({socket_path="/var/run/docker.sock"})
local dockerd_running = dk:_ping().code == 200
local docker_info = dockerd_running and dk:info().body or {}
local docker_aspace = 0
if docker_info.DockerRootDir then
        local statvfs = nixio.fs.statvfs(docker_info.DockerRootDir)
        docker_aspace = statvfs and (statvfs.bavail * statvfs.bsize) or 0
end

s = m:section(SimpleSection, translate("Service Status"), translate("Ubuntu2 status:"))
s:append(Template("ubuntu2/status"))

s = m:section(TypedSection, "main", translate("Setup"), translate("The following parameters will only take effect during installation or upgrade:"))
s.addremove=false
s.anonymous=true

o = s:option(Value, "https_port", translate("HTTPS Port").."<b>*</b>")
o.default = "3001"
o.datatype = "port"

o = s:option(Value, "image_name", translate("Image").."<b>*</b>")
o.rmempty = false
o.datatype = "string"
if "x86_64" == docker_info.Architecture then
  o:value("linkease/desktop-ubuntu2-standard-amd64:latest", "Standard-AMD64")
  o.default = "linkease/desktop-ubuntu2-standard-amd64:latest"
else
  o:value("linkease/desktop-ubuntu2-standard-arm64:latest", "Standard-ARM64")
  o.default = "linkease/desktop-ubuntu2-standard-arm64:latest"
end

o = s:option(Value, "password", "PASSWORD")
o.password = true
o.datatype = "string"

local blocks = ubuntu2_model.blocks()
local home = ubuntu2_model.home()

o = s:option(Value, "config_path", translate("Config path").."<b>*</b>")
o.rmempty = false
o.datatype = "string"

local paths, default_path = ubuntu2_model.find_paths(blocks, home, "Configs")
for _, val in pairs(paths) do
  o:value(val, val)
end
o.default = default_path

return m
