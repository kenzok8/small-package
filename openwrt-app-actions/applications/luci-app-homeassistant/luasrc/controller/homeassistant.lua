
module("luci.controller.homeassistant", package.seeall)

function index()
  entry({"admin", "services", "homeassistant"}, alias("admin", "services", "homeassistant", "config"), _("Home Assistant"), 30).dependent = true
  entry({"admin", "services", "homeassistant", "config"}, cbi("homeassistant"))
end
