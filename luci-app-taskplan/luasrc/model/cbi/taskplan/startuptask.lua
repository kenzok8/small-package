
local m,s,e

m=Map("taskplan",translate("Startup task"),translate("<b>The original [Timing Settings] includes scheduled task execution and startup task execution. Presets include over 10 functions, including restart, shutdown, network restart, memory release, system cleaning, network sharing, network shutdown, automatic detection of network disconnects and reconnection, MWAN3 load balancing detection of reconnection, and custom scripts</b></br>") ..
translate("The task to be executed upon startup, with a startup delay time unit of seconds."))

s = m:section(TypedSection, 'global')
s.anonymous=true

e=s:option(TextValue, "customscript" ,translate("Edit Custom Script"))
e.description = translate("The execution content of the [Scheduled Customscript] in the task name")
e.rows = 5
e.default=" "

e=s:option(TextValue, "customscript2" ,translate("Edit Custom Script2"))
e.description = translate("The execution content of the [Scheduled Customscript2] in the task name")
e.rows = 5
e.default=" "

s=m:section(TypedSection,"ltime","")
s.addremove=true
s.anonymous=true
s.template = "cbi/tblsection"

e = s:option(Value, 'remarks', translate('Remarks'))

e=s:option(Flag,"enable",translate("Enable"))
e.rmempty = false
e.default=0

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
e:value(10,translate("Scheduled DisRereboot"))
e:value(11,translate("Scheduled Restartmwan3"))
e:value(13,translate("Scheduled Wifiup"))
e:value(14,translate("Scheduled Wifidown"))
e:value(12,translate("Scheduled Customscript"))
e:value(15,translate("Scheduled Customscript2"))
e.default=2

e=s:option(Value,"delay",translate("Delayed Start(seconds)"))
e.default=10

m.apply_on_parse = true
m.on_after_apply = function(self,map)
	luci.sys.exec("/etc/init.d/taskplan start")
end

return m
