
module("luci.controller.oneapi", package.seeall)

function index()
  entry({"admin", "services", "oneapi"}, alias("admin", "services", "oneapi", "config"), _("OneAPI"), 30).dependent = true
  entry({"admin", "services", "oneapi", "config"}, cbi("oneapi"))
end
