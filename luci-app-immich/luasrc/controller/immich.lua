
module("luci.controller.immich", package.seeall)

function index()
  entry({"admin", "services", "immich"}, alias("admin", "services", "immich", "config"), _("Immich"), 30).dependent = true
  entry({"admin", "services", "immich", "config"}, cbi("immich"))
end
