-- Copyright 2020 BlackYau <blackyau426@gmail.com>
-- GNU General Public License v3.0


require("luci.sys")

m = Map("suselogin", translate("轻化工校园网认证"), translate("自动连接网络,支持断线自动重连"))

s = m:section(TypedSection, "login", "")
s.addremove = false
s.anonymous = true

enable = s:option(Flag, "enable", translate("启用"), translate("启用后即会检测上网状态，并尝试自动拨号"))
enable.rmempty = false

name = s:option(Value, "username", translate("用户名(学号)"))
name.rmempty = false
pass = s:option(Value, "password", translate("密码(身份证后6位)"))
pass.password = true
pass.rmempty = false

isp = s:option(ListValue, "isp", translate("运营商"))
isp:value("%E5%AE%9C%E5%AE%BE%E7%94%B5%E4%BF%A1", translate("宜宾电信互联网"))
isp:value("%E5%AE%9C%E5%AE%BE%E7%A7%BB%E5%8A%A8", translate("宜宾移动互联网"))
isp:value("%E6%A0%A1%E5%9B%AD%E7%BD%91", translate("校园网"))
isp:value("%E5%AE%9C%E5%AE%BE%E8%81%94%E9%80%9A", translate("宜宾联通互联网"))

interval = s:option(Value, "interval", translate("间隔时间"), translate("每隔多少时间(≥1)检测一下网络是否连接正常，如果网络异常则会尝试连接(单位:分钟)"))
interval.default = 5
interval.datatype = "min(1)"

auto_offline = s:option(Flag, "auto_offline", translate("自动下线"), translate("启用后，如果有新设备连接路由器则会将网络下线重新登录一次，可减少因为多终端设备在线而导致的账号封禁（会导致网络波动游戏玩家慎用）"))
auto_offline.rmempty = false

success = s:option(DummyValue,"opennewwindow",translate("认证页面"))
success.description = translate("<input type=\"button\" class=\"cbi-button cbi-button-save\" value=\"打开认证页\" onclick=\"window.open('http://10.23.2.4/eportal/success.jsp')\" /><input type=\"button\" class=\"cbi-button cbi-button-save\" value=\"打开自助服务\" onclick=\"window.open('http://10.23.2.6:8080/selfservice')\" /><br />可查看认证状态和管理在线设备")


local apply = luci.http.formvalue("cbi.apply")
if apply then
	io.popen("/etc/init.d/suselogin restart")
end

return m
