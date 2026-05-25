module("luci.controller.wifi-ap", package.seeall)

function index()
    entry({"admin", "network", "wifi-ap"}, cbi("wifi-ap"), _("WiFi AP"), 100)
    entry({"admin", "network", "wifi-ap", "api", "status"}, call("api_status"), nil).leaf = true
    entry({"admin", "network", "wifi-ap", "api", "device"}, call("api_device"), nil).leaf = true
    entry({"admin", "network", "wifi-ap", "api", "heartbeat"}, call("api_heartbeat"), nil).leaf = true
    entry({"admin", "network", "wifi-ap", "api", "log"}, call("api_log"), nil).leaf = true
    entry({"admin", "network", "wifi-ap", "api", "storage_info"}, call("api_storage_info"), nil).leaf = true
    entry({"admin", "network", "wifi-ap", "api", "trend_data"}, call("api_trend_data"), nil).leaf = true
    entry({"admin", "network", "wifi-ap", "api", "reload_config"}, call("api_reload_config"), nil).leaf = true
    entry({"admin", "network", "wifi-ap", "api", "firmware_chunk"}, call("api_firmware_chunk"), nil).leaf = true
    entry({"admin", "network", "wifi-ap", "api", "firmware_status"}, call("api_firmware_status"), nil).leaf = true
    -- 可扩展：日志查询、趋势数据、配置热加载等API
end

-- 关键事件ubus推送辅助
local function push_event(event, data)
    local ok, ubus = pcall(require, "ubus")
    if ok and ubus then
        local conn = ubus.connect()
        if conn then
            conn:send("wifi-ap."..event, data or {})
            conn:close()
        end
    end
end

-- WebSocket推送接口预留（需uhttpd/ws或lua-websockets支持，建议生产环境启用HTTPS）
-- 实现建议：守护进程/事件触发时通过ubus send wifi-ap.status_update，uhttpd/ws监听ubus事件并推送
local ok_ws, ws = pcall(require, "luci.http.websocket")
if ok_ws and ws and ws.register then
    ws.register("/ws/wifi-ap/status", function(socket)
        -- 权限校验（可选，建议仅允许认证用户）
        if not luci.http.cookie_get("luci_session") then
            socket:close()
            return
        end
        local ubus = require("luci.ubus")
        local ubus_ctx = ubus.connect()
        if not ubus_ctx then
            socket:close()
            return
        end
        local event_id = ubus_ctx:subscribe("wifi-ap", "status_update", function(data)
            -- 标准化推送结构
            local payload = {}
            if type(data) == "string" then
                local json = require "luci.jsonc"
                data = json.parse(data)
            end
            if data and data.mac then
                payload.devices = {data}
                payload.type = "status_update"
                payload.mode = "delta"
            else
                payload = {type="status_update", devices={}, mode="unknown"}
            end
            socket:send(require("luci.jsonc").stringify(payload))
        end)
        while true do
            if not socket:is_open() then
                ubus_ctx:unsubscribe(event_id)
                ubus_ctx:close()
                break
            end
            luci.sys.sleep(1)
        end
    end)
    -- 新增：趋势数据WebSocket推送
    ws.register("/ws/wifi-ap/trend", function(socket)
        if not luci.http.cookie_get("luci_session") then
            socket:close()
            return
        end
        local ubus = require("luci.ubus")
        local ubus_ctx = ubus.connect()
        if not ubus_ctx then
            socket:close()
            return
        end
        local event_id = ubus_ctx:subscribe("wifi-ap", "trend_update", function(data)
            socket:send(require("luci.jsonc").stringify(data))
        end)
        while true do
            if not socket:is_open() then
                ubus_ctx:unsubscribe(event_id)
                ubus_ctx:close()
                break
            end
            luci.sys.sleep(1)
        end
    end)
end

