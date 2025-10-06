
module("luci.controller.uptimekuma", package.seeall)

function index()
  entry({"admin", "services", "uptimekuma"}, alias("admin", "services", "uptimekuma", "config"), _("UptimeKuma"), 30).dependent = true
  entry({"admin", "services", "uptimekuma", "config"}, cbi("uptimekuma"))
end
