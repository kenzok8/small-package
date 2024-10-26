local fs = require "nixio.fs"
local conffile = "/tmp/log/autoshell.log"

f = SimpleForm("logview", translate("日志"), translate("日志不能实时更新，需要手动刷新界面"))
f.reset = false
f.submit = false

t = f:field(TextValue, "conf")
t.rmempty = true
t.rows = 20
function t.cfgvalue()
	return fs.readfile(conffile) or ""
end

t.readonly="readonly"

btn_clear = f:field(Button, "clear", "")
btn_clear.inputtitle = "清除日志"

function btn_clear.write()
	fs.writefile(conffile, "日志已清除") 
	luci.http.redirect(luci.dispatcher.build_url("admin", "services", "webauto", "log"))
end

btn_read = f:field(Button, "read", "")
btn_read.inputtitle = "刷新日志"

function btn_read.write()
	t.value = fs.readfile(conffile) or ""
end

return f