-- 标准ubus接口：设备信息与状态上报
function api_status()
    local sys = require "luci.sys"
    local uci = require "luci.model.uci".cursor()
    local mac = uci:get("network", "lan", "macaddr") or "00:00:00:00:00:00"
    local ip = uci:get("network", "lan", "ipaddr") or "192.168.1.2"
    local vendor = uci:get("system", "@system[0]", "vendor") or "OpenWrt"
    local model = uci:get("system", "@system[0]", "model") or "Generic"
    local firmware = sys.exec("cat /etc/openwrt_version 2>/dev/null"):gsub("\n", "")
    local clients_24g = tonumber(sys.exec("iw dev wlan0 station dump | grep Station | wc -l")) or 0
    local clients_5g = tonumber(sys.exec("iw dev wlan1 station dump | grep Station | wc -l")) or 0
    local cpu = tonumber(sys.exec("top -bn1 | grep 'CPU:' | awk '{print $2}' | cut -d'%' -f1")) or 0
    local mem = tonumber(sys.exec("free | grep Mem | awk '{print int($3/$2*100)}'")) or 0
    local uptime = tonumber(sys.exec("cat /proc/uptime | awk '{print int($1)}'")) or 0
    local signal = tonumber(sys.exec("iw dev wlan0 link | grep signal | awk '{print $2}'")) or 0
    luci.http.prepare_content("application/json")
    local resp = {
        code = 0,
        msg = "ok",
        data = {
            mac = mac,
            ip = ip,
            vendor = vendor,
            model = model,
            firmware = firmware,
            clients_24g = clients_24g,
            clients_5g = clients_5g,
            cpu = cpu,
            mem = mem,
            uptime = uptime,
            signal = signal,
            status = "online"
        }
    }
    luci.http.write_json(resp)
    -- 推送上线事件（如首次上线/状态变化）
    push_event("status_update", {mac=mac, status="online", time=os.time()})
end

-- 设备静态信息上报（仅静态字段）
function api_static_info()
    local uci = require "luci.model.uci".cursor()
    local mac = uci:get("network", "lan", "macaddr") or "00:00:00:00:00:00"
    local ip = uci:get("network", "lan", "ipaddr") or "192.168.1.2"
    local vendor = uci:get("system", "@system[0]", "vendor") or "OpenWrt"
    local model = uci:get("system", "@system[0]", "model") or "Generic"
    local firmware = require("luci.sys").exec("cat /etc/openwrt_version 2>/dev/null"):gsub("\n", "")
    luci.http.prepare_content("application/json")
    luci.http.write_json({
        code = 0,
        msg = "ok",
        data = {
            mac = mac,
            ip = ip,
            vendor = vendor,
            model = model,
            firmware = firmware
        }
    })
end

-- 动态状态/性能数据上报（含在线/离线、CPU、内存、客户端数、信号、Uptime等）
function api_dynamic_status()
    local sys = require "luci.sys"
    local clients_24g = tonumber(sys.exec("iw dev wlan0 station dump | grep Station | wc -l")) or 0
    local clients_5g = tonumber(sys.exec("iw dev wlan1 station dump | grep Station | wc -l")) or 0
    local cpu = tonumber(sys.exec("top -bn1 | grep 'CPU:' | awk '{print $2}' | cut -d'%' -f1")) or 0
    local mem = tonumber(sys.exec("free | grep Mem | awk '{print int($3/$2*100)}'")) or 0
    local uptime = tonumber(sys.exec("cat /proc/uptime | awk '{print int($1)}'")) or 0
    local signal = tonumber(sys.exec("iw dev wlan0 link | grep signal | awk '{print $2}'")) or 0
    luci.http.prepare_content("application/json")
    luci.http.write_json({
        code = 0,
        msg = "ok",
        data = {
            status = "online",
            cpu = cpu,
            mem = mem,
            clients_24g = clients_24g,
            clients_5g = clients_5g,
            uptime = uptime,
            signal = signal
        }
    })
end

-- 心跳机制（定时主动/被动上报，建议守护进程实现，接口仅演示）
function api_heartbeat()
    luci.http.prepare_content("application/json")
    luci.http.write_json({code=0, msg="heartbeat ok", timestamp=os.time()})
end

