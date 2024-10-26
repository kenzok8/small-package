local fs = require "nixio.fs"
local conffile = "/tmp/log/chongyoung.log"

f = SimpleForm("logview", translate("日志"), translate("每30秒自动刷新界面"))
f.reset = false
f.submit = false

t = f:field(TextValue, "conf")
t.rmempty = true
t.rows = 20
function t.cfgvalue()
    local logfile = fs.readfile(conffile) or ""
    local lines = {}
    for line in logfile:gmatch("[^\r\n]+") do
        table.insert(lines, line)
        if #lines > 20 then
            table.remove(lines, 1)
        end
    end
    return table.concat(lines, "\n")
end

function check_log_update()
    t.value = fs.readfile(conffile) or ""
    luci.http.redirect(luci.dispatcher.build_url("admin", "school", "chongyoung", "log"))
end

if luci.http.formvalue("apply") then
    check_log_update()
else
    luci.http.write('<script>setTimeout("location.reload(true);", 30000)</script>')
end

t.readonly="readonly"

btn_clear = f:field(Button, "clear", "")
btn_clear.inputtitle = "清除日志"

function btn_clear.write()
	fs.writefile(conffile, " ") 
end

return f
