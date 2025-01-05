--[[
LuCI - Lua Configuration Interface
]]--

local taskd = require "luci.model.tasks"
local pve_model = require "luci.model.pve"
local m, s, o

m = taskd.docker_map("pve", "pve", "/usr/libexec/istorec/pve.sh",
	translate("Proxmox"),
	translate("Proxmox in iStoreOS.") .. " login: root/password. " 
		.. translate("Official website:") .. ' <a href=\"https://pve.proxmox.com/\" target=\"_blank\">https://pve.proxmox.com/</a>')

s = m:section(SimpleSection, translate("Service Status"), translate("PVE status:"))
s:append(Template("pve/status"))

s = m:section(TypedSection, "pve", translate("Setup"), translate("The following parameters will only take effect during installation or upgrade:"))
s.addremove=false
s.anonymous=true

o = s:option(Value, "http_port", translate("HTTP Port").."<b>*</b>")
o.default = "8006"
o.datatype = "port"

o = s:option(Value, "image_name", translate("Image").."<b>*</b>")
o.rmempty = false
o.datatype = "string"
o:value("linkease/pve:latest", "linkease/pve:latest")
o:value("linkease/pve:8.3.2", "linkease/pve:8.3.2")
o.default = "linkease/pve:latest"

local blocks = pve_model.blocks()
local home = pve_model.home()

o = s:option(Value, "config_path", translate("Config path").."<b>*</b>")
o.rmempty = false
o.datatype = "string"

local paths, default_path = pve_model.find_paths(blocks, home, "Configs")
for _, val in pairs(paths) do
  o:value(val, val)
end
o.default = default_path

o = s:option(Value, "root_pwd", "ROOT_PASSWORD")
o.password = true
o.datatype = "string"

o = s:option(Value, "time_zone", translate("Timezone"))
o.datatype = "string"
o:value("Asia/Shanghai", "Asia/Shanghai")

return m
