--[[
LuCI - Lua Configuration Interface
]]--

local taskd = require "luci.model.tasks"
local m, s, o

m = taskd.docker_map("nextcloud", "nextcloud", "/usr/libexec/istorec/nextcloud.sh",
	translate("Nextcloud"),
	translate("A safe home for all your data. Access & share your files, calendars, contacts, mail & more from any device, on your terms.")
		.. translate("Official website:") .. ' <a href=\"https://nextcloud.com/\" target=\"_blank\">https://nextcloud.com/</a>')

s = m:section(SimpleSection, translate("Service Status"), translate("Nextcloud status:"))
s:append(Template("nextcloud/status"))

s = m:section(TypedSection, "nextcloud", translate("Setup"), translate("The following parameters will only take effect during installation or upgrade:"))
s.addremove=false
s.anonymous=true

o = s:option(Value, "port", translate("Port").."<b>*</b>")
o.rmempty = false
o.default = "8082"
o.datatype = "port"

o = s:option(Value, "config_path", translate("Config path").."<b>*</b>")
o.rmempty = false
o.default = "/root/nextcloud/config"
o.datatype = "string"

return m
