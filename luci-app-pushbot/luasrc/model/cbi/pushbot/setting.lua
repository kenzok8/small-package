
local nt = require "luci.sys".net
local fs=require"nixio.fs"
local e=luci.model.uci.cursor()
local net = require "luci.model.network".init()
local sys = require "luci.sys"
local ifaces = sys.net:devices()

m=Map("pushbot", "", "")

m:section(SimpleSection).template  = "pushbot/pushbot_status"

s=m:section(NamedSection,"pushbot","pushbot",translate(""))
s:tab("basic", translate("基本设置"))
s:tab("content", translate("推送内容"))
s:tab("crontab", translate("定时推送"))
s:tab("disturb", translate("免打扰"))
s:tab("advanced", translate("高级设置"))
s:tab("client", translate("在线设备"))
s:tab("log", translate("日志"))
s.addremove = false
s.anonymous = true

--基本设置
a=s:taboption("basic", Flag,"pushbot_enable",translate("启用"))
a.default=0
a.rmempty = true

--精简模式
a = s:taboption("basic", MultiValue, "lite_enable", translate("精简模式"))
a:value("device", translate("精简当前设备列表"))
a:value("nowtime", translate("精简当前时间"))
a:value("content", translate("只推送标题"))
a.widget = "checkbox"
a.default = nil
a.optional = true

--推送模式
a=s:taboption("basic", ListValue,"jsonpath",translate("推送模式"))
a.default="/usr/bin/pushbot/api/dingding.json"
a.rmempty = true
a:value("/usr/bin/pushbot/api/dingding.json",translate("钉钉"))
a:value("/usr/bin/pushbot/api/ent_wechat.json",translate("企业微信"))
a:value("/usr/bin/pushbot/api/feishu.json",translate("飞书"))
a:value("/usr/bin/pushbot/api/bark.json",translate("Bark"))
a:value("/usr/bin/pushbot/api/pushplus.json",translate("PushPlus"))
a:value("/usr/bin/pushbot/api/pushdeer.json",translate("PushDeer"))
a:value("/usr/bin/pushbot/api/diy.json",translate("自定义推送"))

a=s:taboption("basic", Value,"dd_webhook",translate('Webhook'), translate("钉钉机器人 Webhook").."，只输入access_token=后面的即可<br>调用代码获取<a href='https://developers.dingtalk.com/document/robots/custom-robot-access' target='_blank'>点击这里</a><br><br>")
a.rmempty = true
a:depends("jsonpath","/usr/bin/pushbot/api/dingding.json")

a=s:taboption("basic", Value, "we_webhook", translate("Webhook"),translate("企业微信机器人 Webhook").."，只输入key=后面的即可<br>调用代码获取<a href='https://work.weixin.qq.com/api/doc/90000/90136/91770' target='_blank'>点击这里</a><br><br>")
a.rmempty = true
a:depends("jsonpath","/usr/bin/pushbot/api/ent_wechat.json")

a=s:taboption("basic", Value,"pp_token",translate('PushPlus Token'), translate("PushPlus Token").."<br>调用代码获取<a href='http://pushplus.plus/doc/' target='_blank'>点击这里</a><br><br>")
a.rmempty = true
a:depends("jsonpath","/usr/bin/pushbot/api/pushplus.json")

a=s:taboption("basic", ListValue,"pp_channel",translate('PushPlus Channel'))
a.rmempty = true
a:depends("jsonpath","/usr/bin/pushbot/api/pushplus.json")
a:value("wechat",translate("wechat：PushPlus微信公众号"))
a:value("cp",translate("cp：企业微信应用"))
a:value("webhook",translate("webhook：第三方webhook"))
a:value("sms",translate("sms：短信"))
a:value("mail",translate("mail：邮箱"))
a.description = translate("第三方webhook：企业微信、钉钉、飞书、server酱<br>sms短信/mail邮箱：PushPlus暂未开放<br>具体channel设定参见：<a href='http://pushplus.plus/doc/extend/webhook.html' target='_blank'>点击这里</a>")

