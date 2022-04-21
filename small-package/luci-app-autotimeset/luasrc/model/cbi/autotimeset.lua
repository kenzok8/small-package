local o=require"luci.dispatcher"
local e=require("luci.model.ipkg")
local s=require"nixio.fs"
local e=luci.model.uci.cursor()
local m,s,e

m=Map("autotimeset",translate("Scheduled Setting"),translate("Timing settings include: timing restart, timing shutdown, timing restart network, all functions can be used together."))

s=m:section(TypedSection,"login","")
s.addremove=false
s.anonymous=true

e=s:option(Flag,"enable",translate("Enable"))
e.rmempty = false
e.default=0

e=s:option(ListValue,"stype",translate("Scheduled Type"), translate("Set the type of timing"))
e:value(1,translate("Scheduled Reboot"))
e:value(2,translate("Scheduled Poweroff"))
e:value(3,translate("Scheduled ReNetwork"))
e.default=2

e=s:option(ListValue,"week",translate("Week Day"), translate("The start-up cycle is weekly or daily"))
e:value(7,translate("Everyday"))
e:value(1,translate("Monday"))
e:value(2,translate("Tuesday"))
e:value(3,translate("Wednesday"))
e:value(4,translate("Thursday"))
e:value(5,translate("Friday"))
e:value(6,translate("Saturday"))
e:value(0,translate("Sunday"))
e.default=7

e=s:option(Value,"hour",translate("Hour"), translate("Set an hour"))
e.datatype = "range(0,23)"
e.rmempty = false

e=s:option(Value,"minute",translate("Minute"), translate("Set a minute"))
e.datatype = "range(0,59)"
e.rmempty = false

local e=luci.http.formvalue("cbi.apply")
if e then
  io.popen("/etc/init.d/autotimeset restart")
end

return m
