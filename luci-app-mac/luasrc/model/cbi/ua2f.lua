local uci = require("luci.model.uci").cursor()

function get_status_html(status_value)
    local html = "<span style='color:red'>" .. translate("Disabled") .. "</span>"
    if status_value == "1" then
        html = "<span style='color:green'>" .. translate("Enabled") .. "</span>"
    end
    return html
end

m = Map("ua2f",
    translate("UA2F配置中心"),
    translate([[
        <span style="font-family: '微软雅黑'; color: pink">该界面由 Brukamen 开发</span><br>
        <span style="font-family: '微软雅黑'; color: pink">联系邮箱：169296793@qq.com</span><br>
        <span style="font-family: '微软雅黑'; color: blue">点击按钮启用或关闭相应功能，转到测试网址测试结果为Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/112.0.0.0 Safari/537.36 Edg/112.0.1722.68则成功开启防检测</span><br>
        <span style="font-family: '微软雅黑'; color: blue">该插件并非适合所有类型的检测！！！</span><br>
        <span style="font-family: '微软雅黑'; color: yellow"><a href="http://ua.233996.xyz/" target="_blank">点击此处跳转到测试网址</a></span>
    ]])
)

s = m:section(NamedSection, "enabled", "ua2f", translate("启用/禁用 UA2F-->开启后开机自动运行"))

o = s:option(Button, "__enable_btn")
o.inputtitle = translate("Enable")
o.inputstyle = "apply"
function o.write()
    uci:set("ua2f", "enabled", "enabled", "1")
    uci:commit("ua2f")
    os.execute("/etc/init.d/ua2f enable")
    os.execute("/etc/init.d/ua2f start")
end

o = s:option(Button, "__disable_btn")
o.inputtitle = translate("Disable")
o.inputstyle = "reset"
function o.write()
    uci:set("ua2f", "enabled", "enabled", "0")
    uci:commit("ua2f")
    os.execute("/etc/init.d/ua2f stop")
end

o = s:option(DummyValue, "__status")
o.rawhtml  = true
o.placeholder = "-"
function o.cfgvalue()
    local enabled = uci:get("ua2f", "enabled", "enabled")
    o.value = get_status_html(enabled)
    return o.value
end

status = s:option(DummyValue, "status", translate("运行状态："))
status.cfgvalue = function(self, section)
   local pid = luci.sys.exec("pidof ua2f")
   if pid == "" then
      return translate("未运行")
   else
      return translate("运行中(系统进程 %s)"):format(pid)
   end
end

s = m:section(NamedSection, "firewall", "ua2f", translate("处理内网流量，防止访问内网时被检测（建议开启）"))

o = s:option(Button, "__enable_intranet_btn")
o.inputtitle = translate("Enable")
o.inputstyle = "apply"
function o.write()
    uci:set("ua2f", "firewall", "handle_intranet", "1")
    uci:commit("ua2f")
end

o = s:option(Button, "__disable_intranet_btn")
o.inputtitle = translate("Disable")
o.inputstyle = "reset"
function o.write()
    uci:set("ua2f", "firewall", "handle_intranet", "0")
    uci:commit("ua2f")
end

o = s:option(DummyValue, "__status")
o.rawhtml  = true
o.placeholder = "-"
function o.cfgvalue()
    local handle_intranet = uci:get("ua2f", "firewall", "handle_intranet")
    o.value = get_status_html(handle_intranet)
    return o.value
end


s = m:section(NamedSection, "firewall", "ua2f", translate("自动配置防火墙（建议开启）"))

o = s:option(Button, "__enable_firewall_btn")
o.inputtitle = translate("Enable")
o.inputstyle = "apply"
function o.write()
    uci:set("ua2f", "firewall", "handle_fw", "1")
    uci:commit("ua2f")
end

o = s:option(Button, "__disable_firewall_btn")
o.inputtitle = translate("Disable")
o.inputstyle = "reset"
function o.write()
    uci:set("ua2f", "firewall", "handle_fw", "0")
    uci:commit("ua2f")
end

o = s:option(DummyValue, "__status")
o.rawhtml  = true
o.placeholder = "-"
function o.cfgvalue()
    local handle_fw = uci:get("ua2f", "firewall", "handle_fw")
    o.value = get_status_html(handle_fw)
    return o.value
end

s = m:section(NamedSection, "firewall", "ua2f", translate("处理443端口流量，443端口出现 http 流量的概率较低（建议关闭）"))

o = s:option(Button, "__enable_tls_btn")
o.inputtitle = translate("Enable")
o.inputstyle = "apply"
function o.write()
    uci:set("ua2f", "firewall", "handle_tls", "1")
    uci:commit("ua2f")
end

o = s:option(Button, "__disable_tls_btn")
o.inputtitle = translate("Disable")
o.inputstyle = "reset"
function o.write()
    uci:set("ua2f", "firewall", "handle_tls", "0")
    uci:commit("ua2f")
end

o = s:option(DummyValue, "__status")
o.rawhtml  = true
o.placeholder = "-"
function o.cfgvalue()
    local handle_tls = uci:get("ua2f", "firewall", "handle_tls")
    o.value = get_status_html(handle_tls)
    return o.value
end

s = m:section(NamedSection, "firewall", "ua2f", translate("处理mmtls流量（微信不能正常使用时关闭）"))

o = s:option(Button, "__enable_mmtls_btn")
o.inputtitle = translate("Enable")
o.inputstyle = "apply"
function o.write()
    uci:set("ua2f", "firewall", "handle_mmtls", "1")
    uci:commit("ua2f")
end

o = s:option(Button, "__disable_mmtls_btn")
o.inputtitle = translate("Disable")
o.inputstyle = "reset"
function o.write()
    uci:set("ua2f", "firewall", "handle_mmtls", "0")
    uci:commit("ua2f")
end

o = s:option(DummyValue, "__status")
o.rawhtml  = true
o.placeholder = "-"
function o.cfgvalue()
    local handle_mmtls = uci:get("ua2f", "firewall", "handle_mmtls")
    o.value = get_status_html(handle_mmtls)
    return o.value
end

_log = s:option(TextValue, "运行日志")
_log.rmempty = true
function _log.cfgvalue(self, section)
    local log_msg = ""
    local fp = io.popen("logread -e UA2F | tail -n 20")
    if fp then
        local data = fp:read("*all")
        fp:close()
        log_msg = data
    else
        log_msg = translate("Failed to read log.")
    end
    return log_msg
end

return m


