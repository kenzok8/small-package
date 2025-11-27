local m, s

m = Map("aihelper", translate("AiHelper"), translate("AiHelper is an efficient data transfer tool."))
m:section(SimpleSection).template  = "aihelper/aihelper_status"

s=m:section(TypedSection, "aihelper", translate("Global settings"))
s.addremove=false
s.anonymous=true

s:option(Flag, "enabled", translate("Enable")).rmempty=false
return m


