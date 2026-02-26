local m, s

m = Map("kai", translate("KAI"), translate("KAI is an efficient AI tool."))
m:section(SimpleSection).template  = "kai/kai_status"

s=m:section(TypedSection, "kai", translate("Global settings"))
s.addremove=false
s.anonymous=true

s:option(Flag, "enabled", translate("Enable")).rmempty=false
return m


