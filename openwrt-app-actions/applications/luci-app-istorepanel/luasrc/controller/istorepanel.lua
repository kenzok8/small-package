
module("luci.controller.istorepanel", package.seeall)

function index()
  entry({"admin", "services", "istorepanel"}, alias("admin", "services", "istorepanel", "config"), _("1Panel"), 30).dependent = true
  entry({"admin", "services", "istorepanel", "config"}, cbi("istorepanel"))
end
