--[[
LuCI - Lua Configuration Interface
]]--

local taskd = require "luci.model.tasks"
local docker = require "luci.docker"
local uptimekuma_model = require "luci.model.uptimekuma"
local m, s, o

m = taskd.docker_map("uptimekuma", "uptimekuma", "/usr/libexec/istorec/uptimekuma.sh",
	translate("UptimeKuma"),
	translate("Uptime Kuma is an easy-to-use self-hosted monitoring tool.")
		.. translate("Official website:") .. ' <a href=\"https://uptime.kuma.pet/\" target=\"_blank\">https://uptime.kuma.pet/</a>')

local dk = docker.new({socket_path="/var/run/docker.sock"})
local dockerd_running = dk:_ping().code == 200
local docker_info = dockerd_running and dk:info().body or {}
local docker_aspace = 0
if docker_info.DockerRootDir then
	local statvfs = nixio.fs.statvfs(docker_info.DockerRootDir)
	docker_aspace = statvfs and (statvfs.bavail * statvfs.bsize) or 0
end

s = m:section(SimpleSection, translate("Service Status"), translate("UptimeKuma status:"))
s:append(Template("uptimekuma/status"))

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
o:value("louislam/uptime-kuma:1", "louislam/uptime-kuma:1")
o:value("louislam/uptime-kuma:beta", "louislam/uptime-kuma:beta")
o.default = "louislam/uptime-kuma:1"

local blocks = uptimekuma_model.blocks()
local home = uptimekuma_model.home()

o = s:option(Value, "config_path", translate("Config path").."<b>*</b>")
o.rmempty = false
o.datatype = "string"

local paths, default_path = uptimekuma_model.find_paths(blocks, home, "Configs")
for _, val in pairs(paths) do
  o:value(val, val)
end
o.default = default_path

return m
