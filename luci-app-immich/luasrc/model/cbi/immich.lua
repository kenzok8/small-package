--[[
LuCI - Lua Configuration Interface
]]--

local taskd = require "luci.model.tasks"
local docker = require "luci.docker"
local immich_model = require "luci.model.immich"
local m, s, o

m = taskd.docker_map("immich", "immich", "/usr/libexec/istorec/immich.sh",
	translate("Immich"),
	translate("Immich is a self-host photo and video management solution.")
		.. translate("Official website:") .. ' <a href=\"https://immich.app/\" target=\"_blank\">https://immich.app/</a>')

local dk = docker.new({socket_path="/var/run/docker.sock"})
local dockerd_running = dk:_ping().code == 200
local docker_info = dockerd_running and dk:info().body or {}
local docker_aspace = 0
if docker_info.DockerRootDir then
	local statvfs = nixio.fs.statvfs(docker_info.DockerRootDir)
	docker_aspace = statvfs and (statvfs.bavail * statvfs.bsize) or 0
end

s = m:section(SimpleSection, translate("Service Status"), translate("Immich status:"))
s:append(Template("immich/status"))

s = m:section(TypedSection, "main", translate("Setup"),
		(docker_aspace < 2147483648 and
		(translate("The free space of Docker is less than 2GB, which may cause the installation to fail.") 
		.. "<br>") or "") .. translate("The following parameters will only take effect during installation or upgrade:"))
s.addremove=false
s.anonymous=true

o = s:option(Value, "port", translate("Port").."<b>*</b>")
o.default = "2283"
o.datatype = "port"

o = s:option(Value, "image_ver", translate("Image").."<b>*</b>")
o.rmempty = false
o.datatype = "string"
o.default = "release"
o:value("release", "release")

local blocks = immich_model.blocks()
local home = immich_model.home()

o = s:option(Value, "config_path", translate("Config path").."<b>*</b>")
o.rmempty = false
o.datatype = "string"

local paths, default_path = immich_model.find_paths(blocks, home, "Configs")
for _, val in pairs(paths) do
  o:value(val, val)
end
o.default = default_path

o = s:option(Value, "db_password", "DB_PASSWORD".."<b>*</b>")
o.rmempty = false
o.default = "postgres"
o.datatype = "string"
o.password = true

return m
