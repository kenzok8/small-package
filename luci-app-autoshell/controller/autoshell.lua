module("luci.controller.autoshell", package.seeall)

function index()
    entry({"admin", "services", "webauto"}, alias("admin", "services", "webauto", "settings"), _("Web认证"), 99).index = true
    entry({"admin", "services", "webauto", "settings"}, cbi("autoshell"), _("认证设置"), 1)
    entry({"admin", "services", "webauto", "log"}, cbi("autoshell_log"), _("认证日志"), 2)
end
