module("luci.controller.agent2api", package.seeall)

function index()
  entry({"admin", "services", "agent2api"},
        alias("admin", "services", "agent2api", "config"), _("Agent2API"), 30).dependent = true
  entry({"admin", "services", "agent2api", "config"}, cbi("agent2api"))
end
