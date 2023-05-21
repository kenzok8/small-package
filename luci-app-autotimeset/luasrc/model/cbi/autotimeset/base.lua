local o=require"luci.dispatcher"
local e=require("luci.model.ipkg")
local s=require"nixio.fs"
local e=luci.model.uci.cursor()
local m,s,e

m=Map("autotimeset",translate("Scheduled Setting"),translate("<b>Timing settings include: timing restart, timing shutdown, timing restart network, all functions can be used together.</b></br>") ..
translate("N1-N5 is continuous, N1, N3, N5 is discontinuous, */N represents every N hours or every N minutes.The week can only be 0~6, the hour can only be 0~23, the minute can only be 0~59, the unavailable time is 48 hours.") ..
translate("&nbsp;&nbsp;&nbsp;<input class=\"cbi-button cbi-button-apply\" type=\"button\" value=\"" ..
translate("Test/Verify Settings") ..
" \" onclick=\"window.open('https://tool.lu/crontab/')\"/>"))

s = m:section(TypedSection, 'global')
s.anonymous=true

e=s:option(TextValue, "customscript") 
e.description = translate("Only by editing the content of the custom script well and scheduling the custom script task can it be executed effectively.")
e.rows = 5
e.default = '#!/bin/sh'
e.rmempty = false

s=m:section(TypedSection,"stime","")
s.addremove=true
s.anonymous=true
s.template = "cbi/tblsection"

e=s:option(ListValue,"stype",translate("Scheduled Type"))
e:value(1,translate("Scheduled Reboot"))
e:value(2,translate("Scheduled Poweroff"))
e:value(3,translate("Scheduled ReNetwork"))
e:value(4,translate("Scheduled RestartSamba"))
e:value(5,translate("Scheduled Restartwan"))
e:value(6,translate("Scheduled Closewan"))
e:value(7,translate("Scheduled Clearmem"))
e:value(8,translate("Scheduled Sysfree"))
e:value(9,translate("Scheduled DisReconn"))
e:value(10,translate("Scheduled Restartmwan3"))
e:value(11,translate("Scheduled Customscript"))
e.default=2

e=s:option(Value,"month",translate("Month(0~11)"))
e.rmempty = false
e.default = '*'

week=s:option(Value,"week",translate("Week Day(0~6)"))
week.rmempty = true
week:value('*',translate("Everyday"))
week:value(0,translate("Sunday"))
week:value(1,translate("Monday"))
week:value(2,translate("Tuesday"))
week:value(3,translate("Wednesday"))
week:value(4,translate("Thursday"))
week:value(5,translate("Friday"))
week:value(6,translate("Saturday"))
week.default='*'

e=s:option(Value,"hour",translate("Hour(0~23)"))
e.rmempty = false
e.default = 0

e=s:option(Value,"minute",translate("Minute(0~59)"))
e.rmempty = false
e.default = 0

e=s:option(Flag,"enable",translate("Enable"))
e.rmempty = false
e.default=0

return m
