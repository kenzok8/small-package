local honk = require "luci.model.honk_tools"
local m, s, o

m = Map("honk", translate("Global Settings"), translate("Configure global settings for HONK."))

local config_file = "/etc/honk/config.dae"

s = honk.init_editor(m, "global")

s:option(Flag, "enabled", translate("Enabled")).rmempty = false

honk.add_editor(s, config_file, "globalconf", translate("Global Configuration"), translate("Correctly configure the include field for separate-config to work, or enter complete configuration here."))

return m

