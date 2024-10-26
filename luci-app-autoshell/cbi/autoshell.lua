local fs = require "nixio.fs"
local uci = require "luci.model.uci".cursor()
local conffile = "/etc/config/autoshell"

f = SimpleForm("logview", translate("web抓包认证"), translate("在这里粘贴你抓包的curl，系统将自动生成对应请求脚本并实时保持网络在线。"))
f.reset = false
f.submit = translate("保存抓包")

t = f:field(TextValue, "conf")
t.rmempty = true
t.rows = 20
function t.cfgvalue()
    local value = fs.readfile(conffile)
    return value or ""
end
function t.write(self, section, value)
    if value then
        fs.writefile(conffile, value)
    end
end

btn_generate = f:field(Button, "generate", "")
btn_generate.inputtitle = "生成脚本"

function btn_generate.write()
    local scriptExist = luci.sys.call("[ -f /etc/autoshell.sh ]") == 0
    if scriptExist then
        luci.http.write('<script>alert("脚本已更新！！");</script>')
        os.execute("sh /etc/autoshells.sh")
    else
        luci.http.write('<script>alert("脚本创建成功！！");</script>')
        os.execute("sh /etc/autoshells.sh")
    end
end

local pid = luci.sys.exec("pgrep -f '/etc/autoshell.sh'")

if pid == "" then
    btn_authenticate = f:field(Button, "authenticate", "")
    btn_authenticate.inputtitle = "开始认证"

    function btn_authenticate.write()
        luci.http.redirect(luci.dispatcher.build_url("admin", "services", "webauto"))
        os.execute("sh /etc/autoshell.sh &")
    end
else
    btn_stop = f:field(Button, "stop", "")
    btn_stop.inputtitle = "停止脚本"

    function btn_stop.write()
        os.execute("killall sh /etc/autoshell.sh")
        luci.http.redirect(luci.dispatcher.build_url("admin", "services", "webauto"))
    end
end

return f
