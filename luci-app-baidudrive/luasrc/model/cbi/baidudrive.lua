local m, s

m = Map("baidudrive", translate("BaiduDrive"), translate("BaiduDrive provides a Baidu Netdisk Web UI."))
m:section(SimpleSection).template = "baidudrive/baidudrive_status"

s = m:section(TypedSection, "baidudrive", translate("Global settings"))
s.addremove = false
s.anonymous = true

s:option(Flag, "enabled", translate("Enable")).rmempty = false

local baidudrive_model = require "luci.model.baidudrive"
local blocks = baidudrive_model.blocks()
local home = baidudrive_model.home()

local data_dir = s:option(Value, "data_dir", translate("Data directory"))
data_dir.rmempty = false
data_dir.description = translate("Required. BaiduDrive stores its config, session and task data under this directory.")

local paths, default_path = baidudrive_model.find_paths(blocks, home, "Configs")
for _, val in pairs(paths) do
	data_dir:value(val, val)
end
data_dir.default = default_path

local port = s:option(Value, "port", translate("Listen port"))
port.default = "8080"
port.rmempty = false
port.datatype = "port"
port.description = translate("Port for BaiduDrive HTTP server.")

return m
