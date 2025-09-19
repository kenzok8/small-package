local uci = luci.model.uci.cursor()
local fs = require "nixio.fs"
local sys = require "luci.sys"

m = Map("nginx-proxy", translate("Reverse Proxy Configuration"),
    translate("Configure domain-based reverse proxy rules. Each rule requires a unique domain configuration."))

-- 代理规则主配置节
s = m:section(TypedSection, "proxy", translate("Proxy Rules"))
s.template = "cbi/tblsection"
s.addremove = true
s.anonymous = false
s.sortable = true

-- 域名配置 (增强验证)
domain = s:option(Value, "domain", translate("Domain Name"))
domain.datatype = "hostname"
domain.rmempty = false
domain.description = translate("Enter full domain (e.g. example.com or sub.example.com)")
function domain.validate(self, value)
    -- RFC 1034合规验证
    if not value:match("^[a-zA-Z0-9\\u4e00-\\u9fa5][a-zA-Z0-9-]{1,61}[a-zA-Z0-9]%.[a-zA-Z]{2,}$") then
        return nil, translate("Invalid domain format (e.g. example.com)")
    end
    -- 通配符验证
    if value:match("%*%.") and not value:match("^%*%.[a-zA-Z0-9-]+%.[a-zA-Z]{2,}$") then
        return nil, translate("Wildcard domains must be in format *.example.com")
    end
    return value
end

-- 后端服务器配置
backend = s:option(Value, "backend", translate("Backend Server"))
backend.datatype = "uri"
backend.rmempty = false
backend.description = translate("Format: http://192.168.1.100:8080 or https://internal-server")
function backend.validate(self, value)
    if not value:match("^https?://") then
        return nil, translate("Must start with http:// or https://")
    end
    return value
end

-- 监听端口配置 (智能默认)
port = s:option(Value, "port", translate("Listen Port"))
port.datatype = "port"
port.rmempty = false
port.description = translate("Standard ports: 80 (HTTP) or 443 (HTTPS)")
function port.cfgvalue(self, section)
    local value = m:get(section, "port")
    if not value then
        local ssl_enabled = uci:get("nginx-proxy", "ssl", "enabled") or "0"
        return ssl_enabled == "1" and "443" or "80"
    end
    return value
end

-- IP协议版本选项
ipv4 = s:option(Flag, "ipv4", translate("Enable IPv4"))
ipv4.default = "1"
ipv4.rmempty = false

ipv6 = s:option(Flag, "ipv6", translate("Enable IPv6"))
ipv6.default = "1"
ipv6.rmempty = false

-- 协议类型选项
proto = s:option(ListValue, "proto", translate("Protocol"))
proto:value("http", "HTTP/HTTPS")
proto:value("websocket", "WebSocket")
proto:value("grpc", "gRPC")
proto.default = "http"
function proto.validate(self, value, section)
    local backend = m:get(section, "backend")
    if value == "grpc" and not backend:match("^grpc?://") then
        return nil, translate("gRPC backend must use grpc:// or grpcs:// protocol")
    end
    return value
end

-- 证书路径 (智能默认)
cert_path = s:option(Value, "cert_path", translate("SSL Certificate Path"))
cert_path:depends("proto", "http")  -- 仅HTTP协议需要证书
function cert_path.cfgvalue(self, section)
    local value = m:get(section, "cert_path")
    if not value and uci:get("nginx-proxy", "acme", "enabled") == "1" then
        local domain = m:get(section, "domain")
        return "/etc/ssl/acme/"..domain:gsub("%*", "wildcard").."_fullchain.cer"
    end
    return value
end

-- 健康检查配置
health_check = s:option(Flag, "health_check", translate("Enable Health Check"))
check_path = s:option(Value, "check_path", translate("Check Path"))
check_path:depends("health_check", "1")
function check_path.cfgvalue(self, section)
    local path = m:get(section, "check_path")
    if not path then
        return m:get(section, "proto") == "grpc" 
            and "/grpc.health.v1.Health/Check" 
            or "/health"
    end
    return path
end

-- 访问控制列表
acl = s:option(DynamicList, "allow", translate("Allowed Clients"))
acl.datatype = "or(ipaddr, cidr)"
function acl.validate(self, value)
    for _, v in ipairs(value) do
        if not (luci.ip.new(v) or v:match("^[%d%.]+/%d+$") or v:match("^[%x:]+/%d+$")) then
            return nil, translatef("Invalid IP/CIDR: %s", v)
        end
    end
    return value
end

-- 超时配置 (智能默认)
s:option(Value, "proxy_connect_timeout", translate("Connect Timeout"))
s:option(Value, "proxy_read_timeout", translate("Read Timeout"))

m.on_parse = function(self)
    uci:foreach("nginx-proxy", "proxy", function(s)
        if not s.proxy_read_timeout then
            local timeout = {
                http = "60s",
                websocket = "3600s",
                grpc = "3600s"
            }[s.proto or "http"]
            uci:set("nginx-proxy", s[".name"], "proxy_read_timeout", timeout)
        end
    end)
end

-- 端口冲突验证
function m.validate(self)
    local ports = {}
    uci:foreach("nginx-proxy", "proxy", function(s)
        if s.port then
            ports[s.port] = ports[s.port] or {}
            table.insert(ports[s.port], s.domain)
        end
    end)

    local errs = {}
    for port, domains in pairs(ports) do
        if #domains > 1 then
            table.insert(errs, translatef("Port %s conflict between: %s", port, table.concat(domains, ", ")))
        end
    end
    return #errs == 0 or nil, errs
end

-- 配置保存后操作
function m.on_commit(self)
    luci.sys.call("/usr/libexec/nginx-proxy/generate-config >/dev/null 2>&1")
end

return m
