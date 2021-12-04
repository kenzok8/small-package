m = Map("mosdns")

s = m:section(TypedSection, "mosdns")
s.addremove = false
s.anonymous = true

config = s:option(TextValue, "manual-config")
config.description = translate("View the YAML Configuration file used by this MosDNS. You can edit it as you own need; Beware the listening port 5335 was hardcoded into the init script, do not change that.")
config.template = "cbi/tvalue"
config.rows = 25

function config.cfgvalue(self, section)
  return nixio.fs.readfile("/etc/mosdns/config.yaml")
end

function config.write(self, section, value)
  value = value:gsub("\r\n?", "\n")
  nixio.fs.writefile("/etc/mosdns/config.yaml", value)
end

return m
