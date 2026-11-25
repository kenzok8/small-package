local m, s

m = Map("dockermanager", translate("Docker Manager"), translate("Docker Manager provides a LinkEase Desktop web module and HTTP API for Docker management."))
m:section(SimpleSection).template = "dockermanager_status"

s = m:section(TypedSection, "dockermanager", translate("Global settings"))
s.addremove = false
s.anonymous = true

s:option(Flag, "enabled", translate("Enable")).rmempty = false

local data_dir = s:option(Value, "data_dir", translate("Data directory"))
data_dir.rmempty = false

local socket_path = s:option(Value, "socket_path", translate("Unix socket path"))
socket_path.default = "/var/run/dockermanager.sock"
socket_path.rmempty = false
socket_path.readonly = true

local base_path = s:option(Value, "base_path", translate("Base path"))
base_path.default = "/apps/dockermanager/"
base_path.rmempty = false
base_path.readonly = true

return m
