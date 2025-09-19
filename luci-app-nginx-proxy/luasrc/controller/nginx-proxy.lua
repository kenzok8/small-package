module("luci.controller.nginx-proxy", package.seeall)

local sys = require "luci.sys"
local uci = require "luci.model.uci".cursor()
local fs = require "nixio.fs"
local util = require "luci.util"
local http = require "luci.http"

function index()
    entry({"admin", "services", "nginx-proxy"}, firstchild(), _("Nginx Proxy"), 60).dependent = false
    entry({"admin", "services", "nginx-proxy", "proxy"}, cbi("nginx-proxy/proxy"), _("Proxy Settings"), 10)
    entry({"admin", "services", "nginx-proxy", "ssl"}, cbi("nginx-proxy/ssl"), _("SSL Settings"), 20)
    entry({"admin", "services", "nginx-proxy", "acme"}, cbi("nginx-proxy/acme"), _("ACME Settings"), 30)
    entry({"admin", "services", "nginx-proxy", "logs"}, cbi("nginx-proxy/logs"), _("Logs"), 40)
    entry({"admin", "services", "nginx-proxy", "schedules"}, cbi("nginx-proxy/schedules"), _("Schedules"), 50)
    
    entry({"admin", "services", "nginx-proxy", "apply"}, call("action_apply")).leaf = true
    entry({"admin", "services", "nginx-proxy", "clearlogs"}, call("action_clearlogs"))
    entry({"admin", "services", "nginx-proxy", "downloadlogs"}, call("action_downloadlogs"))
    entry({"admin", "services", "nginx-proxy", "acme", "logs"}, call("action_logs"))
    entry({"admin", "services", "nginx-proxy", "acme", "revoke"}, post("action_revoke"))
end

function action_logs()
    local log_path = "/var/log/acme.log"
    if fs.access(log_path) then
        http.prepare_content("text/plain")
        http.write(fs.readfile(log_path) or "No logs available")
    else
        http.status(404, "Log file not found")
    end
end

function generate_config()
    local config = {
        "# Auto-generated configuration by LuCI Nginx Proxy",
        "# Generated at: " .. os.date("%Y-%m-%d %H:%M:%S %Z"),
        "",
        "worker_processes auto;",
        "pid /var/run/nginx.pid;",
        "error_log  /var/log/nginx/error.log warn;",
        "",
        "events {",
        "    worker_connections  1024;",
        "    use epoll;",
        "    multi_accept on;",
        "}",
        "",
        "http {",
        "    include       /etc/nginx/mime.types;",
        "    default_type  application/octet-stream;",
        "    sendfile        on;",
        "    tcp_nopush     on;",
        "    tcp_nodelay    on;",
        "    keepalive_timeout  65;",
        "    server_names_hash_bucket_size 128;",
        "    client_max_body_size 64M;",
        "    proxy_headers_hash_max_size 512;",
        "    proxy_headers_hash_bucket_size 64;",
        "    include /etc/nginx/conf.d/*.conf;",
        ""
    }
  local function configure_firewall(port, proto)
    local firewall_type = sys.exec("uci get firewall.@defaults[0].flowtable 2>/dev/null | grep -q nft && echo nft || echo ipt")
    local cmd
    if firewall_type == "nft" then
      cmd = string.format("nft add rule inet fw4 input %s dport %d accept", proto, port)
    else
      cmd = string.format("iptables -I INPUT -p %s --dport %d -j ACCEPT", proto, port)
    end
    sys.call(cmd .. " 2>/dev/null")
  end

  -- 在生成每个server块时调用
  uci:foreach("nginx-proxy", "proxy", function(section)
    if section.port then
      configure_firewall(section.port, "tcp")
    end
  end)