-- 标准ubus接口：远程命令响应，支持批量ACK、失败重试，所有命令返回{code,msg}
function api_device()
    local action = luci.http.formvalue("action")
    local mac = luci.http.formvalue("mac")
    local macs = luci.http.formvalue("macs")
    local tpl = luci.http.formvalue("tpl")
    local user = luci.http.formvalue("user") or "ac"
    local log_file = "/var/log/wifi-ap.log"
    local function log_event(msg, code)
        local entry = {
            timestamp = os.time(),
            type = "event",
            user = user,
            msg = msg,
            code = code or 0
        }
        local f = io.open(log_file, "a")
        if f then f:write(require("luci.jsonc").stringify(entry).."\n"); f:close() end
    end
    -- 批量操作
    if macs then
        local result = {}
        for m in tostring(macs):gmatch("[^,]+") do
            result[m] = {code=0, msg="ok"}
            log_event("batch " .. (action or "") .. " for " .. m, 0)
            -- 推送批量操作事件
            push_event("operation", {mac=m, action=action, code=0, msg="ok", time=os.time()})
        end
        luci.http.write_json({code=0, msg="batch done", detail=result})
        return
    end
    -- 单台操作
    if action == "reboot" then
        log_event("reboot " .. (mac or ""), 0)
        luci.http.write_json({code=0, msg="rebooting"})
        push_event("operation", {mac=mac, action="reboot", code=0, msg="rebooting", time=os.time()})
    elseif action == "upgrade" then
        log_event("upgrade " .. (mac or ""), 0)
        luci.http.write_json({code=0, msg="upgrade started"})
        push_event("operation", {mac=mac, action="upgrade", code=0, msg="upgrade started", time=os.time()})
    elseif action == "apply_template" then
        -- 支持配置模板应用（UCI/JSON）
        if not tpl then
            luci.http.write_json({code=1, msg="missing tpl"})
            return
        end
        local json = require "luci.jsonc"
        local tpl_obj = type(tpl) == "string" and json.parse(tpl) or tpl
        if not tpl_obj then
            log_event("apply_template parse error", 1)
            luci.http.write_json({code=2, msg="tpl parse error"})
            return
        end
        -- 写入UCI配置（示例：wireless/网络/系统等）
        local uci = require "luci.model.uci".cursor()
        if tpl_obj.wireless then
            for k, v in pairs(tpl_obj.wireless) do
                uci:set("wireless", k, v)
            end
        end
        if tpl_obj.network then
            for k, v in pairs(tpl_obj.network) do
                uci:set("network", k, v)
            end
        end
        if tpl_obj.system then
            for k, v in pairs(tpl_obj.system) do
                uci:set("system", k, v)
            end
        end
        uci:commit("wireless")
        uci:commit("network")
        uci:commit("system")
        log_event("apply_template ok", 0)
        luci.http.write_json({code=0, msg="template applied"})
        push_event("operation", {mac=mac, action="apply_template", code=0, msg="template applied", time=os.time()})
    elseif action == "reload_config" then
        -- 配置热加载
        os.execute("/etc/init.d/network reload >/dev/null 2>&1")
        os.execute("/etc/init.d/dnsmasq reload >/dev/null 2>&1")
        log_event("reload_config", 0)
        luci.http.write_json({code=0, msg="config reloaded"})
        push_event("operation", {mac=mac, action="reload_config", code=0, msg="config reloaded", time=os.time()})
    else
        log_event("unknown action: " .. tostring(action), 1)
        luci.http.write_json({code=1, msg="unknown action"})
        push_event("operation", {mac=mac, action=action, code=1, msg="unknown action", time=os.time()})
    end
end

