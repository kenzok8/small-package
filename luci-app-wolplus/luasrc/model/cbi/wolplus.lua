local i = require "luci.sys"
local t, e
t = Map("wolplus", translate("Wake on LAN +"), translate("Wake on LAN is a mechanism to remotely boot computers in the local network.") .. [[<br/><br/><a href="https://github.com/sundaqiang/openwrt-packages" target="_blank">Powered by sundaqiang</a>]])
t.template = "wolplus/index"
e = t:section(TypedSection, "macclient", translate("Host Clients"))
e.template = "cbi/tblsection"
e.anonymous = true
e.addremove = true
---- add device section
a = e:option(Value, "name", translate("Name"))
a.optional = false
---- mac address
nolimit_mac = e:option(Value, "macaddr", translate("MAC Address"))
nolimit_mac.rmempty = false
i.net.mac_hints(function(e, t) nolimit_mac:value(e, "%s (%s)" % {e, t}) end)
----- network interface
nolimit_eth = e:option(Value, "maceth", translate("Network Interface"))
nolimit_eth.rmempty = false
for t, e in ipairs(i.net.devices()) do if e ~= "lo" then nolimit_eth:value(e) end end
----- wake device
btn = e:option(Button, "_awake",translate("Wake Up Host"))
btn.inputtitle	= translate("Awake")
btn.inputstyle	= "apply"
btn.disabled	= false
btn.template = "wolplus/awake"
function gen_uuid(format)
    local uuid = i.exec("echo -n $(cat /proc/sys/kernel/random/uuid)")
    if format == nil then
        uuid = string.gsub(uuid, "-", "")
    end
    return uuid
end
function e.create(e, t)
    local uuid = gen_uuid()
    t = uuid
    TypedSection.create(e, t)
end

return t