end
    -- 处理全局SSL配置
    local ssl_enabled = uci:get("nginx-proxy", "ssl", "enabled") or "0"
    if ssl_enabled == "1" then
        table.insert(config, "    # SSL全局配置")
        table.insert(config, "    ssl_protocols TLSv1.2 TLSv1.3;")
        table.insert(config, "    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384;")
        table.insert(config, "    ssl_prefer_server_ciphers on;")
        table.insert(config, "    ssl_session_cache shared:SSL:10m;")
        table.insert(config, "    ssl_session_timeout 10m;")
        table.insert(config, "    ssl_stapling on;")
        table.insert(config, "    ssl_stapling_verify on;")
        table.insert(config, "")
    end

    -- 生成代理服务器配置
    uci:foreach("nginx-proxy", "proxy", function(section)
        if section[".type"] == "proxy" then
            local server_block = {
                "    # Proxy configuration for " .. (section.domain or "unnamed"),
                "    server {"
            }

            -- 监听端口配置
            if section.ipv4 == "1" then
                local listen = string.format("        listen %s", section.port or 80)
                if ssl_enabled == "1" then
                    listen = listen .. " ssl"
                end
                table.insert(server_block, listen .. ";")
            end

            if section.ipv6 == "1" then
                local listen = string.format("        listen [::]:%s", section.port or 80)
                if ssl_enabled == "1" then
                    listen = listen .. " ssl"
                end
                table.insert(server_block, listen .. ";")
            end

            -- 服务器名称
            table.insert(server_block, string.format("        server_name %s;", section.domain))

            -- SSL证书配置
            if ssl_enabled == "1" then
                table.insert(server_block, string.format("        ssl_certificate %s;", 
                    uci:get("nginx-proxy", "ssl", "cert_path") or "/etc/ssl/server.crt"))
                table.insert(server_block, string.format("        ssl_certificate_key %s;",
                    uci:get("nginx-proxy", "ssl", "key_path") or "/etc/ssl/server.key"))
            end

            -- 访问控制列表
            if section.allow and #section.allow > 0 then
                table.insert(server_block, "        # Access control list")
                for _, ip in ipairs(section.allow) do
                    table.insert(server_block, string.format("        allow %s;", ip))
                end
                table.insert(server_block, "        deny all;")
            end

            -- 位置块配置
            table.insert(server_block, "        location / {")
            if section.proto == "websocket" then
                table.insert(server_block, "            # WebSocket configuration")
                table.insert(server_block, "            proxy_http_version 1.1;")
                table.insert(server_block, "            proxy_set_header Upgrade $http_upgrade;")
                table.insert(server_block, "            proxy_set_header Connection \"upgrade\";")
            elseif section.proto == "grpc" then
                table.insert(server_block, "            # gRPC configuration")
                table.insert(server_block, "            grpc_pass " .. section.backend .. ";")
            else
                table.insert(server_block, string.format("            proxy_pass %s;", section.backend))
            end

            -- 通用代理头设置
            local headers = {
                "Host $host",
                "X-Real-IP $remote_addr",
                "X-Forwarded-For $proxy_add_x_forwarded_for",
                "X-Forwarded-Proto $scheme"
            }
            
            if section.headers then
                for _, h in ipairs(util.split(section.headers, "\n")) do
                    if #h > 0 then table.insert(headers, h) end
                end
            end

            for _, header in ipairs(headers) do
                table.insert(server_block, string.format("            proxy_set_header %s;", header))
            end

            -- 健康检查配置
            if section.health_check == "1" then
                table.insert(server_block, string.format("            health_check interval=%ss uri=%s;",
                    section.check_interval or 30,
                    section.check_path or "/health"))
            end

            -- 连接超时设置
            table.insert(server_block, "            proxy_connect_timeout 60s;")
            table.insert(server_block, "            proxy_read_timeout 600s;")

            table.insert(server_block, "        }")
            table.insert(server_block, "    }")
            table.insert(server_block, "")

            config = util.merge(config, server_block)
        end
    end)

    table.insert(config, "}")

    -- 写入配置文件
    local ok = fs.writefile("/etc/nginx/nginx-proxy.conf", table.concat(config, "\n"))
    if not ok then
        sys.log("Failed to write Nginx configuration file")
        return false
    end

    -- 测试并重新加载配置
    local test = sys.call("nginx -t 2>/tmp/nginx-test.log")
    if test == 0 then
        return sys.call("/etc/init.d/nginx reload") == 0
    else
        sys.log("Nginx configuration test failed, check /tmp/nginx-test.log")
        return false
    end
end

function action_apply()
    local success = generate_config()
    http.redirect(http.build_url("admin/services/nginx-proxy", 
        success and "?status=success" or "?status=failed"))
end

function action_clearlogs()
    local log_path = uci:get("nginx-proxy", "global", "log_path") or "/var/log/nginx/proxy.log"
    if fs.access(log_path) then
        if fs.writefile(log_path, "") then
            http.redirect(http.build_url("admin/services/nginx-proxy/logs?cleared=true"))
        else
            http.status(500, "Failed to clear logs")
        end
    else
        http.status(404, "Log file not found")
    end
end

function action_downloadlogs()
    local log_path = uci:get("nginx-proxy", "global", "log_path") or "/var/log/nginx/proxy.log"
    if fs.access(log_path) then
        http.header("Content-Disposition", "attachment; filename=nginx-proxy.log")
        http.prepare_content("text/plain")
        http.write(fs.readfile(log_path))
        return
    end
    http.status(404, "Log file not found")
end
