
module("luci.controller.openwebui", package.seeall)

function index()
  entry({"admin", "services", "openwebui"}, alias("admin", "services", "openwebui", "config"), _("OpenWebUI"), 30).dependent = true
  entry({"admin", "services", "openwebui", "config"}, cbi("openwebui"))
end
