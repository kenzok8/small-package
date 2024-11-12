
module("luci.controller.arcadia", package.seeall)

function index()
  entry({"admin", "services", "arcadia"}, alias("admin", "services", "arcadia", "config"), _("Arcadia"), 30).dependent = true
  entry({"admin", "services", "arcadia", "config"}, cbi("arcadia"))
end
