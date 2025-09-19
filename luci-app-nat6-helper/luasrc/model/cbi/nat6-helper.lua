m = Map("nat6-helper", "NAT6 配置助手") 
m.description = translate("IPv6 路由器做 NAT6，使得路由器下级可以使用 IPv6 协议访问网站。<br />若插件启用失败，请检查路由器是否正常获取到IPv6")

m:section(SimpleSection).template  = "nat6-helper/nat6_status"

s = m:section(TypedSection, "nat6-helper")
s.addremove = false
s.anonymous = true

enabled = s:option(Flag, "enabled", translate("Enable"))
enabled.default = 0
enabled.rmempty = false

name = s:option(Value, "name", translate("Interface"))
name.rmempty = false
name.default = "wan6"
name.description = translate("默认为wan6，也可自行设置为有ipv6的网口名称，当该网卡变动时自动设置nat6")

init = s:option(Button, "init_button", translate("初始化"))
init.inputtitle = translate("一键配置")
init.inputstyle = "apply"
init.description = translate("一键设置ULA和DHCPv6和ipv6-dns，并设置通告默认网关。<br />启用本插件前需执行一次，配置完毕后会重启一次网络，稍等片刻网络恢复再进行设置")
function init.write(self, section)
    io.popen("/etc/init.d/nat6-helper setLan")
end

return m