a=s:taboption("basic", Value,"pp_webhook",translate('PushPlus Custom Webhook'), translate("PushPlus 自定义Webhook").."<br>第三方webhook或企业微信调用<br>具体自定义Webhook设定参见：<a href='http://pushplus.plus/doc/extend/webhook.html' target='_blank'>点击这里</a><br><br>")
a.rmempty = true
a:depends("pp_channel","cp")
a:depends("pp_channel","webhook")

a=s:taboption("basic", Flag,"pp_topic_enable",translate("PushPlus 一对多推送"))
a.default=0
a.rmempty = true
a:depends("pp_channel","wechat")

a=s:taboption("basic", Value,"pp_topic",translate('PushPlus Topic'), translate("PushPlus 群组编码").."<br>一对多推送时指定的群组编码<br>具体群组编码Topic设定参见：<a href='http://www.pushplus.plus/push2.html' target='_blank'>点击这里</a><br><br>")
a.rmempty = true
a:depends("pp_topic_enable","1")

a=s:taboption("basic", Value,"pushdeer_key",translate('PushDeer Key'), translate("PushDeer Key").."<br>调用代码获取<a href='http://www.pushdeer.com/' target='_blank'>点击这里</a><br><br>")
a.rmempty = true
a:depends("jsonpath","/usr/bin/pushbot/api/pushdeer.json")

a=s:taboption("basic", Flag,"pushdeer_srv_enable",translate("自建 PushDeer 服务器"))
a.default=0
a.rmempty = true
a:depends("jsonpath","/usr/bin/pushbot/api/pushdeer.json")

a=s:taboption("basic", Value,"pushdeer_srv",translate('PushDeer Server'), translate("PushDeer 自建服务器地址").."<br>如https://your.domain:port<br>具体自建服务器设定参见：<a href='http://www.pushdeer.com/selfhosted.html' target='_blank'>点击这里</a><br><br>")
a.rmempty = true
a:depends("pushdeer_srv_enable","1")

a=s:taboption("basic", Value,"fs_webhook",translate('WebHook'), translate("飞书 WebHook").."<br>调用代码获取<a href='https://www.feishu.cn/hc/zh-CN/articles/360024984973' target='_blank'>点击这里</a><br><br>")
a.rmempty = true
a:depends("jsonpath","/usr/bin/pushbot/api/feishu.json")

a=s:taboption("basic", Value,"bark_token",translate('Bark Token'), translate("Bark Token").."<br>调用代码获取<a href='https://github.com/Finb/Bark' target='_blank'>点击这里</a><br><br>")
a.rmempty = true
a:depends("jsonpath","/usr/bin/pushbot/api/bark.json")

a=s:taboption("basic", Flag,"bark_srv_enable",translate("自建 Bark 服务器"))
a.default=0
a.rmempty = true
a:depends("jsonpath","/usr/bin/pushbot/api/bark.json")

a=s:taboption("basic", Value,"bark_srv",translate('Bark Server'), translate("Bark 自建服务器地址").."<br>如https://your.domain:port<br>具体自建服务器设定参见：<a href='https://github.com/Finb/Bark' target='_blank'>点击这里</a><br><br>")
a.rmempty = true
a:depends("bark_srv_enable","1")

a=s:taboption("basic", Value,"bark_sound",translate('Bark Sound'), translate("Bark 通知声音").."<br>如silence.caf<br>具体设定参见：<a href='https://github.com/Finb/Bark/tree/master/Sounds' target='_blank'>点击这里</a><br><br>")
a.rmempty = true
a.default = "silence.caf"
a:depends("jsonpath","/usr/bin/pushbot/api/bark.json")

a=s:taboption("basic", Flag,"bark_icon_enable",translate(" Bark 通知图标"))
a.default=0
a.rmempty = true
a:depends("jsonpath","/usr/bin/pushbot/api/bark.json")

a=s:taboption("basic", Value,"bark_icon",translate('Bark Icon'), translate("Bark 通知图标").."(仅 iOS15 或以上支持)<br>如http://day.app/assets/images/avatar.jpg<br>具体设定参见：<a href='https://github.com/Finb/Bark#%E5%85%B6%E4%BB%96%E5%8F%82%E6%95%B0' target='_blank'>点击这里</a><br><br>")
a.rmempty = true
a.default = "http://day.app/assets/images/avatar.jpg"
a:depends("bark_icon_enable","1")

