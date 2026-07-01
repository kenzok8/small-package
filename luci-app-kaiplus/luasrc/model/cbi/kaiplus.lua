local m, s
local sys = require "luci.sys"

m = Map("kaiplus", translate("KaiPlus"), translate("KaiPlus is an AI workspace and session service."))
m:section(SimpleSection).template = "kaiplus/kaiplus_status"

m.on_after_commit = function(self)
	sys.call("/etc/init.d/kaiplus restart >/dev/null 2>&1 &")
end

s = m:section(TypedSection, "kaiplus", translate("Global settings"))
s.addremove = false
s.anonymous = true

s:option(Flag, "enabled", translate("Enable")).rmempty = false

local kaiplus_model = require "luci.model.kaiplus"
local blocks = kaiplus_model.blocks()
local home = kaiplus_model.home()

local data_dir = s:option(Value, "data_dir", translate("Data directory"))
data_dir.rmempty = false
data_dir.description = translate("Required. KaiPlus stores workspace, cache, config, and state under this directory.")

local paths, default_path = kaiplus_model.find_paths(blocks, home, "Configs")
for _, val in pairs(paths) do
	data_dir:value(val, val)
end
data_dir.default = default_path

local port = s:option(Value, "port", translate("Web port"))
port.default = "8198"
port.rmempty = false
port.datatype = "port"
port.description = translate("Port for the KaiPlus web service.")

return m
