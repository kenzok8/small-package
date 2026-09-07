local honk = require "luci.model.honk_tools"
local m, s

m = Map("honk", translate("Routing Settings"), translate("Configure routing rules for HONK."))

local route_file = "/etc/honk/config.d/route.dae"

s = honk.init_editor(m, "route")
honk.add_editor(s, route_file, "routeconf", translate("Route Configuration"))

return m