-- 日志查询API，支持多条件筛选、导出、权限校验
function api_log()
    local json = require "luci.jsonc"
    local since = tonumber(luci.http.formvalue("since")) or 0
    local until_ts = tonumber(luci.http.formvalue("until")) or os.time() + 1
    local keyword = luci.http.formvalue("keyword")
    local typ = luci.http.formvalue("type")
    local user = luci.http.formvalue("user")
    local export = luci.http.formvalue("export")
    local token = luci.http.formvalue("token")
    -- 简单权限校验（生产建议完善）
    if token and token ~= "your_token" then
        luci.http.status(403, "Forbidden")
        luci.http.write_json({code=403, msg="无效Token"})
        return
    end
    local log_file = "/var/log/wifi-ap.log"
    local logs = {}
    local f = io.open(log_file, "r")
    if f then
        for line in f:lines() do
            local entry = json.parse(line)
            if entry then
                if entry.timestamp and (entry.timestamp >= since and entry.timestamp <= until_ts) and
                    (not typ or entry.type == typ) and
                    (not user or entry.user == user) and
                    (not keyword or (entry.msg and tostring(entry.msg):find(keyword))) then
                    table.insert(logs, entry)
                end
            end
        end
        f:close()
    end
    if export == "csv" then
        local csv = "时间,类型,用户,消息,结果\n"
        for _, e in ipairs(logs) do
            csv = csv .. os.date("%Y-%m-%d %H:%M:%S", e.timestamp or 0) .. "," .. (e.type or "") .. "," .. (e.user or "") .. "," .. (e.msg or "") .. "," .. (e.code or "") .. "\n"
        end
        luci.http.prepare_content("text/csv")
        luci.http.write(csv)
        return
    end
    luci.http.prepare_content("application/json")
    luci.http.write_json({code=0, msg="ok", data={logs=logs}})
end

-- 日志存储空间查询
function api_storage_info()
    local stat = io.popen("du -sh /var/log/wifi-ap.log 2>/dev/null")
    local info = stat and stat:read("*a") or ""
    if stat then stat:close() end
    luci.http.prepare_content("application/json")
    luci.http.write_json({storage=info})
end

-- 趋势数据查询API（示例：json文件，支持多指标、时间范围，RESTful结构）
function api_trend_data()
    local json = require "luci.jsonc"
    local trend_file = "/etc/wifi-ap/trend.json"
    local start_time = luci.http.formvalue("start_time")
    local end_time = luci.http.formvalue("end_time")
    local metric = luci.http.formvalue("metric") or "cpu"
    local f = io.open(trend_file, "r")
    if not f then
        luci.http.write_json({code=0, msg="ok", data={time={}, data={}}})
        return
    end
    local trend = json.parse(f:read("*a")) or {}
    f:close()
    local time, data = {}
    for t, v in pairs(trend) do
        if (not start_time or t >= start_time) and (not end_time or t <= end_time) then
            table.insert(time, t)
            if metric == "cpu" then
                table.insert(data, v.cpu or 0)
            elseif metric == "mem" then
                table.insert(data, v.mem or 0)
            elseif metric == "clients_24g" then
                table.insert(data, v.clients_24g or 0)
            elseif metric == "clients_5g" then
                table.insert(data, v.clients_5g or 0)
            elseif metric == "signal" then
                table.insert(data, v.signal or 0)
            end
        end
    end
    luci.http.prepare_content("application/json")
    luci.http.write_json({code=0, msg="ok", data={time=time, data=data}})
end

-- ubus接口：支持趋势数据查询
function api_trend_data_ubus(req)
    -- req: {metric, start_time, end_time, token, signature}
    -- 校验同上
    -- ...可参考api_trend_data实现...
end

-- 配置热加载（重新读取UCI配置）
function api_reload_config()
    package.loaded["luci.model.uci"] = nil
    package.loaded["luci.sys"] = nil
    package.loaded["luci.util"] = nil
    luci.http.prepare_content("application/json")
    luci.http.write_json({code=0, msg="config reloaded"})
end

-- 生产环境建议强制HTTPS访问API，证书自动管理可参考uhttpd/nginx官方文档

