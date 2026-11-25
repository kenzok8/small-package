local m, s

m = Map("agentflow", translate("AgentFlow"), translate("AgentFlow orchestrates projects and independently installed coding agents."))
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

function data_dir.validate(self, value, section)
	value = (value or ""):match("^%s*(.-)%s*$")
	if value == "" or value == "/" then
		return nil, translate("Data directory cannot be empty.")
	end
	if not value:match("^/mnt/[^/]+/") then
		return nil, translate("Please select a disk as the data directory.")
	end
	return value
end

local paths, default_path = agentflow_model.find_paths(blocks, home)
for _, val in pairs(paths) do
	data_dir:value(val, val)
end
data_dir.default = default_path

local home_dir = s:option(Value, "home_dir", translate("AgentFlow home directory"))
home_dir.rmempty = true
home_dir.description = translate("Optional. New installations use <data directory>/home. An upgraded installation may retain its previous HOME so credentials are not moved silently.")

function home_dir.validate(self, value, section)
	value = (value or ""):match("^%s*(.-)%s*$")
	if value == "" then
		return value
	end
	if not value:match("^/mnt/[^/]+/") or value:find("//", 1, true) or value:match("/%.%.?/") then
		return nil, translate("Please select a disk as the home directory.")
	end
	return value:gsub("/+$", "")
end

return m
