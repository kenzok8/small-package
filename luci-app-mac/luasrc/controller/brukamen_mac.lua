module("luci.controller.brukamen_mac", package.seeall)

function index()
    entry({"admin", "services", "brukamen_mac"}, cbi("brukamen_mac"), _("MAC克隆"), 90)
    entry({"admin", "services", "ua2f"}, cbi("ua2f"), "防检测配置", 92)
    entry({"admin", "services", "Brukamen_WiFi"}, cbi("Brukamen_WiFi"), "WIFI设置", 93)
    --entry({"admin", "services", "webauto"}, alias("admin", "services", "webauto", "settings"), _("Web认证"), 99).index = true
    --entry({"admin", "services", "webauto", "settings"}, cbi("autoshell"), _("认证设置"), 1)
    --entry({"admin", "services", "webauto", "log"}, cbi("autoshell_log"), _("认证日志"), 2)
    entry({"admin", "services", "autoreboot"}, cbi("autoreboot"), _("定时重启"), 100)
end
