
local fs=require"nixio.fs"
local sys = require "luci.sys"

m=Map("pushbot", "", "")
m:section(SimpleSection).template = "pushbot/pushbot_status"

-- Single NamedSection — ALL options defined here for form processing
-- content/advanced/client/log options have .render = function() end to skip HTML rendering (faster page load)
s=m:section(NamedSection,"pushbot","pushbot","")
s.addremove = false
s.anonymous = true

-- 基本设置 (needed by initCard for .cbi-value DOM lookup)
a=s:option( Flag,"pushbot_enable","启用")
a.default=0; a.rmempty = true

a = s:option( MultiValue, "lite_enable", "精简模式")
a:value("device", "精简当前设备列表")
a:value("nowtime", "精简当前时间")
a:value("content", "只推送标题")
a.widget = "checkbox"; a.default = nil

-- 推送模式 (needed by initPushModeCard)
a=s:option( ListValue,"jsonpath","推送模式")
a.default="/usr/bin/pushbot/api/dingding.json"; a.rmempty = true
a:value("/usr/bin/pushbot/api/dingding.json","钉钉")
a:value("/usr/bin/pushbot/api/ent_wechat.json","企业微信")
a:value("/usr/bin/pushbot/api/feishu.json","飞书")
a:value("/usr/bin/pushbot/api/bark.json","Bark")
a:value("/usr/bin/pushbot/api/pushplus.json","PushPlus")
a:value("/usr/bin/pushbot/api/pushdeer.json","PushDeer")
a:value("/usr/bin/pushbot/api/diy.json","自定义推送")

a=s:option( Value,"dd_webhook",'Webhook'); a.rmempty = true
a.description = "钉钉机器人 Webhook，只输入access_token=后面的即可<br>调用代码获取<a href='https://developers.dingtalk.com/document/robots/custom-robot-access' target='_blank'>点击这里</a><br><br>"
a=s:option( Value, "we_webhook", "Webhook"); a.rmempty = true
a.description = "企业微信机器人 Webhook，只输入key=后面的即可<br>调用代码获取<a href='https://work.weixin.qq.com/api/doc/90000/90136/91770' target='_blank'>点击这里</a><br><br>"
a=s:option( Value,"pp_token",'PushPlus Token'); a.rmempty = true
a.description = "PushPlus Token<br>调用代码获取<a href='http://pushplus.plus/doc/' target='_blank'>点击这里</a><br><br>"

a=s:option( ListValue,"pp_channel",'PushPlus Channel'); a.rmempty = true
a:value("wechat","wechat：PushPlus微信公众号")
a:value("cp","cp：企业微信应用")
a:value("webhook","webhook：第三方webhook")
a:value("sms","sms：短信")
a:value("mail","mail：邮箱")
a.description = "第三方webhook：企业微信、钉钉、飞书、server酱<br>sms短信/mail邮箱：PushPlus暂未开放<br>具体channel设定参见：<a href='http://pushplus.plus/doc/extend/webhook.html' target='_blank'>点击这里</a>"