a=s:taboption("basic", Value,"bark_level",translate('Bark Level'), translate("Bark 时效性通知").."<br>可选参数值：<br/>active：不设置时的默认值，系统会立即亮屏显示通知。<br/>timeSensitive：时效性通知，可在专注状态下显示通知。<br/>passive：仅将通知添加到通知列表，不会亮屏提醒。")
a.rmempty = true
a.default = "active"
a:depends("jsonpath","/usr/bin/pushbot/api/bark.json")

a=s:taboption("basic", TextValue, "diy_json", translate("自定义推送"))
a.optional = false
a.rows = 28
a.wrap = "soft"
a.cfgvalue = function(self, section)
    return fs.readfile("/usr/bin/pushbot/api/diy.json")
end
a.write = function(self, section, value)
    fs.writefile("/usr/bin/pushbot/api/diy.json", value:gsub("\r\n", "\n"))
end
a:depends("jsonpath","/usr/bin/pushbot/api/diy.json")

a=s:taboption("basic", Button,"__add",translate("发送测试"))
a.inputtitle=translate("发送")
a.inputstyle = "apply"
function a.write(self, section)
	luci.sys.call("cbi.apply")
	luci.sys.call("/usr/bin/pushbot/pushbot test &")
end

a=s:taboption("basic", Value,"device_name",translate('本设备名称'))
a.rmempty = true
a.description = translate("在推送信息标题中会标识本设备名称，用于区分推送信息的来源设备")

a=s:taboption("basic", Value,"sleeptime",translate('检测时间间隔'))
a.rmempty = true
a.optional = false
a.default = "60"
a.datatype = "and(uinteger,min(10))"
a.description = translate("越短的时间时间响应越及时，但会占用更多的系统资源")

a=s:taboption("basic", ListValue,"oui_data",translate("MAC设备信息数据库"))
a.rmempty = true
a.default=""
a:value("",translate("关闭"))
a:value("1",translate("简化版"))
a:value("2",translate("完整版"))
a:value("3",translate("网络查询"))
a.description = translate("需下载 4.36m 原始数据，处理后完整版约 1.2M，简化版约 250kb <br/>若无梯子，请勿使用网络查询")

a=s:taboption("basic", Flag,"oui_dir",translate("下载到内存"))
a.rmempty = true
a:depends("oui_data","1")
a:depends("oui_data","2")
a.description = translate("懒得做自动更新了，下载到内存中，重启会重新下载 <br/>若无梯子，还是下到机身吧")

a=s:taboption("basic", Flag,"reset_regularly",translate("每天零点重置流量数据"))
a.rmempty = true

a=s:taboption("basic", Flag,"debuglevel",translate("开启日志"))
a.rmempty = true

a= s:taboption("basic", DynamicList, "device_aliases", translate("设备别名"))
a.rmempty = true
a.description = translate("<br/> 请输入设备 MAC 和设备别名，用“-”隔开，如：<br/> XX:XX:XX:XX:XX:XX-我的手机")

--设备状态
a=s:taboption("content", ListValue,"pushbot_ipv4",translate("IPv4 变更通知"))
a.rmempty = true
a.default=""
a:value("",translate("关闭"))
a:value("1",translate("通过接口获取"))
a:value("2",translate("通过URL获取"))

