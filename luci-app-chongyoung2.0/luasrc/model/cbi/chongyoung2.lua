local fs = require "nixio.fs"
local uci = require "luci.model.uci".cursor()
local conffile = "/etc/config/userprofile"

f = SimpleForm("logview", translate("密码管理(自动计算，勿动)"))
f.reset = false
f.submit = translate("保存参数")

t = f:field(TextValue, "conf")
t.rmempty = true
t.rows = 20
function t.cfgvalue()
    local value = fs.readfile(conffile)
    return value or ""
end

-- 在保存前，将Windows换行符 (\r\n) 替换为Linux换行符 (\n)，否则会导致读取密码时发生错误。。。
function t.write(self, section, value)
    if value then
        -- 将 \r\n 替换为 \n
        value = value:gsub("\r\n", "\n")
        fs.writefile(conffile, value)
    end
end

return f
