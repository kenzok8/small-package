module("luci.controller.chongyoung", package.seeall)

function index()
    entry({"admin", "school", "chongyoung"}, alias("admin", "school", "chongyoung", "settings"), _("飞young"), 100).index = true
    entry({"admin", "school", "chongyoung", "settings"}, cbi("chongyoung"), _("认证设置"), 1)
    entry({"admin", "school", "chongyoung", "passwd"}, cbi("chongyoung2"), _("密码管理"), 2)
    entry({"admin", "school", "chongyoung", "log"}, cbi("chongyoung_log"), _("认证日志"), 3)
end
