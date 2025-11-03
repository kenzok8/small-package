module("luci.controller.zdinnav", package.seeall)
require "luci.util"
local http = require "luci.http"

function index()
    entry({"admin", "services", "zdinnav"}, alias("admin", "services", "zdinnav", "config"), _("ZdinNav"), 3).dependent =
        true
    entry({"admin", "services", "zdinnav", "config"}, cbi("zdinnav"))
    -- get请求
    -- entry({"admin", "services", "zdinnav", "check_package"}, call("action_check_package")).leaf = true
    -- post请求
    entry({"admin", "services", "zdinnav", "check_package"}, post("action_check_package")).leaf = true
    entry({"admin", "services", "zdinnav", "reset_http"}, post("action_reset_http")).leaf = true
    entry({"admin", "services", "zdinnav", "reset_password"}, post("action_reset_password")).leaf = true
end

local function http_write_json(data)
    http.prepare_content("application/json")
    http.write_json(data or {
        code = 1
    })
end

function action_check_package()
    local e = {}
    local file_path = luci.http.formvalue("path")
    e.status = luci.util.trim(luci.util.exec("/usr/libexec/istorec/zdinnav.sh check_package " .. file_path))
    http_write_json(e)
end

function action_reset_http()
    local e = {}
    e.status = luci.util.trim(luci.util.exec("/usr/libexec/istorec/zdinnav.sh reset_http"))
    http_write_json(e)
end

function action_reset_password()
    local e = {}
    e.status = luci.util.trim(luci.util.exec("/usr/libexec/istorec/zdinnav.sh reset_password"))
    http_write_json(e)
end
