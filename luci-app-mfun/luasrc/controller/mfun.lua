
module("luci.controller.mfun", package.seeall)

function index()
  entry({"admin", "services", "mfun"}, alias("admin", "services", "mfun", "config"), _("Mfun"), 31).dependent = true
  entry({"admin", "services", "mfun", "config"}, cbi("mfun"))
end
