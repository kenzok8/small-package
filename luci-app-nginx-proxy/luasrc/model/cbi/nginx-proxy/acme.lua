local uci = luci.model.uci.cursor()
local fs = require "nixio.fs"
local sys = require "luci.sys"
local http = require "luci.http"
local util = require "luci.util"
local nixio = require "nixio"

m = Map("nginx-proxy", translate("ACME Automation"),
    translate("Automated Certificate Management using ACME protocol (Let's Encrypt)"))

-- 添加版本控制头
m.on_init = function(self)
    http.header("X-ACME-Config-Version", "2.2")
end

s = m:section(NamedSection, "acme", "acme", translate("ACME Settings"))

-- 启用ACME增强 ---------------------------------------------------------------
enable = s:option(Flag, "enabled", translate("Enable ACME"),
    translate("Automatically obtain and renew SSL certificates"))
enable.rmempty = false

-- 增强邮箱验证 ---------------------------------------------------------------
email = s:option(Value, "email", translate("Account Email"),
    translate("Required for certificate notifications"))
email.datatype = "email"
email:depends("enabled", "1")
function email.validate(self, value)
    if not value:match("^[%w%._-]+@[%w%._-]+%.[%a]+$") then
        return nil, translate("Invalid email format")
    end
    return value
end

-- 增强域名验证（支持通配符和IDN）--------------------------------------------
domains = s:option(DynamicList, "domains", translate("Certificate Domains"),
    translate("Main domain first, supports punycode and wildcards"))
domains:depends("enabled", "1")
function domains.validate(self, value)
    local idn_check = sys.exec("which idn2") ~= ""
    for _, domain in ipairs(value) do
        -- 转换IDN为punycode
        if domain:match("^xn--") and idn_check then
            domain = sys.exec("idn2 -d "..domain:gsub("'", "")) or domain
        end
        
        if not domain:match("^(%*%.)?([a-zA-Z0-9_-]+%.)+[a-zA-Z]{2,}$") and
           not domain:match("^([a-zA-Z0-9_-]+%.)+[a-zA-Z]{2,}$") then
            return nil, translatef("Invalid domain: %s", domain)
        end
    end
    return value
end

-- ACME服务器增强 ------------------------------------------------------------
server = s:option(ListValue, "server", translate("ACME Server"))
server:depends("enabled", "1")
server:value("https://acme-v02.api.letsencrypt.org/directory", translate("Let's Encrypt Production"))
server:value("https://acme-staging-v02.api.letsencrypt.org/directory", translate("Let's Encrypt Staging"))
server:value("https://acme.zerossl.com/v2/DV90", "ZeroSSL")
server.default = "https://acme-v02.api.letsencrypt.org/directory"

-- 验证方式增强 ---------------------------------------------------------------
validation = s:option(ListValue, "validation", translate("Validation Method"))
validation:depends("enabled", "1")
validation:value("http", "HTTP-01 (Webroot)", 
    translate("Requires port 80 accessible"))
validation:value("dns", "DNS-01 (Recommended)", 
    translate("Supports wildcard certificates"))
validation.default = "dns"

-- Webroot路径增强 -----------------------------------------------------------
webroot = s:option(Value, "webroot", translate("Webroot Path"),
    translate("Must be writable by Nginx process"))
webroot:depends("validation", "http")
webroot.default = "/var/lib/acme-challenge"
function webroot.validate(self, value)
    if not fs.stat(value) then
        fs.mkdirr(value)
        fs.chmod(value, 755)
        fs.chown(value, "nginx", "nginx")
    end
    return value
end

-- DNS提供商增强 -------------------------------------------------------------
dns_provider = s:option(ListValue, "dns_provider", translate("DNS Provider"))
dns_provider:depends("validation", "dns")
dns_provider:value("cloudflare", "Cloudflare")
dns_provider:value("route53", "AWS Route53")
dns_provider:value("aliyun", "Aliyun DNS")
dns_provider:value("digitalocean", "DigitalOcean")
dns_provider:value("gcp", "Google Cloud DNS")
dns_provider:value("custom", "Custom API")
dns_provider.default = "cloudflare"

-- 安全处理API凭证 -----------------------------------------------------------
api_credentials = s:option(Value, "api_credentials", translate("API Credentials"))
api_credentials.template = "cbi/tvalue"
api_credentials.rows = 3
api_credentials:depends("dns_provider", "cloudflare")
api_credentials:depends("dns_provider", "aliyun")
api_credentials:depends("dns_provider", "digitalocean")
api_credentials:depends("dns_provider", "route53")
api_credentials:depends("dns_provider", "gcp")

function api_credentials.cfgvalue(self, section)
    return uci:get("nginx-proxy", section, "api_credentials") or ""
end

function api_credentials.write(self, section, value)
    -- 加密存储敏感信息
    local encrypted = sys.exec("echo '"..value.."' | openssl aes-256-cbc -salt -a")
    uci:set("nginx-proxy", section, "api_credentials", encrypted)
