local m, s

m = Map("dockermanager", translate("Docker Manager"), translate("Docker Manager provides a LinkEase Desktop web module and HTTP API for Docker management."))
m:section(SimpleSection).template = "dockermanager_status"

s = m:section(TypedSection, "dockermanager", translate("Global settings"))
s.addremove = false
s.anonymous = true

s:option(Flag, "enabled", translate("Enable")).rmempty = false

local data_dir = s:option(Value, "data_dir", translate("Data directory"))
data_dir.rmempty = false

local port = s:option(Value, "port", translate("Listen port"))
port.default = "8192"
port.rmempty = false
port.datatype = "port"

local bind_addr = s:option(Value, "bind_addr", translate("Bind address"))
bind_addr.default = "0.0.0.0"
bind_addr.rmempty = false

local base_path = s:option(Value, "base_path", translate("Base path"))
base_path.default = "/apps/dockermanager/"
base_path.rmempty = false

return m
