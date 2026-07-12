local api = require "luci.passwall.api"
local com = require "luci.passwall.com"
local appname = "passwall"

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

o = s:option(Flag, "github_proxy", translate("GitHub Proxy"), translate("Use gh-proxy instead of proxy nodes for component updates."))
o.default = 0

local k, v
for _, k in ipairs(com.order) do
	v = com[k]
	if k ~= "chinadns-ng" then
		o = s:option(Value, k:gsub("%-","_") .. "_file", translatef("%s App Path", v.name))
		o.default = v.default_path or ("/usr/bin/" .. k)
		o.rmempty = false
	end
end

o = s:option(DummyValue, "tips", "　")
o.rawhtml = true
o.cfgvalue = function(t, n)
	return string.format('<font color="red">%s</font>', translate("if you want to run from memory, change the path, /tmp beginning then save the application and update it manually."))
end

return m
