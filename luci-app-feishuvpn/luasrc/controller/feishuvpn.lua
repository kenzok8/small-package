
module("luci.controller.feishuvpn", package.seeall)

function index()
  entry({"admin", "services", "feishuvpn"}, alias("admin", "services", "feishuvpn", "config"), _("FeiShuVpn"), 30).dependent = true
  entry({"admin", "services", "feishuvpn", "config"}, cbi("feishuvpn"))
end
