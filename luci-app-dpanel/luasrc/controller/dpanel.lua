
module("luci.controller.dpanel", package.seeall)

function index()
  entry({"admin", "services", "dpanel"}, alias("admin", "services", "dpanel", "config"), _("DPanel"), 30).dependent = true
  entry({"admin", "services", "dpanel", "config"}, cbi("dpanel"))
end
