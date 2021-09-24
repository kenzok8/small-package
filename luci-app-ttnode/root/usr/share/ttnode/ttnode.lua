-- Copyright (C) 2020 jerrykuku <jerrykuku@gmail.com>
-- Licensed to the public under the GNU General Public License v3.
package.path = package.path .. ';/usr/share/ttnode/?.lua'
local uci = require 'luci.model.uci'.cursor()
local config = 'ttnode'
local requests = require('requests')
local BASE_URL = 'http://tiantang.mogencloud.com/web/api/'
local BASE_API = 'http://tiantang.mogencloud.com/api/v1/'
local xformHeaders = {['Content-Type'] = 'application/x-www-form-urlencoded'}

local sckey = uci:get_first(config, 'global', 'serverchan')
local tg_token = uci:get_first(config, 'global', 'tg_token')
local tg_userid = uci:get_first(config, 'global', 'tg_userid')
local token = uci:get_first(config, 'global', 'token')

local auto_cash = uci:get_first(config, 'global', 'auto_cash')
local week = uci:get_first(config, 'global', 'week')
local ttnode = {}
local msg = ''
local total = 0
local msgTitle = '[甜糖星愿]星愿日结详细'

-- BASE Function --

function print_r(t)
    local print_r_cache = {}
    local function sub_print_r(t, indent)
        if (print_r_cache[tostring(t)]) then
            print(indent .. '*' .. tostring(t))
        else
            print_r_cache[tostring(t)] = true
            if (type(t) == 'table') then
                for pos, val in pairs(t) do
                    if (type(val) == 'table') then
                        print(indent .. '[' .. pos .. '] => ' .. tostring(t) .. ' {')
                        sub_print_r(val, indent .. string.rep(' ', string.len(pos) + 8))
                        print(indent .. string.rep(' ', string.len(pos) + 6) .. '}')
                    elseif (type(val) == 'string') then
                        print(indent .. '[' .. pos .. '] => "' .. val .. '"')
                    else
                        print(indent .. '[' .. pos .. '] => ' .. tostring(val))
                    end
                end
            else
                print(indent .. tostring(t))
            end
        end
    end
    if (type(t) == 'table') then
        print(tostring(t) .. ' {')
        sub_print_r(t, '  ')
        print('}')
    else
        sub_print_r(t, '  ')
    end
    print()
end

function sleep(n)
    os.execute('sleep ' .. n)
end

--APIS--

--发送消息到Server酱 和 Telegram
function ttnode.sendMsg(text, desp)
    if sckey:len() > 0 then
        local url = 'https://sc.ftqq.com/' .. sckey .. '.send'
        local data = 'text=' .. text .. '&desp=' .. desp
        response = requests.post {url, data = data, headers = xformHeaders}
    end
    if tg_token:len() > 0 and tg_userid:len() > 0 then
        local tg_url = 'https://api.telegram.org/bot' .. tg_token .. '/sendMessage'
        local tg_msg = "<b>"..text.."</b>"..desp
        local tg_data = 'chat_id='.. tg_userid ..'&text=' .. tg_msg .. '&parse_mode=html'
        response = requests.post {tg_url, data = tg_data, headers = xformHeaders}
    end
    return 1
end

--获取验证码
function ttnode.getCode(phone)
    url = BASE_URL .. 'login/code'
    data = 'phone=' .. phone
    response = requests.post {url, data = data, headers = xformHeaders}
    json_body, error = response.json()
    return json_body
end

-- 登录
function ttnode.login(phone, authCode)
    url = BASE_URL .. 'login'
    data = 'phone=' .. phone .. '&authCode=' .. authCode
    response = requests.post {url, data = data, headers = xformHeaders}
    json_body, error = response.json()
    if json_body.errCode == 0 then
        token = json_body.data.token
        uci:set('ttnode', '@global[0]', 'token', token)
        uci:commit('ttnode')
        return true
    else
        return false
    end
end

--甜糖用户初始化信息，可以获取待收取的推广信息数，可以获取账户星星数
function ttnode.getInitInfo()
    url = BASE_URL .. 'account/message/loading'
    headers = {['Content-Type'] = 'application/json', ['authorization'] = token}
    response = requests.post {url, headers = headers}
    json_body, error = response.json()
    return json_body
end

--获取当前设备列表，可以获取待收的星星数
function ttnode.getDevices()
    url = BASE_API .. 'devices?page=1&type=2&per_page=200'
    headers = {['Content-Type'] = 'application/json', ['authorization'] = token}
    response = requests.get {url, headers = headers}
    json_body, error = response.json()
    return json_body
end

--收取推广奖励星星
function ttnode.promote_score_logs(score)
    if score == 0 then
        msg = msg .. '\n ' .. os.date('%Y-%m-%d %H:%M:%S') .. '[推广奖励]0-🌟\n'
        return
    end
    url = BASE_API .. 'promote/score_logs'
    headers = {['Content-Type'] = 'application/json', ['authorization'] = token}
    data = {score = score}
    response = requests.post {url, data = data, headers = headers}
    json_body, error = response.json()
    if json_body.errCode ~= 0 then
        msg = msg .. '\n' .. os.date('%Y-%m-%d %H:%M:%S') .. ' [推广奖励]0-🌟\n'
        return
    end
    msg = msg .. '\n ' .. os.date('%Y-%m-%d %H:%M:%S') .. '[推广奖励]"..score.."-🌟\n'
    total = total + score
    return
end

