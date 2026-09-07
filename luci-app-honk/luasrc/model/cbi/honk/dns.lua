local honk = require "luci.model.honk_tools"
local m, s

m = Map("honk", translate("DNS Settings"), translate("Configure DNS settings for HONK."))

local dns_file = "/etc/honk/config.d/dns.dae"

s = honk.init_editor(m, "dns")
honk.add_editor(s, dns_file, "dnsconf", translate("DNS Configuration"))

return m

