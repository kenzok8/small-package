local i = require "luci.sys"
local m, e

m = Map("mentohust", translate("锐捷认证"))
m.description = translate("MentoHUST 是一个支持 Windows、Linux 和 Mac OS 下锐捷认证的程序（附带支持赛尔认证）。")

m:section(SimpleSection).template  = "mentohust/mentohust_status"

e = m:section(TypedSection, "mentohust")
e.addremove = false
e.anonymous = true

o = e:option(Flag, "enable", translate("启用"))
o.rmempty = false

o = e:option(Value, "username", translate("用户名"))
o.datatype = "string"
o.rmempty = true

o = e:option(Value, "password", translate("密码"))
o.datatype = "string"
o.password = true
o.rmempty = true

o = e:option(Value, "interface", translate("网络接口"))
for t, e in ipairs(i.net.devices()) do
    if e ~= "lo" then o:value(e) end
end
o.rmempty = false

o = e:option(Value, "ipaddr", translate("IP 地址"))
o.description = translate("留空或设置为 0.0.0.0 使用本地 IP（DHCP）")
o.default = "0.0.0.0"
o.rmempty = true

o = e:option(Value, "gateway", translate("网关"))
o.default = "0.0.0.0"
o.rmempty = false

o = e:option(Value, "mask", translate("子网掩码"))
o.default = "255.255.255.0"
o.rmempty = false

o = e:option(Value, "dns", translate("DNS"))
o.default = "0.0.0.0"
o.rmempty = true

o = e:option(Value, "ping", translate("Ping 主机"))
o.description = translate("用于掉线检测的 Ping 主机，设置为 0.0.0.0 关闭此功能。")
o.default = "0.0.0.0"
o.rmempty = false

o = e:option(Value, "timeout", translate("认证超时时间（秒）"))
o.default = "8"
o.rmempty = false

o = e:option(Value, "interval", translate("响应间隔时间（秒）"))
o.default = "30"
o.rmempty = false

o = e:option(Value, "wait", translate("失败等待时间（秒）"))
o.default = "15"
o.rmempty = false

o = e:option(Value, "fail_number", translate("允许失败次数"))
o.description = translate("默认为 0，表示无限制。")
o.default = "0"
o.rmempty = false

o = e:option(ListValue, "multicast_address", translate("组播地址"))
o.default = "1"
o:value("0", translate("标准"))
o:value("1", translate("锐捷"))
o:value("2", translate("赛尔"))

o = e:option(ListValue, "dhcp_mode", translate("DHCP 模式"))
o.default = "1"
o:value("0", translate("无"))
o:value("1", translate("二次认证"))
o:value("2", translate("认证后"))
o:value("3", translate("认证前"))

o = e:option(Value, "dhcp_script", translate("DHCP 脚本"))
o.description = translate("默认为 udhcpc -i")
o.default = "udhcpc -i"
o.rmempty = true

o = e:option(Value, "version", translate("客户端版本号"))
o.description = translate("默认为 0.00，表示兼容 xrgsu")
o.default = "0.00"
o.rmempty = false

local s = m:section(TypedSection, "log", translate("锐捷日志"))

function s.cfgsections(self)
    return { " " }
end

_log = s:option(TextValue, "_log")
_log.rmempty = true
function _log.cfgvalue(self, section)
    local log_msg = ""
    local fp = io.popen("logread -e mentohust | tail -n 20")
    if fp then
        local data = fp:read("*all")
        fp:close()
        log_msg = data
    else
        log_msg = translate("无法读取日志。")
    end
    return log_msg
end

return m