a = s:taboption("content", ListValue, "ipv4_interface", translate("接口名称"))
a.rmempty = true
a:depends({pushbot_ipv4="1"})
for _, iface in ipairs(ifaces) do
	if not (iface == "lo" or iface:match("^ifb.*")) then
		local nets = net:get_interface(iface)
		nets = nets and nets:get_networks() or {}
		for k, v in pairs(nets) do
			nets[k] = nets[k].sid
		end
		nets = table.concat(nets, ",")
		a:value(iface, ((#nets > 0) and "%s (%s)" % {iface, nets} or iface))
	end
end
a.description = translate("<br/>一般选择 wan 接口，多拨环境请自行选择")

a=s:taboption("content", TextValue, "ipv4_list", translate("IPv4 API列表"))
a.optional = false
a.rows = 8
a.wrap = "soft"
a.cfgvalue = function(self, section)
    return fs.readfile("/usr/bin/pushbot/api/ipv4.list")
end
a.write = function(self, section, value)
    fs.writefile("/usr/bin/pushbot/api/ipv4.list", value:gsub("\r\n", "\n"))
end
a.description = translate("<br/>会因服务器稳定性、连接频繁等原因导致获取失败<br/>如接口可以正常获取 IP，不推荐使用<br/>从以上列表中随机地址访问")
a:depends({pushbot_ipv4="2"})

a=s:taboption("content", ListValue,"pushbot_ipv6",translate("IPv6 变更通知"))
a.rmempty = true
a.default="disable"
a:value("0",translate("关闭"))
a:value("1",translate("通过接口获取"))
a:value("2",translate("通过URL获取"))

a = s:taboption("content", ListValue, "ipv6_interface", translate("接口名称"))
a.rmempty = true
a:depends({pushbot_ipv6="1"})
for _, iface in ipairs(ifaces) do
	if not (iface == "lo" or iface:match("^ifb.*")) then
		local nets = net:get_interface(iface)
		nets = nets and nets:get_networks() or {}
		for k, v in pairs(nets) do
			nets[k] = nets[k].sid
		end
		nets = table.concat(nets, ",")
		a:value(iface, ((#nets > 0) and "%s (%s)" % {iface, nets} or iface))
	end
end
a.description = translate("<br/>一般选择 wan 接口，多拨环境请自行选择")

a=s:taboption("content", TextValue, "ipv6_list", translate("IPv6 API列表"))
a.optional = false
a.rows = 8
a.wrap = "soft"
a.cfgvalue = function(self, section)
    return fs.readfile("/usr/bin/pushbot/api/ipv6.list")
end
a.write = function(self, section, value)
    fs.writefile("/usr/bin/pushbot/api/ipv6.list", value:gsub("\r\n", "\n"))
end
a.description = translate("<br/>会因服务器稳定性、连接频繁等原因导致获取失败<br/>如接口可以正常获取 IP，不推荐使用<br/>从以上列表中随机地址访问")
a:depends({pushbot_ipv6="2"})

a=s:taboption("content", Flag,"pushbot_up",translate("设备上线通知"))
a.default=1
a.rmempty = true

a=s:taboption("content", Flag,"pushbot_down",translate("设备下线通知"))
a.default=1
a.rmempty = true

a=s:taboption("content", Flag,"cpuload_enable",translate("CPU 负载报警"))
a.default=1
a.rmempty = true

a= s:taboption("content", Value, "cpuload", "负载报警阈值")
a.default = 2
a.rmempty = true
a:depends({cpuload_enable="1"})

a=s:taboption("content", Flag,"temperature_enable",translate("CPU 温度报警"))
a.default=1
a.rmempty = true
a.description = translate("请确认设备可以获取温度，如需修改命令，请移步高级设置")

a= s:taboption("content", Value, "temperature", "温度报警阈值")
a.rmempty = true
a.default = "80"
a.datatype="uinteger"
a:depends({temperature_enable="1"})
a.description = translate("<br/>设备报警只会在连续五分钟超过设定值时才会推送<br/>而且一个小时内不会再提醒第二次")

a=s:taboption("content", Flag,"client_usage",translate("设备异常流量"))
a.default=0
a.rmempty = true

a= s:taboption("content", Value, "client_usage_max", "每分钟流量限制")
a.default = "10M"
a.rmempty = true
a:depends({client_usage="1"})
a.description = translate("设备异常流量警报（byte），你可以追加 K 或者 M")

a=s:taboption("content", Flag,"client_usage_disturb",translate("异常流量免打扰"))
a.default=1
a.rmempty = true
a:depends({client_usage="1"})

a = s:taboption("content", DynamicList, "client_usage_whitelist", translate("异常流量关注列表"))
nt.mac_hints(function(mac, name) a:value(mac, "%s (%s)" %{ mac, name }) end)
a.rmempty = true
a:depends({client_usage_disturb="1"})
a.description = translate("请输入设备 MAC")

--LoginNoti
a=s:taboption("content", Flag,"web_logged",translate("Web 登录提醒"))
a.default=0
a.rmempty = true

a=s:taboption("content", Flag,"ssh_logged",translate("SSH 登录提醒"))
a.default=0
a.rmempty = true

a=s:taboption("content", Flag,"web_login_failed",translate("Web 错误尝试提醒"))
a.default=0
a.rmempty = true

a=s:taboption("content", Flag,"ssh_login_failed",translate("SSH 错误尝试提醒"))
a.default=0
a.rmempty = true

a= s:taboption("content", Value, "login_max_num", "错误尝试次数")
a.default = "3"
a.datatype="and(uinteger,min(1))"
a:depends("web_login_failed","1")
a:depends("ssh_login_failed","1")
a.description = translate("超过次数后推送提醒")

a=s:taboption("content", Flag,"web_login_black",translate("自动拉黑"))
a.default=0
a.rmempty = true
a:depends("web_login_failed","1")
a:depends("ssh_login_failed","1")
a.description = translate("直到重启前都不会重置次数，请先添加白名单")

a= s:taboption("content", Value, "ip_black_timeout", "拉黑时间(秒)")
a.default = "86400"
a.datatype="and(uinteger,min(0))"
a:depends("web_login_black","1")
a.description = translate("0 为永久拉黑，慎用<br>如不幸误操作，请更改设备 IP 进入 LUCI 界面清空规则")

a=s:taboption("content", DynamicList, "ip_white_list", translate("白名单 IP 列表"))
a.datatype = "ipaddr"
a.rmempty = true
luci.ip.neighbors({family = 4}, function(entry)
	if entry.reachable then
		a:value(entry.dest:string())
	end
end)
a:depends("web_logged","1")
a:depends("ssh_logged","1")
a:depends("web_login_failed","1")
a:depends("ssh_login_failed","1")
a.description = translate("忽略白名单登陆提醒和拉黑操作，暂不支持掩码位表示")

a=s:taboption("content", TextValue, "ip_black_list", translate("IP 黑名单列表"))
a.optional = false
a.rows = 8
a.wrap = "soft"
a.cfgvalue = function(self, section)
    return fs.readfile("/usr/bin/pushbot/api/ip_blacklist")
end
a.write = function(self, section, value)
    fs.writefile("/usr/bin/pushbot/api/ip_blacklist", value:gsub("\r\n", "\n"))
end
a:depends("web_login_black","1")

--定时推送
a=s:taboption("crontab", ListValue,"crontab",translate("定时任务设定"))
a.rmempty = true
a.default=""
a:value("",translate("关闭"))
a:value("1",translate("定时发送"))
a:value("2",translate("间隔发送"))

a=s:taboption("crontab", ListValue,"regular_time",translate("发送时间"))
a.rmempty = true
for t=0,23 do
a:value(t,translate("每天"..t.."点"))
end
a.default=8
a.datatype=uinteger
a:depends("crontab","1")

a=s:taboption("crontab", ListValue,"regular_time_2",translate("发送时间"))
a.rmempty = true
a:value("",translate("关闭"))
for t=0,23 do
a:value(t,translate("每天"..t.."点"))
end
a.default="关闭"
a.datatype=uinteger
a:depends("crontab","1")

a=s:taboption("crontab", ListValue,"regular_time_3",translate("发送时间"))
a.rmempty = true

a:value("",translate("关闭"))
for t=0,23 do
a:value(t,translate("每天"..t.."点"))
end
a.default="关闭"
a.datatype=uinteger
a:depends("crontab","1")

a=s:taboption("crontab", ListValue,"interval_time",translate("发送间隔"))
a.rmempty = true
for t=1,23 do
a:value(t,translate(t.."小时"))
end
a.default=6
a.datatype=uinteger
a:depends("crontab","2")
a.description = translate("<br/>从 00:00 开始，每 * 小时发送一次")

a= s:taboption("crontab", Value, "send_title", translate("推送标题"))
a:depends("crontab","1")
a:depends("crontab","2")
a.placeholder = "OpenWrt By tty228 路由状态："
a.description = translate("<br/>使用特殊符号可能会造成发送失败")

a=s:taboption("crontab", Flag,"router_status",translate("系统运行情况"))
a.default=1
a:depends("crontab","1")
a:depends("crontab","2")

a=s:taboption("crontab", Flag,"router_temp",translate("设备温度"))
a.default=1
a:depends("crontab","1")
a:depends("crontab","2")

a=s:taboption("crontab", Flag,"router_wan",translate("WAN信息"))
a.default=1
a:depends("crontab","1")
a:depends("crontab","2")

a=s:taboption("crontab", Flag,"client_list",translate("客户端列表"))
a.default=1
a:depends("crontab","1")
a:depends("crontab","2")

a=s:taboption("crontab", Value,"google_check_timeout",translate("全球互联检测超时时间"))
a.rmempty = true
a.optional = false
a.default = "10"
a.datatype = "and(uinteger,min(3))"
a.description = translate("过短的时间可能导致检测不准确")

e=s:taboption("crontab", Button,"_add",translate("手动发送"))
e.inputtitle=translate("发送")
e:depends("crontab","1")
e:depends("crontab","2")
e.inputstyle = "apply"
function e.write(self, section)
luci.sys.call("cbi.apply")
        luci.sys.call("/usr/bin/pushbot/pushbot send &")
end

--免打扰
a=s:taboption("disturb", ListValue,"pushbot_sheep",translate("免打扰时段设置"),translate("在指定整点时间段内，暂停推送消息<br/>免打扰时间中，定时推送也会被阻止。"))
a.rmempty = true

a:value("",translate("关闭"))
a:value("1",translate("模式一：脚本挂起"))
a:value("2",translate("模式二：静默模式"))
a.description = translate("模式一停止一切检测，包括无人值守。")
a=s:taboption("disturb", ListValue,"starttime",translate("免打扰开始时间"))
a.rmempty = true

for t=0,23 do
a:value(t,translate("每天"..t.."点"))
end
a.default=0
a.datatype=uinteger
a:depends({pushbot_sheep="1"})
a:depends({pushbot_sheep="2"})
a=s:taboption("disturb", ListValue,"endtime",translate("免打扰结束时间"))
a.rmempty = true

for t=0,23 do
a:value(t,translate("每天"..t.."点"))
end
a.default=8
a.datatype=uinteger
a:depends({pushbot_sheep="1"})
a:depends({pushbot_sheep="2"})

a=s:taboption("disturb", ListValue,"macmechanism",translate("MAC过滤"))
a:value("",translate("disable"))
a:value("allow",translate("忽略列表内设备"))
a:value("block",translate("仅通知列表内设备"))
a:value("interface",translate("仅通知此接口设备"))
a.rmempty = true


a = s:taboption("disturb", DynamicList, "pushbot_whitelist", translate("忽略列表"))
nt.mac_hints(function(mac, name) a :value(mac, "%s (%s)" %{ mac, name }) end)
a.rmempty = true
a:depends({macmechanism="allow"})
a.description = translate("AA:AA:AA:AA:AA:AA\\|BB:BB:BB:BB:BB:B 可以将多个 MAC 视为同一用户<br/>任一设备在线后不再推送，设备全部离线时才会推送，避免双 wifi 频繁推送")

a = s:taboption("disturb", DynamicList, "pushbot_blacklist", translate("关注列表"))
nt.mac_hints(function(mac, name) a:value(mac, "%s (%s)" %{ mac, name }) end)
a.rmempty = true
a:depends({macmechanism="block"})
a.description = translate("AA:AA:AA:AA:AA:AA\\|BB:BB:BB:BB:BB:B 可以将多个 MAC 视为同一用户<br/>任一设备在线后不再推送，设备全部离线时才会推送，避免双 wifi 频繁推送")

a = s:taboption("disturb", ListValue, "pushbot_interface", translate("接口名称"))
a:depends({macmechanism="interface"})
a.rmempty = true

for _, iface in ipairs(ifaces) do
	if not (iface == "lo" or iface:match("^ifb.*")) then
		local nets = net:get_interface(iface)
		nets = nets and nets:get_networks() or {}
		for k, v in pairs(nets) do
			nets[k] = nets[k].sid
		end
		nets = table.concat(nets, ",")
		a:value(iface, ((#nets > 0) and "%s (%s)" % {iface, nets} or iface))
	end
end

a=s:taboption("disturb", ListValue,"macmechanism2",translate("MAC过滤2"))
a:value("",translate("disable"))
a:value("MAC_online",translate("列表内任意设备在线时免打扰"))
a:value("MAC_offline",translate("列表内设备都离线后免打扰"))
a.rmempty = true

a = s:taboption("disturb", DynamicList, "MAC_online_list", translate("在线免打扰列表"))
nt.mac_hints(function(mac, name) a:value(mac, "%s (%s)" %{ mac, name }) end)
a.rmempty = true
a:depends({macmechanism2="MAC_online"})

a = s:taboption("disturb", DynamicList, "MAC_offline_list", translate("任意离线免打扰列表"))
nt.mac_hints(function(mac, name) a:value(mac, "%s (%s)" %{ mac, name }) end)
a.rmempty = true
a:depends({macmechanism2="MAC_offline"})

-- 高级设置

b=s:taboption("advanced", Value,"up_timeout",translate('设备上线检测超时（s）'))
b.default = "2"
b.optional=false
b.datatype="uinteger"

b=s:taboption("advanced", Value,"down_timeout",translate('设备离线检测超时（s）'))
b.default = "20"
b.optional=false
b.datatype="uinteger"

b=s:taboption("advanced", Value,"timeout_retry_count",translate('离线检测次数'))
b.default = "2"
b.optional=false
b.datatype="uinteger"
b.description = translate("若无二级路由设备，信号强度良好，可以减少以上数值<br/>因夜间 wifi 休眠较为玄学，遇到设备频繁推送断开，烦请自行调整参数<br/>..╮(╯_╰）╭..")

b=s:taboption("advanced", Value,"thread_num",translate('最大并发进程数'))
b.default = "3"
b.datatype="uinteger"

b=s:taboption("advanced", Value, "soc_code", "自定义温度读取命令")
b.rmempty = true 
b:value("",translate("默认"))
b:value("pve",translate("PVE 虚拟机"))
b.description = translate("请尽量避免使用特殊符号，如双引号、$、!等，执行结果需为数字，用于温度对比")

b=s:taboption("advanced", Value,"pve_host",translate("宿主机地址"))
b.rmempty=true
b.default="10.0.0.2"
b.description = translate("请确认已经设置好密钥登陆，否则会引起脚本无法正常运行等错误！<br/>PVE 安装 sensors 命令自行百度<br/>密钥登陆例：<br/>opkg update #更新列表<br/>opkg install openssh-client openssh-keygen #安装openssh客户端<br/>ssh-keygen -t rsa # 生成密钥文件（自行设定密码等信息）<br/>ssh root@10.0.0.2 \"tee -a ~/.ssh/id_rsa.pub\" < ~/.ssh/id_rsa.pub # 传送公钥到 PVE<br/>ssh -i ~/.ssh/id_rsa root@10.0.0.2 sensors # 测试温度命令")
b:depends({soc_code="pve"})

b=s:taboption("advanced", Value,"pve_port",translate("SSH端口"))
b.rmempty=true
b.default="22"
b.description = translate("默认为22，如有自定义，请填写自定义SSH端口")
b:depends({soc_code="pve"})

b=s:taboption("advanced", Button,"soc",translate("测试温度命令"))
b.inputtitle = translate("输出信息")
b.write = function()
	luci.sys.call("/usr/bin/pushbot/pushbot soc")
	luci.http.redirect(luci.dispatcher.build_url("admin","services","pushbot","setting"))
end

if nixio.fs.access("/tmp/pushbot/soc_tmp") then
	e=s:taboption("advanced", TextValue,"soc_tmp")
	e.rows=2
	e.readonly=true
	e.cfgvalue = function()
		return luci.sys.exec("cat /tmp/pushbot/soc_tmp && rm -f /tmp/pushbot/soc_tmp")
	end
end

b=s:taboption("advanced", Flag,"err_enable",translate("无人值守任务"))
b.default=0
b.rmempty=true
b.description = translate("请确认脚本可以正常运行，否则可能造成频繁重启等错误！")

b=s:taboption("advanced", Flag,"err_sheep_enable",translate("仅在免打扰时段重拨"))
b.default=0
b.rmempty=true
b.description = translate("避免白天重拨 ddns 域名等待解析，此功能不影响断网检测<br/>因夜间跑流量问题，该功能可能不稳定")
b:depends({err_enable="1"})

b=s:taboption("advanced", DynamicList, "err_device_aliases", translate("关注列表"))
b.rmempty = true 
b.description = translate("只会在列表中设备都不在线时才会执行<br/>免打扰时段一小时后，关注设备五分钟低流量（约100kb/m）将视为离线")
nt.mac_hints(function(mac, name) b :value(mac, "%s (%s)" %{ mac, name }) end)
b:depends({err_enable="1"})

b=s:taboption("advanced", ListValue,"network_err_event",translate("网络断开时"))
b.default=""
b:depends({err_enable="1"})
b:value("",translate("无操作"))
b:value("1",translate("重启路由器"))
b:value("2",translate("重新拨号"))
b:value("3",translate("修改相关设置项，尝试自动修复网络"))
b.description = translate("选项 1 选项 2 不会修改设置，并最多尝试 2 次。<br/>选项 3 会将设置项备份于 /usr/bin/pushbot/configbak 目录，并在失败后还原。<br/>【！！无法保证兼容性！！】不熟悉系统设置项，不会救砖请勿使用")

b=s:taboption("advanced", ListValue,"system_time_event",translate("定时重启"))
b.default=""
b:depends({err_enable="1"})
b:value("",translate("无操作"))
b:value("1",translate("重启路由器"))
b:value("2",translate("重新拨号"))

b=s:taboption("advanced", Value, "autoreboot_time", "系统运行时间大于")
b.rmempty = true 
b.default = "24"
b.datatype="uinteger"
b:depends({system_time_event="1"})
b.description = translate("单位为小时")

b=s:taboption("advanced", Value, "network_restart_time", "网络在线时间大于")
b.rmempty = true 
b.default = "24"
b.datatype="uinteger"
b:depends({system_time_event="2"})
b.description = translate("单位为小时")

b=s:taboption("advanced", Flag,"public_ip_event",translate("重拨尝试获取公网 ip"))
b.default=0
b.rmempty=true
b:depends({err_enable="1"})
b.description = translate("重拨时不会推送 ip 变动通知，并会导致你的域名无法及时更新 ip 地址<br/>请确认你可以通过重拨获取公网 ip，否则这不仅徒劳无功还会引起频繁断网<br/>移动等大内网你就别挣扎了！！")

b=s:taboption("advanced", Value, "public_ip_retry_count", "当天最大重试次数")
b.rmempty = true 
b.default = "10"
b.datatype="uinteger"
b:depends({public_ip_event="1"})

-- 在线设备
local client_val = s:taboption("client", TextValue, "pushbot_client", translate("在线设备输出"))
client_val.rows = 20
client_val.wrap = "off"
client_val.readonly = true
client_val.rmempty = true
client_val.cfgvalue = function(self, section)
	return sys.exec("/usr/bin/pushbot/pushbot client")
end

-- 日志
local log_val = s:taboption("log", TextValue, "pushbot_log", translate("日志输出"))
log_val.rows = 20
log_val.wrap = "off"
log_val.readonly = true
log_val.rmempty = true
log_val.cfgvalue = function(self, section)
	return fs.readfile("/tmp/pushbot/pushbot.log") or ""
end

return m
