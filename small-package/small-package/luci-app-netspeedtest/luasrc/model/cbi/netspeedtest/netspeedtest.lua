-- Copyright 2018 sirpdboy (herboy2008@gmail.com)
require("luci.util")
local o,t,e
 
if luci.sys.call("pidof iperf3 >/dev/null") == 0 then
	status = translate("<strong><font color=\"green\">iperf3 服务端运行中</font></strong>")
else
	status = translate("<strong><font color=\"red\">iperf3 服务端未启动</font></strong>")
end

o = Map("netspeedtest", "<font color='green'>" .. translate("Netspeedtest") .."</font>",translate( "Network speed diagnosis test (including intranet and extranet)<br/>For specific usage, see:") ..translate("<a href=\'https://github.com/sirpdboy/netspeedtest.git' target=\'_blank\'>GitHub @netspeedtest/luci-app-netspeedtest</a>") )

t = o:section(TypedSection, "netspeedtest", translate('iperf3 lanspeedtest'))
t.anonymous = true
t.description = translate(string.format("%s<br />", status))

e = t:option(DummyValue, '', '')
e.rawhtml = true
e.template ='netspeedtest/netspeedtest'


t=o:section(TypedSection,"netspeedtest",translate("wanspeedtest"))
t.anonymous=true
e = t:option(DummyValue, '', '')
e.rawhtml = true
e.template ='netspeedtest/speedtest'

e =t:option(DummyValue, '', '')
e.rawhtml = true
e.template = 'netspeedtest/log'

return o
