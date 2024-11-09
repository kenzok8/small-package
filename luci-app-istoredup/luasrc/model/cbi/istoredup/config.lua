--[[
LuCI - Lua Configuration Interface
]]--

local taskd = require "luci.model.tasks"
local istoredup_model = require "luci.model.istoredup"
local m, s, o

m = taskd.docker_map("istoredup", "istoredup", "/usr/libexec/istorec/istoredup.sh",
	translate("iStoreDup"),
	translate("A duplica of iStoreOS.")
		.. translate("Official website:") .. ' <a href=\"https://www.istoreos.com/\" target=\"_blank\">https://www.istoreos.com/</a>')

s = m:section(SimpleSection, translate("Service Status"), translate("iStoreDup status:"))
s:append(Template("istoredup/status"))

s = m:section(TypedSection, "istoredup", translate("Setup"), translate("The following parameters will only take effect during installation or upgrade:"))
s.addremove=false
s.anonymous=true

o = s:option(Value, "image_name", translate("Image").."<b>*</b>")
o.rmempty = false
o.datatype = "string"
o:value("linkease/istoreduprk35xx:latest", "linkease/istoreduprk35xx:latest")
o.default = "linkease/istoreduprk35xx:latest"

o = s:option(Value, "time_zone", translate("Timezone"))
o.datatype = "string"
o:value("Asia/Shanghai", "Asia/Shanghai")

return m
