-- Copyright (C) 2020 jerrykuku <jerrykuku@gmail.com>
-- Licensed to the public under the GNU General Public License v3.
package.path = package.path .. ';/usr/share/ttnode/?.lua'
require 'luci.http'
require 'luci.dispatcher'
require 'luci.model.uci'
require 'luci.sys'
local ttnode = require('ttnode')
local config = 'ttnode'
local uci = luci.model.uci.cursor()

-- 检测登录
local check_login = ttnode.getInitInfo()
local isLogin = check_login.errCode == 0 and true or false

m = Map(config, translate('甜糖星愿自动采集'), translate('可以帮你每日自动收取甜糖心愿的星愿，并且可以指定日期每周自动提现。填写邀请码853288支持作者！'))
s = m:section(TypedSection, 'global', translate('基本设置'))
s.anonymous = true

if (isLogin) then
    local nickname = check_login.data.nickName
    local score = check_login.data.score

    o = s:option(DummyValue, 'info', translate('账户信息'))
    o.rawhtml = true
    o.value = "<p id='userinfo'>" .. nickname .. '  (★ ' .. score .. ')</p>'

    o = s:option(Flag, 'auto_run', translate('自动采集开关'))
    o.rmempty = false

    o = s:option(ListValue, 'auto_run_time', translate('自动运行时间'))
    for t = 0, 23 do
        o:value(t, t .. ':00')
    end
    o.default = 2
    o:depends('auto_run', '1')
    o.description = translate('每天自动运行时间，甜糖星愿每天凌晨1点开始计算星愿')

    o = s:option(Flag, 'auto_cash', translate('自动提现开关'))
    o.rmempty = false

    o = s:option(ListValue, 'week', translate('自动提现日期'))
    o:value('Monday', translate('星期一'))
    o:value('Tuesday', translate('星期二'))
    o:value('Wednesday', translate('星期三'))
    o:value('Thursday', translate('星期四'))
    o:value('Friday', translate('星期五'))
    o:value('Saturday', translate('星期六'))
    o:value('Sunday ', translate('星期天'))
    o.default = 'Thursday'
    o:depends('auto_cash', '1')
    o.description = translate('请选择每周几作为自动提现日期')

    o = s:option(Value, 'serverchan', translate('Server酱 SCKEY'))
    o.rmempty = true
    o.description = translate('微信推送，基于Server酱服务，请自行登录 http://sc.ftqq.com/ 绑定并获取 SCKEY ')

    -- telegram

    o = s:option(Value, 'tg_token', translate('Telegram Bot Token'))
    o.rmempty = true
    o.description = translate('首先在Telegram上搜索BotFather机器人，创建一个属于自己的通知机器人，并获取Token。')

    o = s:option(Value, 'tg_userid', translate('Telegram UserID'))
    o.rmempty = true
    o.description = translate('在Telegram上搜索getuserIDbot机器人，获取UserID。')

    o = s:option(DummyValue, '', '')
    o.rawhtml = true
    o.template = 'ttnode/manually_exec'
else
    o = s:option(DummyValue, '', '')
    o.rawhtml = true
    o.template = 'ttnode/login_form'
end

return m
