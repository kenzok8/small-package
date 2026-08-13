api = require "luci.passwall.api"
appname = api.appname
fs = api.fs

api.set_default_cbi()

m = Map("passwall_server", translate("Server Config"))
m.redirect = api.url("server")
api.set_apply_on_parse(m)

if not arg[1] or not m:get(arg[1]) then
	luci.http.redirect(m.redirect)
end

local header = Template(appname .. "/server/config_header")
header.api = api
header.config = m.config
header.section = arg[1]
m:append(header)

m:append(Template(appname .. "/cbi/nodes_listvalue_com"))

s = m:section(NamedSection, arg[1], "user", "")
s.addremove = false
s.dynamic = false

local types_dir = "/usr/lib/lua/luci/model/cbi/" .. appname .. "/server/type/"
s.val = m:get(arg[1]) or {}

o = s:option(Flag, "enable", translate("Enable"))
o.default = "1"
o.rmempty = false

o = s:option(Value, "remarks", translate("Remarks"))
o.default = translate("Remarks")
o.rmempty = false

o = s:option(ListValue, "type", translate("Type"))

local type_table = {}
for filename in fs.dir(types_dir) do
	table.insert(type_table, filename)
end
table.sort(type_table, function(a, b)
	if a == "socks.lua" then return true end
	if b == "socks.lua" then return false end
	return a < b
end)

for index, value in ipairs(type_table) do
	local p_func = loadfile(types_dir .. value)
	setfenv(p_func, getfenv(1))(m, s)
end

local footer = Template(appname .. "/server/config_footer")
footer.api = api
footer.config = m.config
footer.section = arg[1]
m:append(footer)

return api.return_map(m)
