--[[
LuCI - Lua Configuration Interface

Copyright 2010 Jo-Philipp Wich <xm@subsignal.org>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0
]]--

require("luci.sys")

m = Map("autoreboot", translate("定时重启"), translate("配置定时重启。"))

s = m:section(TypedSection, "login", "")
s.addremove = false
s.anonymous = true

enable = s:option(Flag, "enable", translate("启用"))
pass = s:option(Value, "minute", translate("分"))
hour = s:option(Value, "hour", translate("时"))

local apply = luci.http.formvalue("cbi.apply")
if apply then
	io.popen("/etc/init.d/autoreboot restart")
end

return m
