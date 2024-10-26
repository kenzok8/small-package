m = Map("chongyoung", translate("湖北飞young认证--冲young"))

s = m:section(TypedSection, "chongyoung", "")
s.anonymous = true

enabled = s:option(Flag, "enabled", "启用")
user = s:option(Value, "user", "账号")
time = s:option(Value, "time", "网络监测间隔/秒")

local apply = luci.http.formvalue("cbi.apply")
if apply then
	io.popen("/etc/init.d/chongyoung start")
end


return m