a=s:option( Value,"pp_webhook",'PushPlus Custom Webhook'); a.rmempty = true
a.description = "PushPlus 自定义Webhook<br>第三方webhook或企业微信调用<br>具体自定义Webhook设定参见：<a href='http://pushplus.plus/doc/extend/webhook.html' target='_blank'>点击这里</a><br><br>"
a=s:option( Flag,"pp_topic_enable","PushPlus 一对多推送"); a.default=0; a.rmempty = true
a=s:option( Value,"pp_topic",'PushPlus Topic'); a.rmempty = true
a.description = "PushPlus 群组编码<br>一对多推送时指定的群组编码<br>具体群组编码Topic设定参见：<a href='http://www.pushplus.plus/push2.html' target='_blank'>点击这里</a><br><br>"
a=s:option( Value,"pushdeer_key",'PushDeer Key'); a.rmempty = true
a.description = "PushDeer Key<br>调用代码获取<a href='http://www.pushdeer.com/' target='_blank'>点击这里</a><br><br>"
a=s:option( Flag,"pushdeer_srv_enable","自建 PushDeer 服务器"); a.default=0; a.rmempty = true
a=s:option( Value,"pushdeer_srv",'PushDeer Server'); a.rmempty = true
a.description = "PushDeer 自建服务器地址<br>如https://your.domain:port<br>具体自建服务器设定参见：<a href='http://www.pushdeer.com/selfhosted.html' target='_blank'>点击这里</a><br><br>"
a=s:option( Value,"fs_webhook",'WebHook'); a.rmempty = true
a.description = "飞书 WebHook<br>调用代码获取<a href='https://www.feishu.cn/hc/zh-CN/articles/360024984973' target='_blank'>点击这里</a><br><br>"
a=s:option( Value,"bark_token",'Bark Token'); a.rmempty = true
a.description = "Bark Token<br>调用代码获取<a href='https://github.com/Finb/Bark' target='_blank'>点击这里</a><br><br>"
a=s:option( Flag,"bark_srv_enable","自建 Bark 服务器"); a.default=0; a.rmempty = true
a=s:option( Value,"bark_srv",'Bark Server'); a.rmempty = true
a.description = "Bark 自建服务器地址<br>如https://your.domain:port<br>具体自建服务器设定参见：<a href='https://github.com/Finb/Bark' target='_blank'>点击这里</a><br><br>"
a=s:option( Value,"bark_sound",'Bark Sound'); a.rmempty = true; a.default = "silence.caf"
a.description = "Bark 通知声音<br>如silence.caf<br>具体设定参见：<a href='https://github.com/Finb/Bark/tree/master/Sounds' target='_blank'>点击这里</a><br><br>"
a=s:option( Flag,"bark_icon_enable"," Bark 通知图标"); a.default=0; a.rmempty = true
a=s:option( Value,"bark_icon",'Bark Icon'); a.rmempty = true; a.default = "http://day.app/assets/images/avatar.jpg"
a.description = "Bark 通知图标(仅 iOS15 或以上支持)<br>如http://day.app/assets/images/avatar.jpg<br>具体设定参见：<a href='https://github.com/Finb/Bark#%E5%85%B6%E4%BB%96%E5%8F%82%E6%95%B0' target='_blank'>点击这里</a><br><br>"
a=s:option( Value,"bark_level",'Bark Level'); a.rmempty = true; a.default = "active"
a.description = "Bark 时效性通知<br>可选参数值：<br/>active：不设置时的默认值，系统会立即亮屏显示通知。<br/>timeSensitive：时效性通知，可在专注状态下显示通知。<br/>passive：仅将通知添加到通知列表，不会亮屏提醒。"

a=s:option( TextValue, "diy_json", "自定义推送")
a.optional = false; a.rows = 28; a.wrap = "soft"
a.cfgvalue = function(self, section)
    local data = fs.readfile("/usr/bin/pushbot/api/diy.json")
    return data or ""
