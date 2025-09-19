local uci = luci.model.uci.cursor()
local fs = require "nixio.fs"
local sys = require "luci.sys"
local util = require "luci.util"

m = Map("nginx-proxy", translate("SSL Configuration"),
    translate("Configure SSL/TLS settings for HTTPS support"))

-- 添加版本控制头
m.on_init = function(self)
    http.headers["X-Nginx-Proxy-Version"] = "2.1"
end

s = m:section(NamedSection, "ssl", "ssl", translate("SSL Settings"))

-- 增强型SSL启用选项 ----------------------------------------------------------
enable = s:option(Flag, "enabled", translate("Enable SSL"),
    translate("Requires valid certificate and private key"))
enable.rmempty = false

-- 证书路径增强验证 ----------------------------------------------------------
cert = s:option(Value, "cert_path", translate("Certificate Path"),
    translate("Path to SSL certificate file (PEM format)"))
cert:depends("enabled", "1")
cert.datatype = "file"
cert.default = "/etc/nginx/ssl/cert.pem"

function cert.validate(self, value)
    -- 增强证书验证逻辑
    if not value or value == "" then return nil, "Path required" end
    
    if not fs.access(value) then
        return nil, translate("Certificate file not found")
    end
    
    local content = fs.readfile(value) or ""
    if not content:match("-----BEGIN%-%-CERTIFICATE%-%-") then
        return nil, translate("Invalid certificate format (PEM required)")
    end
    
    -- 验证证书有效期
    local expiry = sys.exec("openssl x509 -enddate -noout -in "..value.." 2>&1")
    if expiry:match("not found") then
        return nil, translate("Invalid certificate: ")..expiry
    end
    
    return value
end

-- 私钥路径增强验证 ----------------------------------------------------------
key = s:option(Value, "key_path", translate("Private Key Path"),
    translate("Path to private key file (PEM format)"))
key:depends("enabled", "1")
key.datatype = "file"
key.default = "/etc/nginx/ssl/key.pem"

function key.validate(self, value)
    if not value or value == "" then return nil, "Path required" end
    
    if not fs.access(value) then
        return nil, translate("Private key file not found")
    end
    
    local content = fs.readfile(value) or ""
    if not content:match("-----BEGIN%s(EC|RSA|) PRIVATE KEY-----") then
        return nil, translate("Invalid private key format (PEM required)")
    end
    
    -- 验证私钥是否加密
    if content:match("ENCRYPTED") then
        return nil, translate("Encrypted private keys are not supported")
    end
    
    return value
end

-- 高级选项容器（添加动态加载提示）-------------------------------------------
adv = s:option(DummyValue, "_adv", "")
adv.template = "nginx-proxy/ssl_adv_options"
adv.rawhtml = true

-- 协议版本选择（增强安全性）-------------------------------------------------
protocols = s:option(ListValue, "protocols", translate("SSL Protocols"),
    translate("<a href='https://ssl-config.mozilla.org/' target='_blank'>Recommended settings</a>"))
protocols:depends("enabled", "1")
protocols:value("TLSv1.2 TLSv1.3", "Modern (TLS 1.2 + 1.3)")
protocols:value("TLSv1.3", "Strict (TLS 1.3 Only)")
protocols.default = "TLSv1.2 TLSv1.3"

-- 现代加密套件配置 ----------------------------------------------------------
ciphers = s:option(Value, "ciphers", translate("Cipher Suites"),
    translate("Recommended: ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256"))
ciphers:depends("enabled", "1")
ciphers.default = "ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256"

function ciphers.validate(self, value)
    if not value:match("^[A-Z0-9%-_+:]+$") then
        return nil, translate("Invalid cipher format (use colon-separated OpenSSL names)")
    end
    return value
end

-- 增强HSTS配置 --------------------------------------------------------------
hsts = s:option(Flag, "hsts", translate("Enable HSTS"),
    translate("Enforces HTTPS-only access"))
