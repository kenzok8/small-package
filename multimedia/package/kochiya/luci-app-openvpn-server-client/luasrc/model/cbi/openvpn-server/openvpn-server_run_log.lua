--[[
LuCI - Lua Configuration Interface

Copyright 2025 LunaticKochiya<125438787@qq.com>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

$Id$
]]--
local fs = require "nixio.fs"
local conffile = "/var/openvpn.log"
local conffile_pass = "/etc/openvpn/openvpn-password.log"

f = SimpleForm("logview")

t1 = f:field(TextValue, "conf_file_log")
t1.rmempty = true
t1.rows = 20
t1.css_style = "width: 95vw !important;"
function t1.cfgvalue()
    return fs.readfile(conffile) or ""
end
t1.readonly = "readonly"
t1.description = "OpenVPN Log File"

t2 = f:field(TextValue, "conf_logread")
t2.rmempty = true
t2.rows = 20
t2.css_style = "width: 95vw !important;"
function t2.cfgvalue()
    local log_output = ""
    local handle = io.popen("logread | grep openvpn")
    if handle then
        log_output = handle:read("*a")
        handle:close()
    end
    return log_output or ""
end
t2.readonly = "readonly"
t2.description = "OpenVPN Logread Output"

t3 = f:field(TextValue, "conf_file_pass_log")
t3.rmempty = true
t3.rows = 20
t3.css_style = "width: 95vw !important;"
function t3.cfgvalue()
    return fs.readfile(conffile_pass) or ""
end
t3.readonly = "readonly"
t3.description = "OpenVPN Password Log File"



local clear_btn = f:field(Button, "clear_pass_log")
clear_btn.title = "清空登陆日志"
clear_btn.inputstyle = "remove"
clear_btn.description = "点击清空上面内容"

function clear_btn.write(self, section)
    fs.writefile(conffile_pass, "")
end

t4 = f:field(TextValue, "ifconfig_tun")
t4.rmempty = true
t4.rows = 10
t4.css_style = "width: 95vw !important;"
function t4.cfgvalue()
    local ifconfig_output = ""
    local handle = io.popen("ifconfig | grep -A 6 '^tun' 2>/dev/null")
    if handle then
        ifconfig_output = handle:read("*a")
        handle:close()
    end
    return ifconfig_output or "No tun interfaces found"
end
t4.readonly = "readonly"
t4.description = "All tun Interfaces Configuration"

return f
