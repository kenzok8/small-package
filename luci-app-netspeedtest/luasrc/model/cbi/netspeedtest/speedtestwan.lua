-- Copyright (C) 2020-2022  sirpdboy  <herboy2008@gmail.com> https://github.com/sirpdboy/netspeedtest
require("luci.util")
local o,t,e

o = Map("netspeedtest", "<font color='green'>" .. translate("Net Speedtest") .."</font>",translate( "Network speed diagnosis test (including intranet and extranet)<br/>For specific usage, see:") ..translate("<a href=\'https://github.com/sirpdboy/netspeedtest.git' target=\'_blank\'>GitHub @sirpdboy/netspeedtest</a>") )

t=o:section(TypedSection,"wanspeedtest",translate("Wan Speedtest"))
t.anonymous=true

e = t:option(DummyValue, '', '')
e.rawhtml = true
e.template ='netspeedtest/speedtestwan'

e =t:option(DummyValue, '', '')
e.rawhtml = true
e.template = 'netspeedtest/log'

return o
