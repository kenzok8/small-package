module("luci.controller.chongyoung", package.seeall)

function index()
    entry({"admin", "services", "chongyoung"}, alias("admin", "services", "chongyoung", "settings"), _("湖北飞young"), 100).index = true
    entry({"admin", "services", "chongyoung", "settings"}, cbi("chongyoung"), _("认证设置"), 1)
    entry({"admin", "services", "chongyoung", "passwd"}, cbi("chongyoung2"), _("密码管理"), 2)
    entry({"admin", "services", "chongyoung", "log"}, cbi("chongyoung_log"), _("认证日志"), 3)
end
