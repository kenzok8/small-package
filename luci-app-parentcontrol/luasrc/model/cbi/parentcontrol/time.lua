local o = require "luci.sys"
local fs = require "nixio.fs"
local ipc = require "luci.ip"
local net = require "luci.model.network".init()
local sys = require "luci.sys"
local a, t, e
a = Map("parentcontrol", translate("Parent Control"), translate("<b><font color=\"green\">利用iptables来管控数据包过滤以禁止符合设定条件的用户连接互联网的工具软件。</font> </b></br>\
时间限制:限制指定MAC地址机器是否联网.包括IPV4和IPV6</br>不指定MAC就是代表限制所有机器,星期用1-7表示，多个日期用自定义：1,5表示星期一和星期五" ))
a.template = "parentcontrol/index"

t = a:section(TypedSection, "basic", translate(""))
t.anonymous = true

e = t:option(DummyValue, "parentcontrol_status", translate("当前状态"))
e.template = "parentcontrol/parentcontrol"
e.value = translate("Collecting data...")

e = t:option(Flag, "enabled", translate("开启"))
e.rmempty = false

e = t:option(ListValue, "control_mode",translate("管控强度"), translate("普通管控：管控国内网站，出国插件的国外网站无法管控。强力管控：国内国外都可管控，注意：被管控的机器将无法连接上软路由后台！"))
e.rmempty = false
e:value("0", "普通管控")
e:value("1", "强力管控")
e.default = "0"

t = a:section(TypedSection, "time", translate("时间限制列表"))
t.template = "cbi/tblsection"
t.anonymous = true
t.addremove = true

e = t:option(Value, 'remarks', translate('Remarks'))

e = t:option(Flag, "enable", translate("开启"))
e.rmempty = false
e.default = '1'

e = t:option(Value, "mac", translate("MAC地址<font color=\"green\">(留空为全部客户端)</font>"))

e.rmempty = true
o.net.mac_hints(function(t, a) e:value(t, "%s (%s)" % {t, a}) end)

    function validate_time(self, value, section)
        local hh, mm, ss
        hh, mm, ss = string.match (value, "^(%d?%d):(%d%d)$")
        hh = tonumber (hh)
        mm = tonumber (mm)
        if hh and mm and hh <= 23 and mm <= 59 then
            return value
        else
            return nil, "时间格式必须为 HH:MM 或者留空"
        end
    end
    
e = t:option(Value, "timestart", translate("起控时间"))
e.placeholder = '00:00'
e.default = '00:00'
e.validate = validate_time
e.rmempty = true

e = t:option(Value, "timeend", translate("停控时间"))
e.placeholder = '00:00'
e.default = '00:00'
e.validate = validate_time
e.rmempty = true

week=t:option(Value,"week",translate("Week Day"))
week.rmempty = true
week:value('*',translate("Everyday"))
week:value(7,translate("Sunday"))
week:value(1,translate("Monday"))
week:value(2,translate("Tuesday"))
week:value(3,translate("Wednesday"))
week:value(4,translate("Thursday"))
week:value(5,translate("Friday"))
week:value(6,translate("Saturday"))
week.default='*'

return a



