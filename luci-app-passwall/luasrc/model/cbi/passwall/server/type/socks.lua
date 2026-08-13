local m, s = ...

if not api.is_finded("microsocks") then
	return
end

local type_name = "Socks"

local option_prefix = "socks_"

local function _n(name)
	return option_prefix .. name
end

-- [[ microsocks ]]

s.fields["type"]:value(type_name, "Socks")
if not s.fields["type"].default then
	s.fields["type"].default = type_name
end

if s.val["type"] and s.val["type"] ~= type_name then
	return
end

o = s:option(Value, _n("port"), translate("Listen Port"))
o.datatype = "port"

o = s:option(Flag, _n("auth"), translate("Auth"))

o = s:option(ListValue, _n("user"), translate("User"))
for i, v in ipairs(user_list) do
	o:value(v[".name"], v.username)
end
o:depends({ [_n("auth")] = true })

o = s:option(Flag, _n("log"), translate("Log"))
o.default = "1"

api.luci_types(arg[1], m, s, type_name, option_prefix)
