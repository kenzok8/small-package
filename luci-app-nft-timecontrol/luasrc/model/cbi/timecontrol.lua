-- Copyright 2022-2023 sirpdboy <herboy2008@gmail.com>
-- Licensed to the public under the Apache License 2.0.
local sys = require "luci.sys"
local ifaces = sys.net:devices()
local WADM = require "luci.tools.webadmin"
local ipc = require "luci.ip"
local a, t, e

a = Map("timecontrol", translate("Internet time control"))
a.description = translate("Users can limit their internet usage time through MAC and IP, with available IP ranges such as 192.168.110.00 to 192.168.10.200")..translate("Suggested feedback:")..translate("<a href=\'https://github.com/sirpdboy/luci-app-timecontrol.git' target=\'_blank\'>GitHub @sirpdboy/luci-app-timecontrol </a>")
a.template = "timecontrol/index"

t = a:section(TypedSection, "timecontrol")
t.anonymous = true

e = t:option(DummyValue, "timecontrol_status", translate("Status"))
e.template = "timecontrol/timecontrol"
e.value = translate("Collecting data...")

e = t:option(ListValue, "list_type",translate("Control mode"), translate("blacklist:Block the networking of the target address,whitelist:Only allow networking for the target address and block all other addresses."))
e.rmempty = false
e:value("blacklist", translate("blacklist"))
-- e:value("whitelist", translate("whitelist"))
e.default = "blacklist"

e = t:option(ListValue, "chain",translate("Control intensity"), translate("Pay attention to strong control: machines under control will not be able to connect to the software router backend!"))
e.rmempty = false
-- e:value("forward", translate("Ordinary forwarding control"))
e:value("input", translate("Strong inbound control"))
e.default = "input"

t = a:section(TypedSection, "device")
t.template = "cbi/tblsection"
t.anonymous = true
t.addremove = true

comment = t:option(Value, "comment", translate("Comment"))
comment.size = 8

e = t:option(Flag, "enable", translate("Enabled"))
e.rmempty = false
e.size = 4

ip = t:option(Value, "mac", translate("IP/MAC"))
ip.size = 8

-- 替换原有的 get_devices() 函数
local function get_devices()
    local devices = {}
    local seen_ips = {}
    local ubus = require "ubus"
    local conn = ubus.connect()
    
    -- 辅助函数：尝试获取主机名
    local function get_hostname(ip)
        -- 方法1: 使用 nslookup
        local f = io.popen("nslookup "..ip.." 2>/dev/null | grep 'name =' | cut -d'=' -f2 | sed 's/\\.$//'")
        if f then
            local name = f:read("*l")
            f:close()
            if name and name ~= "" then
                return name:match("^%s*(.-)%s*$")  -- 去除前后空格
            end
        end
        
        -- 方法2: 读取 /tmp/dhcp.leases
        local leases_file = io.open("/tmp/dhcp.leases", "r")
        if leases_file then
            for line in leases_file:lines() do
                local mac, ip_lease, _, hostname = line:match("^(%S+)%s+(%S+)%s+(%S+)%s+(%S+)")
                if ip_lease == ip and hostname ~= "*" then
                    leases_file:close()
                    return hostname
                end
            end
            leases_file:close()
        end
        
        return "unknown"
    end

    -- 1. 从DHCP租约获取设备
    if conn then
        local leases = conn:call("dhcp", "ipv4leases", {}) or {}
        for _, lease in ipairs(leases) do
            if lease.ipaddr and lease.mac then
                local hostname = lease.hostname or get_hostname(lease.ipaddr)
                devices[#devices+1] = {
                    ip = lease.ipaddr,
                    mac = lease.mac:upper(),  -- 统一转为大写
                    hostname = hostname,
                    display = string.format("%s (%s) - %s", lease.ipaddr, lease.mac:upper(), hostname)
                }
                seen_ips[lease.ipaddr] = true
            end
        end
        conn:close()
    end

    -- 2. 从ARP表获取设备（使用ip neigh命令）
    local arp_cmd = io.popen("ip -4 neigh show dev br-lan 2>/dev/null")
    if arp_cmd then
        for line in arp_cmd:lines() do
            local ip_addr, mac = line:match("^(%S+)%s+.+%s+(%S+)%s+")
            if ip_addr and mac and mac ~= "00:00:00:00:00:00" and not seen_ips[ip_addr] then
                mac = mac:upper()  -- 统一MAC地址格式
                local hostname = get_hostname(ip_addr)
                devices[#devices+1] = {
                    ip = ip_addr,
                    mac = mac,
                    hostname = hostname,
                    display = string.format("%s (%s) - %s", ip_addr, mac, hostname)
                }
                seen_ips[ip_addr] = true
            end
        end
        arp_cmd:close()
    end

    -- 按IP地址排序设备列表
    table.sort(devices, function(a, b) return a.ip < b.ip end)
    
    return devices
end


-- 添加设备选项
local devices = get_devices()
for _, dev in ipairs(devices) do
    ip:value(dev.ip, dev.display)
end

function validate_time(self, value, section)
    local hh, mm, ss
    hh, mm, ss = string.match(value, "^(%d?%d):(%d%d)$")
    hh = tonumber(hh)
    mm = tonumber(mm)
    if hh and mm and hh <= 23 and mm <= 59 then
        return value
    else
        return nil, "Time HH:MM or space"
    end
end

e = t:option(Value, "timestart", translate("Start control time"))
e.placeholder = '00:00'
e.default = '00:00'
e.validate = validate_time
e.rmempty = true
e.size = 4

e = t:option(Value, "timeend", translate("Stop control time"))
e.placeholder = '00:00'
e.default = '00:00'
e.validate = validate_time
e.rmempty = true
e.size = 4

week=t:option(Value,"week",translate("Week Day(1~7)"))
week.rmempty = true
week:value('0',translate("Everyday"))
week:value(1,translate("Monday"))
week:value(2,translate("Tuesday"))
week:value(3,translate("Wednesday"))
week:value(4,translate("Thursday"))
week:value(5,translate("Friday"))
week:value(6,translate("Saturday"))
week:value(7,translate("Sunday"))
week:value('1,2,3,4,5',translate("Workday"))
week:value('6,7',translate("Rest Day"))
week.default='0'
week.size = 6

return a
