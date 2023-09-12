local uci = require("luci.model.uci").cursor()

function get_status_html(status_value)
    local html = "<span style='color:red'>" .. translate("Disabled") .. "</span>"
    if status_value == "1" then
        html = "<span style='color:green'>" .. translate("Enabled") .. "</span>"
    end
    return html
end

m = Map("ua2f",
    translate("Brukamen_UA2F"),
    translate([[
        The plugin is developed by Brukamen<br>
        Version number: 2.0.2<br>
        169296793@qq.com<br>
        <a href="http://ua.233996.xyz/" target="_blank">http://ua.233996.xyz/</a>
    ]])
)

s = m:section(NamedSection, "enabled", "ua2f", translate("ON/OFF UA2F"))

o = s:option(Button, "__enable_btn")
o.inputtitle = translate("Enable")
o.inputstyle = "apply"
function o.write()
    uci:set("ua2f", "enabled", "enabled", "1")
    uci:commit("ua2f")
    os.execute("/etc/init.d/ua2f enable")
    os.execute("/etc/init.d/ua2f start")
end

o = s:option(Button, "__disable_btn")
o.inputtitle = translate("Disable")
o.inputstyle = "reset"
function o.write()
    uci:set("ua2f", "enabled", "enabled", "0")
    uci:commit("ua2f")
    os.execute("/etc/init.d/ua2f stop")
end

o = s:option(DummyValue, "__status")
o.rawhtml  = true
o.placeholder = "-"
function o.cfgvalue()
    local enabled = uci:get("ua2f", "enabled", "enabled")
    o.value = get_status_html(enabled)
    return o.value
end

status = s:option(DummyValue, "status", translate("Status"))
status.cfgvalue = function(self, section)
   local pid = luci.sys.exec("pidof ua2f")
   if pid == "" then
      return translate("-OFF")
   else
      return translate("-ON(PID %s)"):format(pid)
   end
end

s = m:section(NamedSection, "firewall", "ua2f", translate("Handle intranet"))

o = s:option(Button, "__enable_intranet_btn")
o.inputtitle = translate("Enable")
o.inputstyle = "apply"
function o.write()
    uci:set("ua2f", "firewall", "handle_intranet", "1")
    uci:commit("ua2f")
end

o = s:option(Button, "__disable_intranet_btn")
o.inputtitle = translate("Disable")
o.inputstyle = "reset"
function o.write()
    uci:set("ua2f", "firewall", "handle_intranet", "0")
    uci:commit("ua2f")
end

o = s:option(DummyValue, "__status")
o.rawhtml  = true
o.placeholder = "-"
function o.cfgvalue()
    local handle_intranet = uci:get("ua2f", "firewall", "handle_intranet")
    o.value = get_status_html(handle_intranet)
    return o.value
end


s = m:section(NamedSection, "firewall", "ua2f", translate("Handle Firewall"))

o = s:option(Button, "__enable_firewall_btn")
o.inputtitle = translate("Enable")
o.inputstyle = "apply"
function o.write()
    uci:set("ua2f", "firewall", "handle_fw", "1")
    uci:commit("ua2f")
end

o = s:option(Button, "__disable_firewall_btn")
o.inputtitle = translate("Disable")
o.inputstyle = "reset"
function o.write()
    uci:set("ua2f", "firewall", "handle_fw", "0")
    uci:commit("ua2f")
end

o = s:option(DummyValue, "__status")
o.rawhtml  = true
o.placeholder = "-"
function o.cfgvalue()
    local handle_fw = uci:get("ua2f", "firewall", "handle_fw")
    o.value = get_status_html(handle_fw)
    return o.value
end

s = m:section(NamedSection, "firewall", "ua2f", translate("Handle TLS"))

o = s:option(Button, "__enable_tls_btn")
o.inputtitle = translate("Enable")
o.inputstyle = "apply"
function o.write()
    uci:set("ua2f", "firewall", "handle_tls", "1")
    uci:commit("ua2f")
end

o = s:option(Button, "__disable_tls_btn")
o.inputtitle = translate("Disable")
o.inputstyle = "reset"
function o.write()
    uci:set("ua2f", "firewall", "handle_tls", "0")
    uci:commit("ua2f")
end

o = s:option(DummyValue, "__status")
o.rawhtml  = true
o.placeholder = "-"
function o.cfgvalue()
    local handle_tls = uci:get("ua2f", "firewall", "handle_tls")
    o.value = get_status_html(handle_tls)
    return o.value
end

s = m:section(NamedSection, "firewall", "ua2f", translate("Handle mmtls"))

o = s:option(Button, "__enable_mmtls_btn")
o.inputtitle = translate("Enable")
o.inputstyle = "apply"
function o.write()
    uci:set("ua2f", "firewall", "handle_mmtls", "1")
    uci:commit("ua2f")
end

o = s:option(Button, "__disable_mmtls_btn")
o.inputtitle = translate("Disable")
o.inputstyle = "reset"
function o.write()
    uci:set("ua2f", "firewall", "handle_mmtls", "0")
    uci:commit("ua2f")
end

o = s:option(DummyValue, "__status")
o.rawhtml  = true
o.placeholder = "-"
function o.cfgvalue()
    local handle_mmtls = uci:get("ua2f", "firewall", "handle_mmtls")
    o.value = get_status_html(handle_mmtls)
    return o.value
end

return m
