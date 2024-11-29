--[[
LuCI - Lua Configuration Interface
]]--

local taskd = require "luci.model.tasks"
local docker = require "luci.docker"
local istoredup_model = require "luci.model.istoredup"
local m, s, o

m = taskd.docker_map("istoredup", "istoredup", "/usr/libexec/istorec/istoredup.sh",
	translate("iStoreDup"),
	translate("A duplica of iStoreOS.")
		.. translate("Official website:") .. ' <a href=\"https://www.istoreos.com/\" target=\"_blank\">https://www.istoreos.com/</a>')

local dk = docker.new({socket_path="/var/run/docker.sock"})
local dockerd_running = dk:_ping().code == 200
local docker_info = dockerd_running and dk:info().body or {}
local docker_aspace = 0
if docker_info.DockerRootDir then
	local statvfs = nixio.fs.statvfs(docker_info.DockerRootDir)
	docker_aspace = statvfs and (statvfs.bavail * statvfs.bsize) or 0
end

s = m:section(SimpleSection, translate("Service Status"), translate("iStoreDup status:"))
s:append(Template("istoredup/status"))

s = m:section(TypedSection, "istoredup", translate("Setup"), 
		(docker_aspace < 2147483648 and
		(translate("The free space of Docker is less than 2GB, which may cause the installation to fail.") 
		.. "<br>") or "") .. translate("The following parameters will only take effect during installation or upgrade:"))
s.addremove=false
s.anonymous=true

o = s:option(Value, "image_name", translate("Image").."<b>*</b>")
o.rmempty = false
o.datatype = "string"
o:value("linkease/istoreduprk35xx:latest", "linkease/istoreduprk35xx:latest")
o:value("linkease/istoredupx86_64:latest", "linkease/istoredupx86_64:latest")
if "x86_64" == docker_info.Architecture then
  o.default = "linkease/istoredupx86_64:latest"
else
  o.default = "linkease/istoreduprk35xx:latest"
end

o = s:option(Value, "time_zone", translate("Timezone"))
o.datatype = "string"
o:value("Asia/Shanghai", "Asia/Shanghai")

return m