hsts:depends("enabled", "1")

hsts_age = s:option(Value, "hsts_age", translate("Max Age"),
    translate("Seconds (31536000 = 1 year)"))
hsts_age.datatype = "uinteger"
hsts_age.default = "31536000"
hsts_age:depends("hsts", "1")

hsts_include_sub = s:option(Flag, "hsts_include_sub", translate("Include Subdomains"))
hsts_include_sub.default = "0"
hsts_include_sub:depends("hsts", "1")

hsts_preload = s:option(Flag, "hsts_preload", translate("Preload List"))
hsts_preload.description = translate("Caution: Cannot be undone!")
hsts_preload:depends("hsts", "1")

-- OCSP增强配置 --------------------------------------------------------------
ocsp = s:option(Flag, "ocsp", translate("OCSP Stapling"),
    translate("Improves SSL handshake performance"))
ocsp:depends("enabled", "1")

-- 会话缓存优化 --------------------------------------------------------------
session_cache = s:option(ListValue, "session_cache", translate("Session Cache"))
session_cache:value("none", translate("Disable"))
session_cache:value("builtin", "Built-in (default)")
session_cache:value("shared:SSL:50m", "Shared (50MB)")
session_cache.default = "shared:SSL:50m"
session_cache:depends("enabled", "1")

-- 智能证书管理 --------------------------------------------------------------
function m.on_parse(self)
    if enable:formvalue("ssl") == "1" then
        -- ACME证书自动检测增强
        local acme_enabled = uci:get_bool("nginx-proxy", "acme", "enabled")
        if acme_enabled then
            local domain = uci:get("nginx-proxy", "proxy", "domain")
            if domain then
                local cert_dir = "/etc/ssl/acme/%s/" % domain
                if fs.stat(cert_dir) then
                    local cert_path = cert_dir.."fullchain.pem"
                    local key_path = cert_dir.."privkey.pem"
                    if fs.access(cert_path) and fs.access(key_path) then
                        uci:set("nginx-proxy", "ssl", "cert_path", cert_path)
                        uci:set("nginx-proxy", "ssl", "key_path", key_path)
                    end
                end
            end
        end

        -- 增强证书密钥匹配验证
        local cert_file = cert:formvalue("ssl") or ""
        local key_file = key:formvalue("ssl") or ""
        if cert_file ~= "" and key_file ~= "" then
            local cert_check = sys.exec("openssl x509 -noout -modulus -in "..cert_file.." 2>/dev/null | openssl sha256")
            local key_check = sys.exec("openssl rsa -noout -modulus -in "..key_file.." 2>/dev/null | openssl sha256")
            
            if cert_check ~= key_check then
                m.message = translate("Certificate and private key mismatch!")
                uci:revert("nginx-proxy")
            end
        end
    end
end

-- 配置应用增强处理 ----------------------------------------------------------
function m.on_commit(self)
    if enable:formvalue("ssl") == "1" then
        -- 安全创建SSL目录
        local ssl_dir = "/etc/nginx/ssl"
        if not fs.stat(ssl_dir) then
            fs.mkdirr(ssl_dir)
            fs.chmod(ssl_dir, 700)
            fs.chown(ssl_dir, "root", "root")
        end

        -- 触发安全配置生成
        local ok = sys.call("/usr/libexec/nginx-proxy/generate-config --safe 2>/tmp/nginx-proxy.log")
        if ok ~= 0 then
            local errors = fs.readfile("/tmp/nginx-proxy.log") or ""
            luci.http.redirect(luci.dispatcher.build_url("admin/services/nginx-proxy/ssl?error="..util.urlencode(errors)))
        end
    end
end

-- 添加证书预览功能 ----------------------------------------------------------
s:option(DummyValue, "_cert_preview", translate("Certificate Info")).template = "nginx-proxy/cert_preview"

return m
