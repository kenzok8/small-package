local m, s, o

m = Map("floatip", translate("FloatingGateway"), translate("FloatingGateway allows two gateway within one lan which can switch between each other in case of a failure."))

m:section(SimpleSection).template  = "floatip_status"

s=m:section(NamedSection, "main", translate("Global settings"))
s.addremove=false
s.anonymous=true

o = s:option(Flag, "enabled", translate("Enable"))
o.rmempty = false

o = s:option(Value, "role", translate("Role"))
o.rmempty = false
o:value("main", translate("Preemptor"))
o:value("fallback", translate("Fallback"))

o = s:option(Value, "set_ip", translate("Floating Gateway IP"))
o.rmempty = false
function o.validate(self, value)
    local ip, mask = value:match("(%d+%.%d+%.%d+%.%d+)/?(%d*)")
    if not ip then
        return nil, "Invalid format."
    end

    -- 验证 IP 地址格式
    for octet in ip:gmatch("%d+") do
        if tonumber(octet) < 0 or tonumber(octet) > 255 then
            return nil, "IP address octets must be between 0 and 255"
        end
    end

    -- 验证子网掩码（如果存在）
    if mask ~= nil and mask ~= "" then
        local netmask = tonumber(mask)
        if netmask < 0 or netmask > 32 then
            return nil, "Netmask must be between 0 and 32"
        end
    end

    return value
  end

o = s:option(Value, "check_ip", translate("Check IP"))
o.rmempty = true
o.datatype = "ipaddr"
o:depends("role", "fallback")

return m
