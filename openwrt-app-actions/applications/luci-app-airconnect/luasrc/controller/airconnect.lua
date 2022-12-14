
module("luci.controller.airconnect", package.seeall)

function index()
  entry({"admin", "services", "airconnect"}, alias("admin", "services", "airconnect", "config"), _("AirConnect"), 90).dependent = true
  entry({"admin", "services", "airconnect", "config"}, cbi("airconnect"))
end
