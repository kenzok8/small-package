--[[
LuCI - Lua Configuration Interface
]]--

local taskd = require "luci.model.tasks"
local docker = require "luci.docker"
local openwebui_model = require "luci.model.openwebui"
local m, s, o

m = taskd.docker_map("openwebui", "openwebui", "/usr/libexec/istorec/openwebui.sh",
	translate("OpenWebUI"),
	translate("Open WebUI is an extensible, self-hosted AI interface that adapts to your workflow, all while operating entirely offline.")
		.. translate("Official website:") .. ' <a href=\"https://openwebui.com/\" target=\"_blank\">https://openwebui.com/</a>')

local dk = docker.new({socket_path="/var/run/docker.sock"})
local dockerd_running = dk:_ping().code == 200
local docker_info = dockerd_running and dk:info().body or {}
local docker_aspace = 0
if docker_info.DockerRootDir then
	local statvfs = nixio.fs.statvfs(docker_info.DockerRootDir)
	docker_aspace = statvfs and (statvfs.bavail * statvfs.bsize) or 0
end

s = m:section(SimpleSection, translate("Service Status"), translate("OpenWebUI status:"))
s:append(Template("openwebui/status"))

s = m:section(TypedSection, "main", translate("Setup"),
		(docker_aspace < 2147483648 and
		(translate("The free space of Docker is less than 2GB, which may cause the installation to fail.") 
		.. "<br>") or "") .. translate("The following parameters will only take effect during installation or upgrade:"))
s.addremove=false
s.anonymous=true

o = s:option(Value, "port", translate("Port").."<b>*</b>")
o.default = "3000"
o.datatype = "port"

o = s:option(Value, "image_name", translate("Image").."<b>*</b>")
o.rmempty = false
o.datatype = "string"
o:value("ghcr.io/open-webui/open-webui:main", "ghcr.io/open-webui/open-webui:main")
o:value("linkease/open-webui:main", "linkease/open-webui:main")
o.default = "linkease/open-webui:main"

local blocks = openwebui_model.blocks()
local home = openwebui_model.home()

o = s:option(Value, "config_path", translate("Config path").."<b>*</b>")
o.rmempty = false
o.datatype = "string"

local paths, default_path = openwebui_model.find_paths(blocks, home, "Configs")
for _, val in pairs(paths) do
  o:value(val, val)
end
o.default = default_path

return m