--收取设备奖励
function ttnode.score_logs(device_id, score, name)
    if score == 0 then
        msg = msg .. '\n ' .. os.date('%Y-%m-%d %H:%M:%S') .. '[' .. name .. ']0-🌟\n'
        return
    end
    url = BASE_API .. 'score_logs'
    headers = {['Content-Type'] = 'application/json', ['authorization'] = token}
    data = {device_id = device_id, score = score}
    response = requests.post {url, data = data, headers = headers}
    json_body, error = response.json()
    if json_body.errCode ~= 0 then
        msg = msg .. '\n ' .. os.date('%Y-%m-%d %H:%M:%S') .. '[' .. name .. ']0-🌟\n'
        return
    end
    msg = msg .. '\n ' .. os.date('%Y-%m-%d %H:%M:%S') .. '[' .. name .. ']' .. score .. '-🌟\n'
    total = total + tonumber(score)
    return
end

--签到功能
function ttnode.sign_in()
    url = BASE_URL .. 'account/sign_in'
    headers = {['Content-Type'] = 'application/json', ['authorization'] = token}
    response = requests.post {url, headers = headers}
    json_body, error = response.json()

    if json_body.errCode ~= 0 then
        msg = msg .. '\n ' .. os.date('%Y-%m-%d %H:%M:%S') .. '[签到奖励]0-🌟(失败:' .. json_body.msg .. ')\n'
        return
    end
    msg = msg .. '\n ' .. os.date('%Y-%m-%d %H:%M:%S') .. '[签到奖励]1-🌟 \n'
    total = total + 1
    return
end

--支付宝提现
function ttnode.withdraw_logs(bean)
    local logStr = ''
    url = BASE_API .. 'withdraw_logs'
    score = bean.score
    score = score - score % 100
    real_name = bean.real_name
    card_id = bean.card_id
    bank_name = '支付宝'
    sub_bank_name = ''
    ztype = 'zfb'
    if score < 1000 then
        logStr = '\n' .. os.date('%Y-%m-%d %H:%M:%S') .. '[自动提现]星愿不足1000无法提现\n'
        return logStr
    end
    data = 'score=' .. score .. '&real_name=' .. real_name .. '&card_id=' .. card_id .. '&bank_name=' .. bank_name .. '&sub_bank_name=' .. sub_bank_name .. '&type=' .. ztype
    print(data)
    headers = {['Content-Type'] = 'application/x-www-form-urlencoded;charset=UTF-8', ['authorization'] = token}
    response = requests.post {url, data = data, headers = headers}
    json_body, error = response.json()
    if json_body.errCode ~= 0 then
        print(json_body.msg .. score)
        logStr = '\n' .. os.date('%Y-%m-%d %H:%M:%S') .. '[自动提现]提现失败，请关闭自动提现等待更新\n'
        return logStr
    end
    local data = json_body.data
    zfbID = data.card_id
    pre = string.sub(zfbID, 1, 5)
    ends = string.sub(zfbID, -5)
    zfbID = pre .. '***' .. ends
    logStr = '\n' .. os.date('%Y-%m-%d %H:%M:%S') .. '[自动提现]扣除' .. score .. '-🌟(' .. zfbID .. ')\n'
    return logStr
end

--逻辑处理

function ttnode.startProcess()
    local resObj = {}

    --获取用户信息
    local userData = ttnode.getInitInfo()
    if userData.errCode ~= 0 then
        resObj.code = 1
        resObj.msg = os.date('%Y-%m-%d %H:%M:%S') .. ' authorization已经失效，请重新抓包填写!'
        ttnode.sendMsg(os.date('%Y-%m-%d %H:%M:%S') .. '[甜糖星愿]-Auth失效通知', resObj.msg)
        return resObj
    end
    local inactivedPromoteScore = userData.data.inactivedPromoteScore
    local accountScore = userData.data.score

    --获取设备列表信息
    local devices = ttnode.getDevices().data.data
    msg = msg .. '\n' .. os.date('%Y-%m-%d %H:%M:%S') .. '[收益详细]：\n```lua'
    --收取签到收益
    ttnode.sign_in()
    --收取推广收益
    ttnode.promote_score_logs(inactivedPromoteScore)
    --收取设备收益
    for _, device in pairs(devices) do
        ttnode.score_logs(device.hardware_id, device.inactived_score, device.alias)
    end

    --自动提现
    local now_week = os.date('%A')
    local withdraw = ''
    if week == now_week and auto_cash == '1' then
        local userInfo = userData.data
        local zfbList = userInfo.zfbList
        if next(zfbList) == nil then
            withdraw = '\n' .. os.date('%Y-%m-%d %H:%M:%S') .. '[自动提现]提现失败，请绑定支付宝账户\n'
        else
            local bean = {}
            bean.score = userInfo.score
            bean.real_name = zfbList[1].name
            bean.card_id = zfbList[1].account
            withdraw = ttnode.withdraw_logs(bean)
        end
    end

    --收益统计并发送微信消息
    local total_str = '\n' .. os.date('%Y-%m-%d %H:%M:%S') .. '[总共收取]' .. total .. '-🌟\n'
    local nowdata = ttnode.getInitInfo()
    local accountScore = nowdata.data.score
    local accountScore_str = '\n' .. os.date('%Y-%m-%d %H:%M:%S') .. '[账户星星]' .. accountScore .. '-🌟\n'
    local ends = '\n```\n***\n注意:以上统计仅供参考，一切请以甜糖客户端APP为准'
    msg = accountScore_str .. total_str .. withdraw .. msg .. ends
    msgRes = ttnode.sendMsg(msgTitle, msg)
    resObj.code = 0
    resObj.msg = msg
    resObj.msgres = msgRes
    return resObj
end

return ttnode