end

-- 自定义脚本增强 ------------------------------------------------------------
custom_api = s:option(Value, "custom_api", translate("Custom Script"),
    translate("Must implement acme.sh DNS API requirements"))
custom_api:depends("dns_provider", "custom")
custom_api.datatype = "file"
function custom_api.validate(self, value)
    if not fs.access(value, "rx") then
        return nil, translate("Script must be executable")
    end
    return value
end

-- 证书状态增强 --------------------------------------------------------------
cert_status = s:option(DummyValue, "_status", translate("Certificate Status"))
cert_status.template = "nginx-proxy/acme_status"
cert_status:depends("enabled", "1")

-- 操作按钮增强 --------------------------------------------------------------
action = s:option(DummyValue, "_actions", translate("Operations"))
action.template = "nginx-proxy/acme_actions"

-- 增强ACME命令构建 ----------------------------------------------------------
local function build_acme_cmd()
    local cmd = {
        "ACME_OPTS='",
        "--server "..uci:get("nginx-proxy", "acme", "server"),
        "--email "..uci:get("nginx-proxy", "acme", "email"),
        "--keylength ec-384",  -- 使用ECC证书
        "--force"
    }
    
    -- 添加域名
    local domains = uci:get("nginx-proxy", "acme", "domains") or {}
    if #domains > 0 then
        cmd[#cmd+1] = "-d "..table.concat(domains, " -d ")
    end
    
    -- 验证方式
    if uci:get("nginx-proxy", "acme", "validation") == "http" then
        cmd[#cmd+1] = "--webroot "..uci:get("nginx-proxy", "acme", "webroot")
    else
        local provider = uci:get("nginx-proxy", "acme", "dns_provider")
        cmd[#cmd+1] = "--dns "..provider
        
        -- 处理加密的API凭证
        if provider ~= "custom" then
            local cred_file = "/tmp/acme_creds."..nixio.crypto.rand_bytes(8)
            local encrypted = uci:get("nginx-proxy", "acme", "api_credentials")
            local decrypted = sys.exec("echo '"..encrypted.."' | openssl aes-256-cbc -d -a")
            fs.writefile(cred_file, decrypted)
            fs.chmod(cred_file, 600)
            
            cmd[#cmd+1] = string.format("--%s-credentials %s", provider, cred_file)
            cmd[#cmd+1] = "--cleanup"  -- 自动删除临时凭证
        end
    end
    
    return table.concat(cmd, " ").."'"
end

-- 增强证书申请处理 ----------------------------------------------------------
function action.write(self, section, value)
    local log_file = "/var/log/acme.log"
    local cmd = build_acme_cmd().." 2>&1 | tee "..log_file
    
    local handle = io.popen(cmd)
    local output = handle:read("*a")
    handle:close()
    
    if fs.access("/root/.acme.sh/*/fullchain.cer") then
        update_cert_paths()
        sys.call("/etc/init.d/nginx reload")
        m.message = translate("Certificate issued successfully")
    else
        m.message = translatef("Failed: %s", output:match("ERROR:(.*)"))
    end
end

-- 增强证书路径更新 ----------------------------------------------------------
function update_cert_paths()
    local main_domain = (uci:get("nginx-proxy", "acme", "domains") or ""):match("([^%s]+)")
    if main_domain then
        main_domain = main_domain:gsub("^%*%.", "")
        local cert_dir = "/root/.acme.sh/"..main_domain.."/"
        
        uci:set("nginx-proxy", "ssl", "cert_path", cert_dir.."fullchain.cer")
        uci:set("nginx-proxy", "ssl", "key_path", cert_dir..main_domain..".key")
        uci:commit("nginx-proxy")
    end
end

-- 增强定时任务管理 ----------------------------------------------------------
function m.on_commit(self)
    if uci:get_bool("nginx-proxy", "acme", "enabled") then
        -- 使用LuCI定时任务管理
        local cron = uci:get_all("cron", "acme_renew") or {}
        cron.command = build_acme_cmd().." --cron"
        cron.minute = "0"
        cron.hour = "3"
        cron.day = "*"
        cron.month = "*"
        cron.weekday = "*"
        
        uci:section("cron", "cron", "acme_renew", cron)
        uci:commit("cron")
        sys.call("/etc/init.d/cron restart")
    else
        uci:delete("cron", "acme_renew")
        uci:commit("cron")
    end
end

-- 输入验证增强 --------------------------------------------------------------
function m.validate(self)
    if uci:get("nginx-proxy", "acme", "validation") == "dns" then
        local provider = uci:get("nginx-proxy", "acme", "dns_provider")
        if provider == "custom" and not fs.access(uci:get("nginx-proxy", "acme", "custom_api")) then
            return nil, translate("Custom API script not found")
        end
    end
    return true
end

return m
