local m, s
local uci = luci.model.uci.cursor()
local sys = require 'luci.sys'


-- s = m:section(TypedSection, 'MySection', translate('基本设置'))
-- s.anonymous = true
-- o = s:option(DummyValue, '', '')
-- o.rawhtml = true
-- o.version = sys.exec('uci get jd-dailybonus.@global[0].version')
-- o.template = 'xunyou/service'
m = Map("xunyou", translate("迅游"), translate("迅游是一款小巧且功能强大的网游加速器，迅游所采用的第五代网游加速技术能更有效地为您解决网游卡机、掉线、延时高、登录难等问题")
.. translatef("For further information "
.. "<a href=\"%s\" target=\"_blank\">"
.. "访问官网</a>", "https://www.xunyou.com/"))

m:section(SimpleSection).template  = "xunyou/xunyou"


s=m:section(TypedSection, "xunyou", translate("Global settings"))
s.addremove=false
s.anonymous=true
s:option(Flag, "enabled", translate("Enable")).rmempty=false

-- s=m:section(TypedSection, "linkease", translate("Global settings"))
-- s.anonymous=true

-- s:option(Flag, "enabled", translate("Enable")).rmempty=false

-- s:option(Value, "port", translate("Port")).rmempty=false
return m