
module("luci.controller.demon", package.seeall)

function index()
  entry({"admin", "services", "demon"}, alias("admin", "services", "demon", "config"), _("Onething Demon"), 30).dependent = true
  entry({"admin", "services", "demon", "config"}, cbi("demon"))
end
