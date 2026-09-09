if not api.is_finded("ipt2socks") then
	return
end

-- [[ Socks ]]
local m, s1 = ...
local type_name = "Socks"

s1.fields["type"]:value(type_name, "Socks")

if s1.val["type"] and s1.val["type"] ~= type_name then
	return
end

local s = NamedSection(m, arg[1], "tmp_" .. s1.sectiontype)
s.parent = s1
s.type_name = type_name
s.option_prefix = "socks_"
api.set_type_cbi(s)

o = s:option(ListValue, "del_protocol", "¡¡") --Ê¼ÖÕÒþ²Ø£¬ÓÃÓÚÉ¾³ý protocol
o:depends({ __hide = "1" })
o.rewrite_option = "protocol"

o = s:option(Value, "address", translate("Address (Support Domain Name)"))

o = s:option(Value, "port", translate("Port"))
o.datatype = "port"

o = s:option(Value, "username", translate("Username"))

o = s:option(Value, "password", translate("Password"))
o.password = true

api.type_cbi_section(s1, s)
