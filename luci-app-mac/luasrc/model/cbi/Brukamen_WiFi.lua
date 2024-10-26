m = Map("wireless", "Wi-Fi设置", "配置Wi-Fi设置")

s = m:section(TypedSection, "wifi-iface", "修改为不同名称即可分为两个wifi信号")
s.anonymous = true

o = s:option(Value, "ssid", "Wi-Fi名称")
o.placeholder = "我的网络"

o = s:option(ListValue, "encryption", "加密类型")
o:value("psk", "WPA/WPA2-PSK")
o:value("none", "无线不加密")
o.default = "none"

o = s:option(Value, "key", "密码")
o.datatype = "wpakey"
o.password = true
o:depends("encryption", "psk")
o.validate = function(self, value)
    if #value < 8 then
        return nil, "密码至少需要8个字符"
    end

    return value
end

return m
