local m, s

m = Map("istoreenhance", translate("iStoreEnhance"), translate("iStoreEnhance is a tool to fix network issues for iStore."))

m:section(SimpleSection).template  = "istoreenhance_status"

s=m:section(TypedSection, "istoreenhance", translate("Global settings"))
s.addremove=false
s.anonymous=true

s:option(Flag, "enabled", translate("Enable")).rmempty=false

s:option(Value, "port", translate("Port")).rmempty=false

return m


