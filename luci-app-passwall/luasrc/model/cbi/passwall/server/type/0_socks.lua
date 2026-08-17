if not api.is_finded("microsocks") then
	return
end

-- [[ microsocks ]]
local m, s1 = ...
local type_name = "Socks"

s1.fields["type"]:value(type_name, "Socks")
if not s1.fields["type"].default then
	s1.fields["type"].default = type_name
end

if s1.val["type"] and s1.val["type"] ~= type_name then
	return
end

local s = NamedSection(m, arg[1], "server")
s.type_name = type_name
s.option_prefix = "socks_"

o = s:option(Value, "port", translate("Listen Port"))
o.datatype = "port"

o = s:option(Flag, "auth", translate("Auth"))

o = s:option(ListValue, "user", translate("User"))
for i, v in ipairs(user_list) do
	o:value(v[".name"], v.username)
end
o:depends({ auth = true })

o = s:option(Flag, "log", translate("Log"))
o.default = "1"

api.luci_types(s1, s)
