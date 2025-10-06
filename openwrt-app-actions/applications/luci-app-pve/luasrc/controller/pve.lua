
module("luci.controller.pve", package.seeall)

function index()
  entry({"admin", "services", "pve"}, alias("admin", "services", "pve", "config"), _("PVE"), 30).dependent = true
  entry({"admin", "services", "pve", "config"}, cbi("pve/config"), _("Config"), 10).leaf = true
  entry({"admin", "services", "pve", "tool"}, form("pve/tool"), _("Tool"), 30).leaf = true
end
