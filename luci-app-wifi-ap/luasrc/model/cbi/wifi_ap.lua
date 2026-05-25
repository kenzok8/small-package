m = Map("wifi-ap", translate("WiFi AP Settings"))
s = m:section(TypedSection, "global", translate("全局设置"))
s.anonymous = true

-- UDP/mDNS/HTTP参数由wifi-ap守护进程读取，自动发现/注册配合AC端
-- 所有API接口RESTful标准化，返回结构统一：{code,msg,data}
-- 详见controller/wifi-ap.lua
s:option(Value, "log_level", translate("日志级别")).default = "info"
s:option(Value, "log_rotate_days", translate("日志保留天数")).default = 7
s:option(Value, "trend_db", translate("趋势数据库路径")).default = "/etc/wifi-ap/trend.json"
s:option(Value, "udp_port", translate("UDP端口")).default = 9090
s:option(Value, "udp_broadcast", translate("UDP广播地址")).default = "255.255.255.255"
s:option(Value, "udp_timeout", translate("UDP超时时间(秒)")).default = 2
s:option(Value, "udp_retry", translate("UDP重试次数")).default = 2

-- 固件分块上传/断点续传参数由wifi-ap-firmware-upload.sh脚本处理
-- 配置参数热加载由reload_config action支持，无需重启服务

btn = s:option(Button, "_reload", translate("配置热加载"))
btn.inputstyle = "apply"
btn.write = function()
    luci.http.redirect(luci.dispatcher.build_url("admin/network/wifi-ap/api/reload_config"))
end

return m
