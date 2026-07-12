local api = require "luci.passwall2.api"
local com = require "luci.passwall2.com"
local appname = api.appname

m = Map(appname)
api.set_apply_on_parse(m)

-- [[ App Settings ]]--
s = m:section(TypedSection, "global_app", translate("App Update"))
s.anonymous = true

local app_version = Template(appname .. "/app_update/app_version")
app_version.api = api
app_version.config = m.config
app_version.com = com
s:append(app_version)

local k, v
for k, v in pairs(com) do
	o = s:option(Value, k:gsub("%-","_") .. "_file", translatef("%s App Path", v.name))
	o.default = v.default_path or ("/usr/bin/" .. k)
	o.rmempty = false
end

o = s:option(DummyValue, "tips", " ")
o.rawhtml = true
o.cfgvalue = function(t, n)
	return string.format('<font color="red">%s</font>', translate("if you want to run from memory, change the path, /tmp beginning then save the application and update it manually."))
end

return m
