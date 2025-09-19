local uci = luci.model.uci.cursor()
local fs = require "nixio.fs"
local sys = require "luci.sys"

m = Map("nginx-proxy", translate("Log Management"),
    translate("View and manage Nginx proxy logs"))

-- 全局日志设置
s = m:section(NamedSection, "global", "global", translate("Global Settings"))

-- 日志路径配置
log_path = s:option(Value, "log_path", translate("Log File Path"),
    translate("Absolute path to the log file"))
log_path.default = "/var/log/nginx/proxy.log"
log_path.rmempty = false
log_path.datatype = "file"

-- 日志内容查看
log_view = s:option(TextValue, "_log_content", translate("Log Content"))
log_view.rows = 20
log_view.readonly = true
log_view.wrap = "off"

function log_view.cfgvalue(self, section)
    local path = log_path:formvalue(section) or log_path.default
    if fs.access(path) then
        return sys.exec("tail -n 200 "..path.." | sed 's/\\x1b\\[[0-9;]*m//g'") -- 显示最后200行并去除ANSI颜色
    end
    return translate("Log file not found or inaccessible")
end

-- 日志轮转配置
log_rotate = s:option(ListValue, "log_rotate", translate("Log Rotation"))
log_rotate:value("daily", translate("Daily"))
log_rotate:value("weekly", translate("Weekly"))
log_rotate:value("monthly", translate("Monthly"))
log_rotate.default = "daily"

log_keep = s:option(Value, "log_keep", translate("Retention Days"),
    translate("Number of days to keep archived logs"))
log_keep.datatype = "range(1,365)"
log_keep.default = "7"

-- 操作按钮
actions = s:option(DummyValue, "_actions", translate("Actions"))
actions.template = "nginx-proxy/log_actions"

-- 输入验证
function m.validate(self)
    local path = log_path:formvalue("global")
    if not path:match("^/") then
        return nil, translate("Log path must be absolute")
    end
    
    if #path > 256 then
        return nil, translate("Path too long (max 256 characters)")
    end
    
    return true
end

-- 应用配置后处理
function m.on_commit(self)
    -- 生成logrotate配置
    local conf = string.format([[
%s {
    %s
    missingok
    rotate %d
    compress
    delaycompress
    notifempty
    create 0640 www-data adm
    sharedscripts
    postrotate
        /usr/bin/killall -USR1 nginx 2>/dev/null || true
    endscript
}]], 
    log_path:formvalue("global") or log_path.default,
    "daily" == log_rotate:formvalue("global") and "daily" or 
    "weekly" == log_rotate:formvalue("global") and "weekly" or "monthly",
    tonumber(log_keep:formvalue("global")) or 7)

    fs.writefile("/etc/logrotate.d/nginx-proxy", conf)
end

return m
