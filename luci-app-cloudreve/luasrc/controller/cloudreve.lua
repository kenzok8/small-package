module("luci.controller.cloudreve", package.seeall)

-- Defensive load: if the api module is missing we simply do not register
-- the menu, instead of throwing during dispatcher pagetree build and
-- taking down the ENTIRE LuCI web UI (seen on a half-installed pkg).
local ok, api = pcall(require, "luci.model.cbi.cloudreve.api")
local fs = require "nixio.fs"

function index()
    if not ok then return end
    if not fs.access("/etc/config/cloudreve") then
        return
    end

    -- NOTE: use dependent=true (same as luci-app-filebrowser) instead of
    -- acl_depends. acl_depends gates the menu behind rpcd ACL grants, which
    -- hides the entry entirely when the ACL is not (yet) loaded -- that made
    -- the menu invisible right after install.
    local e = entry({"admin", "nas", "cloudreve"}, cbi("cloudreve/settings"),
                    translate('Cloudreve 云盘'), 2)
    e.dependent = true
    entry({"admin", "nas"}, firstchild(), "NAS", 45).dependent = false

    entry({"admin", "nas", "cloudreve", "status"}, call("act_status")).leaf = true
    entry({"admin", "nas", "cloudreve", "disks"}, call("act_disks")).leaf = true
    entry({"admin", "nas", "cloudreve", "check"}, call("act_check")).leaf = true
    entry({"admin", "nas", "cloudreve", "download"}, call("act_download")).leaf = true
    entry({"admin", "nas", "cloudreve", "initdir"}, call("act_initdir")).leaf = true
    entry({"admin", "nas", "cloudreve", "svc"}, call("act_svc")).leaf = true
end

-- Service running status (poll for Lua UI)
function act_status()
    local e = {}
    local bin = api.get_binary_path()
    e.running = (luci.sys.call("pgrep -f '" .. bin .. "' >/dev/null") == 0)
    e.installed = api.is_installed()
    e.app_dir = api.get_app_dir()
    e.storage = api.get_storage_root()
    luci.http.prepare_content("application/json")
    luci.http.write_json(e)
end

-- List detected disks for the dropdown
function act_disks()
    local disks = api.get_disks()
    local current = api.get_storage_root()
    luci.http.prepare_content("application/json")
    luci.http.write_json({
        code = 0,
        disks = disks,
        current = current
    })
end

-- Check version / available binary
function act_check()
    local result = api.check_version()
    luci.http.prepare_content("application/json")
    luci.http.write_json(result)
end

-- Create Configs/cloudreve manually (button)
function act_initdir()
    local app_dir = api.ensure_app_dir()
    luci.http.prepare_content("application/json")
    if app_dir then
        luci.http.write_json({
            code = 0,
            app_dir = app_dir,
            message = translate('目录已就绪')
        })
    else
        luci.http.write_json({
            code = 1,
            error = translate('创建 Configs 目录失败，请确认硬盘已挂载且可写')
        })
    end
end

-- Trigger download + install
function act_download()
    local url = luci.http.formvalue("url")
    local result = api.download_install(url)
    luci.http.prepare_content("application/json")
    luci.http.write_json(result)
end

-- 手动启停服务（LuCI 的「保存并应用」只发 reload，服务没起来时 reload 不会拉起它）
function act_svc()
    local act = luci.http.formvalue("action") or ""
    local out = ""
    if act == "start" then
        out = luci.sys.exec("/etc/init.d/cloudreve enable 2>&1; /etc/init.d/cloudreve start 2>&1")
    elseif act == "stop" then
        out = luci.sys.exec("/etc/init.d/cloudreve stop 2>&1")
    elseif act == "restart" then
        out = luci.sys.exec("/etc/init.d/cloudreve enable 2>&1; /etc/init.d/cloudreve restart 2>&1")
    else
        luci.http.prepare_content("application/json")
        luci.http.write_json({ code = 1, error = translate('未知操作') })
        return
    end
    luci.http.prepare_content("application/json")
    luci.http.write_json({ code = 0, output = out })
end
