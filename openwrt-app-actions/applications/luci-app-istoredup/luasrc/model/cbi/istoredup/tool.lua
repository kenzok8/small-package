--[[
LuCI - Lua Configuration Interface
]]--

local http = require 'luci.http'

m=SimpleForm("Tools")
m.submit = false
m.reset = false

s = m:section(SimpleSection)

o = s:option(Value, "action", translate("Action").."<b>*</b>")
o.rmempty = false
o.datatype = "string"
o:value("show-ip", "show-ip")
o.default = "show-ip"

local t=Template("istoredup/tool")
m:append(t)

local btn_do = s:option(Button, "_do")
btn_do.render = function(self, section, scope)
  self.inputstyle = "add"
  self.title = " "
  self.inputtitle = translate("Execute")
  Button.render(self, section, scope)
end

btn_do.write = function(self, section, value)
  local action = m:get(section, "action")
  if action == "show-ip" then
    local cmd = string.format("/usr/libexec/istorec/istoredup.sh %s", action)
    cmd = "/etc/init.d/tasks task_add istoredup " .. luci.util.shellquote(cmd) .. " >/dev/null 2>&1"
    os.execute(cmd)
    t.show_log_taskid = "istoredup"
  end
end

return m

