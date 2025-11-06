--[[
LuCI - Lua Configuration Interface
]]--

local m, s, o

m = SimpleForm("shadowrt", translate("ShadoWRT"), translate("ShadoWRT can create isolated clones of iStoreOS/OpenWRT."))
m.submit = false
m.reset = false

s = m:section(SimpleSection)
s.template = "shadowrt/status"

return m
