-- Copyright 2020 BlackYau <blackyau426@gmail.com>
-- GNU General Public License v3.0


module("luci.controller.suselogin", package.seeall)

function index()
        entry({"admin", "services", "suselogin"},firstchild(), _("川轻化web"), 100).dependent = false
        entry({"admin", "services", "suselogin", "general"}, cbi("suselogin"), _("配置"), 1)
        entry({"admin", "services", "suselogin", "log"}, form("suseloginlog"), _("运行日志"), 2)
end
