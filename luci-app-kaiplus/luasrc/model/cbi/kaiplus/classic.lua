local classic = require "luci.model.kaiplus.classic"
local sys = require "luci.sys"
local m

local description = translate("CLASSIC KAI can run alongside KaiPlus. Its settings and data are independent.")
if not classic.installed() then
	m = SimpleForm("classic_kai", translate("CLASSIC KAI"), description)
	m.submit = false
	m.reset = false
	m:section(SimpleSection).template = "kaiplus/classic_status"
	return m
end

m = Map("kai", translate("CLASSIC KAI"), description)
m:section(SimpleSection).template = "kaiplus/classic_status"

m.on_after_commit = function(self)
	local action = self.uci:get_first("kai", "kai", "enabled") == "1" and "restart" or "stop"
	if sys.call("/etc/init.d/kai " .. action .. " >/dev/null 2>&1") ~= 0 then
		self.message = translate("CLASSIC KAI could not apply the service settings. Check its configuration and system log.")
	end
end

local s = m:section(TypedSection, "kai", translate("Global settings"))
s.addremove = false
s.anonymous = true

local enabled = s:option(Flag, "enabled", translate("Enable"))
enabled.rmempty = false
enabled.description = translate("Save & Apply starts or stops CLASSIC KAI without restarting KaiPlus.")

local model = require "luci.model.kaiplus"
local paths, default_path = model.find_paths(model.blocks(), model.home(), "Configs", "KAI")
local data_dir = s:option(Value, "data_dir", translate("Data directory"))
data_dir.rmempty = false
data_dir.description = translate("Required. CLASSIC KAI stores its workspace, cache, config, and state here. Use a different directory from KaiPlus.")
for _, path in ipairs(paths) do
	data_dir:value(path, path)
end
data_dir.default = default_path

local port = s:option(Value, "port", translate("Access port"))
port.default = "8197"
port.rmempty = false
port.datatype = "port"
port.description = translate("CLASSIC KAI is available at http://router-address:port/apps/kai/web/. Use a different port from KaiPlus.")

return m
