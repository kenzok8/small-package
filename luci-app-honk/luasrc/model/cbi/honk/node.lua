local honk = require "luci.model.honk_tools"
local m, s

m = Map("honk", translate("Node Settings"), translate("Configure nodes and groups for HONK."))

local node_file = "/etc/honk/config.d/node.dae"

s = honk.init_editor(m, "node")
honk.add_editor(s, node_file, "nodeconf", translate("Node Configuration"))

return m

