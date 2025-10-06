
module("luci.controller.istoredup", package.seeall)

function index()
  entry({"admin", "services", "istoredup"}, alias("admin", "services", "istoredup", "config"), _("iStoreDup"), 30).dependent = true
  entry({"admin", "services", "istoredup", "config"}, cbi("istoredup/config"), _("Config"), 10).leaf = true
  entry({"admin", "services", "istoredup", "tool"}, form("istoredup/tool"), _("Tool"), 30).leaf = true
  entry({"admin", "services", "istoredup", "console"}, form("istoredup/console"), _("Console"), 50).leaf = true
end
