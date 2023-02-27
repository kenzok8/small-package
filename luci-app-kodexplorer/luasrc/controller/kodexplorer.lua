
module("luci.controller.kodexplorer", package.seeall)

function index()
  entry({"admin", "services", "kodexplorer"}, alias("admin", "services", "kodexplorer", "config"), _("KodExplorer"), 30).dependent = true
  entry({"admin", "services", "kodexplorer", "config"}, cbi("kodexplorer"))
end
