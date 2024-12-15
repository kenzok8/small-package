
module("luci.controller.ubuntu2", package.seeall)

function index()
  entry({"admin", "services", "ubuntu2"}, alias("admin", "services", "ubuntu2", "config"), _("Ubuntu2"), 30).dependent = true
  entry({"admin", "services", "ubuntu2", "config"}, cbi("ubuntu2"))
end
