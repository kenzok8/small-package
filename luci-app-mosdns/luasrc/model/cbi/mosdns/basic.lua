m = Map("mosdns")
m.title = translate("MosDNS")
m.description = translate("MosDNS is a 'programmable' DNS forwarder.")

m:section(SimpleSection).template = "mosdns/mosdns_status"

s = m:section(TypedSection, "mosdns")
s.addremove = false
s.anonymous = true

enable = s:option(Flag, "enabled", translate("Enable"))
enable.rmempty = false

redirect = s:option(Flag, "redirect", translate("Enable DNS Redirect"))
redirect.rmempty = false

set_config = s:option(Button, "set_config", translate("DNS Helper"))
set_config.inputtitle = translate("Apply")
set_config.inputstyle = "reload"
set_config.description = translate("This will make the necessary adjustments to other plug-in settings.")
set_config.write = function()
  luci.sys.exec("/etc/mosdns/set.sh >/dev/null 2>&1 &")
end

unset_config = s:option(Button, "unset_config", translate("Revert Settings"))
unset_config.inputtitle = translate("Apply")
unset_config.inputstyle = "reload"
unset_config.description = translate("This will revert the adjustments.")
unset_config.write = function()
  luci.sys.exec("/etc/mosdns/unset.sh >/dev/null 2>&1 &")
end

return m