end
a.write = function(self, section, value)
    if value == nil then return end
    if type(value) == "table" then value = value[#value] end
    if value and type(value) == "string" and value ~= "" then
        fs.writefile("/usr/bin/pushbot/api/diy.json", value:gsub("\r\n", "\n"))
    end
end

a=s:option( Button,"__add","发送测试")
a.inputtitle="发送"
function a.write(self, section)
	luci.sys.call("/usr/bin/pushbot/pushbot test &")
end

a=s:option( Value,"device_name",'本设备名称'); a.rmempty = true
a.description = "在推送信息标题中会标识本设备名称，用于区分推送信息的来源设备"
a=s:option( Value,"sleeptime",'检测时间间隔'); a.rmempty = true
a.optional = false; a.default = "60"; a.datatype = "and(uinteger,min(10))"
a.description = "越短的时间时间响应越及时，但会占用更多的系统资源"

a=s:option( ListValue,"oui_data","MAC设备信息数据库")
a.rmempty = true; a.default=""
a:value("","关闭"); a:value("1","简化版"); a:value("2","完整版"); a:value("3","网络查询")
a.description = "需下载 4.36m 原始数据，处理后完整版约 1.2M，简化版约 250kb <br/>若无梯子，请勿使用网络查询"

a=s:option( Flag,"oui_dir","下载到内存"); a.rmempty = true
a:depends("oui_data","1"); a:depends("oui_data","2")
a.description = "懒得做自动更新了，下载到内存中，重启会重新下载 <br/>若无梯子，还是下到机身吧"

a=s:option( Flag,"reset_regularly","每天零点重置流量数据"); a.rmempty = true
a=s:option( Flag,"debuglevel","开启日志"); a.rmempty = true
a = s:option( DynamicList, "device_aliases", "设备别名"); a.rmempty = true
a.description = "输入 MAC-别名，如 XX:XX:XX:XX:XX:XX-我的手机"

-- 免打扰 (needed by initDisturbCard)
a=s:option( ListValue,"pushbot_sheep","免打扰时段设置"); a.rmempty = true
a:value("","关闭"); a:value("1","模式一：脚本挂起"); a:value("2","模式二：静默模式")
a.description = "在指定整点时间段内，暂停推送消息<br/>免打扰时间中，定时推送也会被阻止。"

a=s:option( ListValue,"starttime","免打扰开始时间"); a.rmempty = true
for t=0,23 do a:value(t,"每天"..t.."点") end
a.default=0; a.datatype=uinteger
a:depends({pushbot_sheep="1"}); a:depends({pushbot_sheep="2"})

a=s:option( ListValue,"endtime","免打扰结束时间"); a.rmempty = true
for t=0,23 do a:value(t,"每天"..t.."点") end
a.default=8; a.datatype=uinteger
a:depends({pushbot_sheep="1"}); a:depends({pushbot_sheep="2"})

a=s:option( ListValue,"macmechanism","MAC过滤"); a.rmempty = true
a:value("","disable"); a:value("allow","忽略列表内设备")
a:value("block","仅通知列表内设备"); a:value("interface","仅通知此接口设备")

local _mac_write = a.write
a.write = function(self, section, value)
	_mac_write(self, section, value)
	local u = self.map.uci
	if value ~= "allow" then u:delete(self.config, section, "pushbot_whitelist") end
	if value ~= "block" then u:delete(self.config, section, "pushbot_blacklist") end
	if value ~= "interface" then u:delete(self.config, section, "pushbot_interface") end
end

a = s:option( DynamicList, "pushbot_whitelist", "忽略列表"); a.rmempty = true
a:depends({macmechanism="allow"})

a = s:option( DynamicList, "pushbot_blacklist", "关注列表"); a.rmempty = true
a:depends({macmechanism="block"})

a = s:option( Value, "pushbot_interface", "接口名称"); a.rmempty = true
-- No depends — Value type — disturb card builds dropdown from CT_IFACES

a=s:option( ListValue,"macmechanism2","MAC过滤2"); a.rmempty = true
a:value("","disable"); a:value("MAC_online","列表内任意设备在线时免打扰")
a:value("MAC_offline","列表内设备都离线后免打扰")

local _mac2_write = a.write
a.write = function(self, section, value)
	_mac2_write(self, section, value)
	local u = self.map.uci
	if value ~= "MAC_online" then u:delete(self.config, section, "MAC_online_list") end
	if value ~= "MAC_offline" then u:delete(self.config, section, "MAC_offline_list") end
end

a = s:option( DynamicList, "MAC_online_list", "在线免打扰列表"); a.rmempty = true
a:depends({macmechanism2="MAC_online"})

a = s:option( DynamicList, "MAC_offline_list", "任意离线免打扰列表"); a.rmempty = true
a:depends({macmechanism2="MAC_offline"})

-- 定时推送 (needed by initScheduledPushCard)
a=s:option( ListValue,"crontab","定时任务设定"); a.rmempty = true; a.default=""
a:value("","关闭"); a:value("1","定时发送"); a:value("2","间隔发送")

a=s:option( ListValue,"regular_time","发送时间"); a.rmempty = true
for t=0,23 do a:value(t,"每天"..t.."点") end
a.default=8; a.datatype=uinteger; a:depends("crontab","1")

a=s:option( ListValue,"regular_time_2","发送时间"); a.rmempty = true
a:value("","关闭")
for t=0,23 do a:value(t,"每天"..t.."点") end
a.default="关闭"; a.datatype=uinteger; a:depends("crontab","1")

a=s:option( ListValue,"regular_time_3","发送时间"); a.rmempty = true
a:value("","关闭")
for t=0,23 do a:value(t,"每天"..t.."点") end
a.default="关闭"; a.datatype=uinteger; a:depends("crontab","1")

a=s:option( ListValue,"interval_time","发送间隔"); a.rmempty = true
for t=1,23 do a:value(t,t.."小时") end
a.default=6; a.datatype=uinteger; a:depends("crontab","2")
a.description = "从 00:00 开始，每 * 小时发送一次"

a= s:option( Value, "send_title", "推送标题")
a:depends("crontab","1"); a:depends("crontab","2")
a.placeholder = "OpenWrt By tty228 路由状态："
a.description = "使用特殊符号可能会造成发送失败"

a=s:option( Flag,"router_status","系统运行情况"); a.default=1
a:depends("crontab","1"); a:depends("crontab","2")
a=s:option( Flag,"router_temp","设备温度"); a.default=1
a:depends("crontab","1"); a:depends("crontab","2")
a=s:option( Flag,"router_wan","WAN信息"); a.default=1
a:depends("crontab","1"); a:depends("crontab","2")
a=s:option( Flag,"client_list","客户端列表"); a.default=1
a:depends("crontab","1"); a:depends("crontab","2")

a=s:option( Value,"google_check_timeout","全球互联检测超时时间")
a.rmempty = true; a.optional = false; a.default = "10"
a.datatype = "and(uinteger,min(3))"
a.description = "过短的时间可能导致检测不准确"

e=s:option( Button,"_add","手动发送"); e.inputtitle="发送"
e:depends("crontab","1"); e:depends("crontab","2"); e.inputstyle = "apply"
function e.write(self, section)
luci.sys.call("cbi.apply")
        luci.sys.call("/usr/bin/pushbot/pushbot send &")
end

-- ═══ Content/Advanced/Client/Log — .render = function() end, no HTML rendering but form processing works ═══

-- 推送内容
a=s:option( Value,"pushbot_up",""); a.render = function() end; a.default=1; a.rmempty = true
a=s:option( Value,"pushbot_down",""); a.render = function() end; a.default=1; a.rmempty = true
a=s:option( Value,"cpuload_enable",""); a.render = function() end; a.default=1; a.rmempty = true
a= s:option( Value, "cpuload", ""); a.render = function() end; a.default = 2; a.rmempty = true

a=s:option( Value,"temperature_enable",""); a.render = function() end; a.default=1; a.rmempty = true
a.description = "请确认设备可以获取温度，如需修改命令，请移步高级设置"
a= s:option( Value, "temperature", ""); a.render = function() end; a.rmempty = true
a.default = "80"; a.datatype="uinteger"
a.description = "设备报警只会在连续五分钟超过设定值时才会推送<br/>而且一个小时内不会再提醒第二次"

a=s:option( Value,"client_usage",""); a.render = function() end; a.default=0; a.rmempty = true
a= s:option( Value, "client_usage_max", ""); a.render = function() end; a.default = "10M"; a.rmempty = true
a.description = "设备异常流量警报（byte），你可以追加 K 或者 M"

a=s:option( Value,"client_usage_disturb",""); a.render = function() end; a.default=1; a.rmempty = true

a = s:option( DynamicList, "client_usage_whitelist", ""); a.render = function() end; a.rmempty = true

a=s:option( ListValue,"pushbot_ipv4",""); a.render = function() end; a.rmempty = true; a.default=""
a:value("","关闭"); a:value("1","通过接口获取"); a:value("2","通过URL获取")

a = s:option( Value, "ipv4_interface", "接口名称"); a.rmempty = true

a=s:option( TextValue, "ipv4_list", ""); a.render = function() end; a.optional = false; a.rows = 8; a.wrap = "soft"
a.cfgvalue = function(self, section)
    local data = fs.readfile("/usr/bin/pushbot/api/ipv4.list")
    return data or ""
end
a.write = function(self, section, value)
    if value == nil then return end
    if type(value) == "table" then value = value[#value] end
    if value and type(value) == "string" and value ~= "" then
        fs.writefile("/usr/bin/pushbot/api/ipv4.list", value:gsub("\r\n", "\n"))
    end
end


a=s:option( ListValue,"pushbot_ipv6",""); a.render = function() end; a.rmempty = true; a.default="disable"
a:value("0","关闭"); a:value("1","通过接口获取"); a:value("2","通过URL获取")

a = s:option( Value, "ipv6_interface", "接口名称"); a.rmempty = true

a=s:option( TextValue, "ipv6_list", ""); a.render = function() end; a.optional = false; a.rows = 8; a.wrap = "soft"
a.cfgvalue = function(self, section)
    local data = fs.readfile("/usr/bin/pushbot/api/ipv6.list")
    return data or ""
end
a.write = function(self, section, value)
    if value == nil then return end
    if type(value) == "table" then value = value[#value] end
    if value and type(value) == "string" and value ~= "" then
        fs.writefile("/usr/bin/pushbot/api/ipv6.list", value:gsub("\r\n", "\n"))
    end
end


a=s:option( Value,"web_logged",""); a.render = function() end; a.default=0; a.rmempty = true
a=s:option( Value,"ssh_logged",""); a.render = function() end; a.default=0; a.rmempty = true
a=s:option( Value,"web_login_failed",""); a.render = function() end; a.default=0; a.rmempty = true
a=s:option( Value,"ssh_login_failed",""); a.render = function() end; a.default=0; a.rmempty = true
a= s:option( Value, "login_max_num", ""); a.render = function() end; a.default = "3"
a.datatype="and(uinteger,min(1))"
a.description = "超过次数后推送提醒"

a=s:option( Value,"web_login_black",""); a.render = function() end; a.default=0; a.rmempty = true
a.description = "直到重启前都不会重置次数，请先添加白名单"

a= s:option( Value, "ip_black_timeout", ""); a.render = function() end; a.default = "86400"
a.datatype="and(uinteger,min(0))"
a.description = "0 为永久拉黑，慎用<br>如不幸误操作，请更改设备 IP 进入 LUCI 界面清空规则"

a=s:option( DynamicList, "ip_white_list", ""); a.render = function() end; a.datatype = "ipaddr"; a.rmempty = true
a.description = "忽略白名单登陆提醒和拉黑操作，暂不支持掩码位表示"

a=s:option( TextValue, "ip_black_list", ""); a.render = function() end; a.optional = false; a.rows = 8; a.wrap = "soft"
a.description = "IP 黑名单列表"
a.cfgvalue = function(self, section)
    local data = fs.readfile("/usr/bin/pushbot/api/ip_blacklist")
    return data or ""
end
a.write = function(self, section, value)
    if value == nil then return end
    if type(value) == "table" then value = value[#value] end
    if value and type(value) == "string" and value ~= "" then
        fs.writefile("/usr/bin/pushbot/api/ip_blacklist", value:gsub("\r\n", "\n"))
    end
end

-- 高级设置
b=s:option( Value,"up_timeout",""); b.render = function() end; b.default = "2"
b.optional=false; b.datatype="uinteger"
b=s:option( Value,"down_timeout",""); b.render = function() end; b.default = "20"
b.optional=false; b.datatype="uinteger"
b=s:option( Value,"timeout_retry_count",""); b.render = function() end; b.default = "2"
b.optional=false; b.datatype="uinteger"
b.description = "若无二级路由设备，信号强度良好，可以减少以上数值<br/>因夜间 wifi 休眠较为玄学，遇到设备频繁推送断开，烦请自行调整参数<br/>..╮(╯_╰）╭.."
b=s:option( Value,"thread_num",""); b.render = function() end; b.default = "3"; b.datatype="uinteger"

b=s:option( Value, "soc_code", ""); b.render = function() end; b.rmempty = true
b:value("","默认"); b:value("pve","PVE 虚拟机")
b.description = "请尽量避免使用特殊符号，如双引号、$、!等，执行结果需为数字，用于温度对比"

b=s:option( Value,"pve_host",""); b.render = function() end; b.rmempty=true; b.default="10.0.0.2"
b.description = "请确认已经设置好密钥登陆，否则会引起脚本无法正常运行等错误！<br/>PVE 安装 sensors 命令自行百度<br/>密钥登陆例：<br/>opkg update #更新列表<br/>opkg install openssh-client openssh-keygen #安装openssh客户端<br/>ssh-keygen -t rsa # 生成密钥文件（自行设定密码等信息）<br/>ssh root@10.0.0.2 \"tee -a ~/.ssh/id_rsa.pub\" < ~/.ssh/id_rsa.pub # 传送公钥到 PVE<br/>ssh -i ~/.ssh/id_rsa root@10.0.0.2 sensors # 测试温度命令"
b=s:option( Value,"pve_port",""); b.render = function() end; b.rmempty=true; b.default="22"
b.description = "默认为22，如有自定义，请填写自定义SSH端口"

b=s:option( Value,"err_enable",""); b.render = function() end; b.default=0; b.rmempty=true
b.description = "请确认脚本可以正常运行，否则可能造成频繁重启等错误！"
b=s:option( Value,"err_sheep_enable",""); b.render = function() end; b.default=0; b.rmempty=true
b.description = "避免白天重拨 ddns 域名等待解析，此功能不影响断网检测<br/>因夜间跑流量问题，该功能可能不稳定"

b=s:option( DynamicList, "err_device_aliases", ""); b.render = function() end; b.rmempty = true
b.description = "只会在列表中设备都不在线时才会执行<br/>免打扰时段一小时后，关注设备五分钟低流量（约100kb/m）将视为离线"

b=s:option( ListValue,"network_err_event",""); b.render = function() end; b.default=""
b:value("","无操作"); b:value("1","重启路由器"); b:value("2","重新拨号")
b:value("3","修改相关设置项，尝试自动修复网络")
b.description = "选项 1 选项 2 不会修改设置，并最多尝试 2 次。<br/>选项 3 会将设置项备份于 /usr/bin/pushbot/configbak 目录，并在失败后还原。<br/>【！！无法保证兼容性！！】不熟悉系统设置项，不会救砖请勿使用"

b=s:option( ListValue,"system_time_event",""); b.render = function() end; b.default=""
b:value("","无操作"); b:value("1","重启路由器"); b:value("2","重新拨号")

b=s:option( Value, "autoreboot_time", ""); b.render = function() end; b.rmempty = true
b.default = "24"; b.datatype="uinteger"
b.description = "单位为小时"

b=s:option( Value, "network_restart_time", ""); b.render = function() end; b.rmempty = true
b.default = "24"; b.datatype="uinteger"
b.description = "单位为小时"

b=s:option( Value,"public_ip_event",""); b.render = function() end; b.default=0; b.rmempty=true
b.description = "重拨时不会推送 ip 变动通知，并会导致你的域名无法及时更新 ip 地址<br/>请确认你可以通过重拨获取公网 ip，否则这不仅徒劳无功还会引起频繁断网<br/>移动等大内网你就别挣扎了！！"

b=s:option( Value, "public_ip_retry_count", ""); b.render = function() end; b.rmempty = true
b.default = "10"; b.datatype="uinteger"

-- 在线设备 (DummyValue — reads on tab activation)
local client_val = s:option( DummyValue, "_client", ""); client_val.render = function() end
client_val.rawhtml = true
client_val.value = function(self, section)
	local out = luci.sys.exec("/usr/bin/pushbot/pushbot client 2>/dev/null || true")
	return '<pre style="white-space:pre-wrap;font-family:Menlo,Consolas,monospace;max-height:400px;overflow-y:auto;margin:4px 0">'
		.. luci.util.pcdata(out) .. '</pre>'
end

-- 日志
local log_val = s:option( DummyValue, "_log", ""); log_val.render = function() end
log_val.rawhtml = true
log_val.value = function(self, section)
	local uci_debug = require("luci.model.uci").cursor()
	local debug = uci_debug:get("pushbot", "pushbot", "debuglevel")
	if debug ~= "1" then
		return '<div style="padding:12px;color:#94a3b8;text-align:center">日志已关闭</div>'
	end
	local log = fs.readfile("/tmp/pushbot/pushbot.log") or ""
	return '<textarea class="cbi-input-textarea" style="width:100%;max-height:400px" rows="24" wrap="off" readonly>'
		.. luci.util.pcdata(log) .. '</textarea>'
end

return m
