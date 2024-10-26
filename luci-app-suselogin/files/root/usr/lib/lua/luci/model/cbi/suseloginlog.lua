-- Copyright 2020 BlackYau <blackyau426@gmail.com>
-- GNU General Public License v3.0


local fs = require "nixio.fs"
local conffile = "/tmp/log/suselogin/suselogin.log"

f = SimpleForm("logview", translate("日志"), translate("脚本执行的间隔时间不是精准的，两次检测之间的间隔时间会有 ±10 秒的误差"))
f.reset = false
f.submit = false

t = f:field(TextValue, "conf")
t.rmempty = true
t.rows = 20
function t.cfgvalue()
	return fs.readfile(conffile) or ""
end
t.readonly="readonly"

return f
