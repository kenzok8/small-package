local m, s

m = Map("agentflow", translate("AgentFlow"), translate("AgentFlow provides a Web UI for orchestrating coding agents and workflows."))
m:section(SimpleSection).template = "agentflow/status"

s = m:section(TypedSection, "agentflow", translate("Global settings"))
s.addremove = false
s.anonymous = true

s:option(Flag, "enabled", translate("Enable")).rmempty = false

local agentflow_model = require "luci.model.agentflow"
local blocks = agentflow_model.blocks()
local home = agentflow_model.home()

local data_dir = s:option(Value, "data_dir", translate("Data directory"))
data_dir.rmempty = false
data_dir.description = translate("Required. AgentFlow stores its configuration, database and workspace data under this directory.")

local paths, default_path = agentflow_model.find_paths(blocks, home)
for _, val in pairs(paths) do
	data_dir:value(val, val)
end
data_dir.default = default_path

local port = s:option(Value, "port", translate("Listen port"))
port.default = "9000"
port.rmempty = false
port.datatype = "port"
port.description = translate("Port for the AgentFlow HTTP server.")

return m