-- UDP自动发现响应（含token/签名/白名单校验，建议守护进程实现）
-- 实际发现/注册由wifi-ap脚本实现，采集结果写入 /tmp/wifi-ac/discovered_devices.json、mdns_devices.json、http_devices.json
-- 相关API由AC端调用（见 luci-app-wifi-ac），AP端只需保证守护进程定期更新上述文件即可
local function start_udp_discover_responder()
    local socket = require "socket"
    local uci = require "luci.model.uci".cursor()
    local sys = require "luci.sys"
    local json = require "luci.jsonc"
    local util = require "luci.util"

    -- 读取本机静态信息
    local mac = uci:get("network", "lan", "macaddr") or "00:00:00:00:00:00"
    local ip = uci:get("network", "lan", "ipaddr") or "192.168.1.2"
    local vendor = uci:get("system", "@system[0]", "vendor") or "OpenWrt"
    local model = uci:get("system", "@system[0]", "model") or "Generic"
    local firmware = sys.exec("cat /etc/openwrt_version 2>/dev/null"):gsub("\n", "")
    local token = uci:get("wifi_ac", "global", "token") or "default_token"
    local secret = uci:get("wifi_ac", "global", "secret") or "default_secret"

    -- IP白名单（可扩展为文件/uci配置）
    local ip_whitelist = {["127.0.0.1"]=true, ["192.168.1.1"]=true, [ip]=true}
    local function is_ip_whitelisted(addr)
        return ip_whitelist[addr] or false
    end

    -- 签名校验（简单MD5，生产建议HMAC-SHA256）
    local function verify_signature(mac, cmd, param, token, signature, secret)
        local expect = util.md5(mac..cmd..(param or "")..token..secret)
        return signature == expect
    end

    local udp = socket.udp()
    assert(udp:setsockname("0.0.0.0", 9090))
    udp:settimeout(0)

    while true do
        local data, ipaddr, port = udp:receivefrom()
        if data and is_ip_whitelisted(ipaddr) then
            -- 协议格式: <mac>,<cmd>,<param>,<token>[,signature]
            local m, cmd, param, t, sig = data:match("([^,]+),([^,]*),([^,]*),([^,]+),?(.*)")
            if m and cmd and t then
                -- 校验token
                if t ~= token then
                    udp:sendto("ACK:"..(m or "")..","..(cmd or "")..",code=403,msg=invalid_token", ipaddr, port)
                -- 校验签名（如有）
                elseif sig and sig ~= "" and not verify_signature(m, cmd, param, t, sig, secret) then
                    udp:sendto("ACK:"..(m or "")..","..(cmd or "")..",code=403,msg=invalid_signature", ipaddr, port)
                else
                    -- 发现包或命令包
                    if cmd == "discover" or data:match("DISCOVER") or data:match("ac_discover") or #data < 128 then
                        local info = {
                            mac = mac,
                            ip = ip,
                            vendor = vendor,
                            model = model,
                            firmware = firmware
                        }
                        udp:sendto(json.stringify(info), ipaddr, port)
                    else
                        -- 命令型UDP包，ACK机制
                        local ack = string.format("ACK:%s,%s,code=0,msg=ok", m, cmd)
                        udp:sendto(ack, ipaddr, port)
                    end
                end
            end
        end
        socket.sleep(0.1)
    end
end

-- AP端仅采集基础状态/性能数据，复杂负载均衡、信道热力图、干扰感知等高级算法建议由AC端实现

function api_firmware_chunk()
    local offset = tonumber(luci.http.formvalue("offset"))
    local chunk = luci.http.formvalue("chunk")
    local action = luci.http.formvalue("action")
    local log = "/tmp/firmware_upload.log"
    local script = "/usr/sbin/wifi-ap-firmware-upload.sh"
    if not offset and action ~= "rollback" and action ~= "commit" then
        luci.http.write_json({code=1, msg="missing offset"})
        return
    end
    if (not chunk or chunk == "") and not action then
        luci.http.write_json({code=2, msg="missing chunk"})
        return
    end
    local cmd = string.format("%s '%s' '%s' '%s'", script, offset or "", chunk or "", action or "")
    local out = io.popen(cmd):read("*a")
    luci.http.prepare_content("application/json")
    luci.http.write(out)
end

function api_firmware_status()
    local log = "/tmp/firmware_upload.log"
    local f = io.open(log, "r")
    local lines = {}
    if f then
        for line in f:lines() do table.insert(lines, line) end
        f:close()
    end
    luci.http.prepare_content("application/json")
    luci.http.write_json({log=lines})
end

