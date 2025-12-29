--[[
LuCI - Lua Configuration Interface
]] --
local http = require 'luci.http'
local util = require "luci.util"
local taskd = require "luci.model.tasks"
local docker = require "luci.docker"
local zdinnav_model = require "luci.model.zdinnav"
local m, s, o

-- 是否安装检查
local container_status = util.trim(util.exec("/usr/libexec/istorec/zdinnav.sh status"))
local isInstalled = (string.len(container_status) > 0) or container_status == "running"

local container_https = util.trim(util.exec("/usr/libexec/istorec/zdinnav.sh protocol"))
local isResetHttp = isInstalled and container_https == "https"

-- 重置http按钮
local resetHttp_button = isResetHttp and ("," .. translate(
    "If HTTPS is inaccessible, you can revert to <a href=\"javascript:void(0)\" onclick=\"onResetHttp()\">HTTP access here</a>.")) or
                             "";

m = taskd.docker_map("zdinnav", "zdinnav", "/usr/libexec/istorec/zdinnav.sh", translate("ZdinNav"),
    translate("ZdinNav software is a bookmark management tool for websites.") .. translate("Git website:") ..
        ' <a href=\"https://github.com/MyTkme/ZdinNav-Link\" target=\"_blank\">https://github.com/MyTkme/ZdinNav-Link</a>' ..
        '<br/>' .. translatef(
        "If you have any suggestions for this program, please join my %sgroup — your participation will help make it even better!",
        "<a target=\"_blank\" href=\"https://qm.qq.com/q/2jzO6bYQEI\">QQ</a>") .. '<br/>' .. 
        translate("Default Ultra-Super Administrator:zdinnav Password:pwd123") .. '<br/>' ..
        (isInstalled and (translate(
            "If you forget the super administrator passwor, you can <a href=\"javascript:void(0)\" onclick=\"onResetPassword()\">reset it here</a>") ..
            resetHttp_button) or ""))

local dk = docker.new({
    socket_path = "/var/run/docker.sock"
})
local dockerd_running = dk:_ping().code == 200
local docker_info = dockerd_running and dk:info().body or {}
local docker_aspace = 0
if docker_info.DockerRootDir then
    local statvfs = nixio.fs.statvfs(docker_info.DockerRootDir)
    docker_aspace = statvfs and (statvfs.bavail * statvfs.bsize) or 0
end

s = m:section(SimpleSection, translate("Service Status"))
s:append(Template("zdinnav/status"))

s = m:section(TypedSection, "main", translate("Setup"), (docker_aspace < 540016640 and
    (translate("The free space of Docker is less than 512M, which may cause the installation to fail.") .. "<br>") or ""))

s.addremove = false
s.anonymous = true

-- 常规设置(第一个页签)
s:tab("general", translate("General Settings"),
    translate("The following parameters will only take effect during installation or upgrade."))

-- 高级设置(第二个页签)
s:tab("advanced", translate("Advanced Settings"), translate(
    "Takes effect when the database is initially created, or when the /ZdinNav/ folder under the configuration file path does not contain any data.") ..
    "<br/><span style=\"color:red;\">" ..
    translate(
        "Modifying errors may result in data loss or system failure to boot properly. Please proceed with caution!") ..
    "</span>")

-- 第一个标签页的选项
o = s:taboption("general", Value, "port", translate("Port") .. "<b>*</b>")
o.default = "9200"
o.datatype = "port"

local blocks = zdinnav_model.blocks()
local home = zdinnav_model.home()

o = s:taboption("general", Value, "config_path", translate("Config path") .. "<b>*</b>")
o.rmempty = false
o.datatype = "string"

local paths, default_path = zdinnav_model.find_paths(blocks, home, "Configs")
for _, val in pairs(paths) do
    o:value(val, val)
end
o.default = default_path

-- 离线安装配置
local auto_arch = util.trim(util.exec("/usr/libexec/istorec/zdinnav.sh auto_get_arch"))
o = s:taboption("general", Flag, "enable_offline_installation", translate("Enable Offline Installation"))
o.default = "0"
o.rmempty = false

o = s:taboption("general", DummyValue, "offline_installation_path", translate("Offline Installation Path"))
o:depends("enable_offline_installation", "1")
o.template = "cbi/dvalue"
o.rawhtml = true
o.value = [[<div>]] .. translate("Offline Installation Description") .. auto_arch .. [[<br/>]] ..
              translate("Offline Installation Path Rules") .. [[(]] .. translate("Config path") ..
              [[/downloads/*.tar)：<span class="span-offline-installation-path" name="span_offline_installation_path">]] ..
              default_path ..
              [[/downloads/*.tar</span><br/><button class="a-btn-offline btn cbi-button cbi-button-apply" type="button" onclick="offline_installation_Verify()">]] ..
              translate("Offline Installation Path Verify") .. [[</button></div>]]

o = s:taboption("general", Value, "config_path_change_tag")
o.template = "zdinnav/local_install"
o.default = "config_path"
o.datatype = "enable_offline_installation"

-- 第二个标签页的选项
o = s:taboption("advanced", Value, "database_type", translate("Database Type"))
o.datatype = "string"
o:value("Sqlite", "Sqlite")
o:value("PostgreSQL", "PostgreSQL")
o:value("MySql", "MySql")

o = s:taboption("advanced", Value, "connection_settings", translate("Connection Settings"))
o.datatype = "string"

o = s:taboption("advanced", Value, "administrator_account", translate("Administrator Account"))
o.datatype = "string"

o = s:taboption("advanced", Value, "administrator_password", translate("Password"))
o.password = true
o.datatype = "string"

return m
