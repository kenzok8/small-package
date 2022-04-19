require("luci.util")

mp = Map("uuplugin", translate("UU Game Accelerator"))
mp.description = translate("A Paid Game Acceleration service")
mp:section(SimpleSection).template  = "uuplugin/uuplugin_status"

s = mp:section(TypedSection, "uuplugin")
s.anonymous=true
s.addremove=false

o = s:option(Flag, "enabled", translate("Enable"))
o.default = 0
o.optional = false

local apply = luci.http.formvalue("cbi.apply")
if apply then
    io.popen("/etc/init.d/uuplugin_luci start &")
end

return mp
