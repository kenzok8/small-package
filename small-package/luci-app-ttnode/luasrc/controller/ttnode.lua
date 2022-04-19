-- Copyright (C) 2020 jerrykuku <jerrykuku@gmail.com>
-- Licensed to the public under the GNU General Public License v3.
module('luci.controller.ttnode', package.seeall)
package.path = package.path .. ';/usr/share/ttnode/?.lua'
local ttnode = require('ttnode')
function index()
    if not nixio.fs.access('/etc/config/ttnode') then
        return
    end
    entry({'admin', 'services', 'ttnode'}, alias('admin', 'services', 'ttnode', 'client'), _('甜糖星愿自动采集'), 0).dependent = true -- 首页
    entry({'admin', 'services', 'ttnode', 'client'}, cbi('ttnode', {hideapplybtn = true,hidesavebtn= true,hideresetbtn = true}), nil, 10).leaf = true -- 基本设置
    entry({"admin", "services", "ttnode", "get_code"}, call("getCode")) -- 获取验证码
    entry({"admin", "services", "ttnode", "login"}, call("login")) -- 登录
    entry({"admin", "services", "ttnode", "run"}, call("run")) -- 执行
    entry({"admin", "services", "ttnode", "save"}, call("save")) -- 保存
end

--获取验证码
function getCode()
    local e = {}
    local phone = luci.http.formvalue("phone")
    e.error = 1
    if phone ~= "" and phone ~= nil  then
        local res = ttnode.getCode(phone)
        if res.errCode == 0 then
            e.error = 0
        else
            e.error = 1
        end
    end
    luci.http.prepare_content("application/json")
    luci.http.write_json(e)
end

--登录
function login()
    local e = {}
    e.error = 1
    local phone = luci.http.formvalue("phone")
    local code = luci.http.formvalue("code")
    if phone ~= "" and phone ~= nil and code ~= nil and code ~= ""  then
        local res = ttnode.login(phone,code)
        e.error = res == true and 0 or 1
    end
    luci.http.prepare_content("application/json")
    luci.http.write_json(e)
end

--保存
function save()
    local e = {}
    local uci = luci.model.uci.cursor()
    local auto_run = luci.http.formvalue("auto_run")
    local auto_run_time = luci.http.formvalue("auto_run_time")
    local auto_cash = luci.http.formvalue("auto_cash")
    local week = luci.http.formvalue("week")
    local serverchan = luci.http.formvalue("serverchan")
    local tg_userid = luci.http.formvalue("tg_userid")
    local tg_token = luci.http.formvalue("tg_token")
    local name = ""
    uci:set("ttnode", '@global[0]', 'auto_run', auto_run)
    uci:set("ttnode", '@global[0]', 'auto_run_time', auto_run_time)
    uci:set("ttnode", '@global[0]', 'auto_cash', auto_cash)
    uci:set("ttnode", '@global[0]', 'week', week)
    uci:set("ttnode", '@global[0]', 'serverchan', serverchan)
    uci:set("ttnode", '@global[0]', 'tg_userid', tg_userid)
    uci:set("ttnode", '@global[0]', 'tg_token', tg_token)
    uci:save("ttnode")
    uci:commit("ttnode")
    luci.sys.call("/etc/init.d/ttnode restart")
    e.error = 0
    luci.http.prepare_content("application/json")
    luci.http.write_json(e)

end

--执行
function run()
    local e = {}
    e.error = 1
    local res = ttnode.startProcess()
    e.error = res.code == 0 and 0 or 1
    e.msg = res.msg
    luci.http.prepare_content("application/json")
    luci.http.write_json(e)
end