local m, s

m = Map("dockermanager", translate("Docker Manager"), translate("Docker Manager provides a LinkEase Desktop web module and HTTP API for Docker management."))
m:section(SimpleSection).template = "dockermanager_status"

s = m:section(TypedSection, "dockermanager", translate("Global settings"))
s.addremove = false
s.anonymous = true

s:option(Flag, "enabled", translate("Enable")).rmempty = false

local data_dir = s:option(Value, "data_dir", translate("Data directory"))
data_dir.rmempty = false

local listen_mode = s:option(ListValue, "listen_mode", translate("Listen mode"))
listen_mode:value("auto", translate("Auto"))
listen_mode:value("unix", translate("Unix socket"))
listen_mode:value("tcp", translate("TCP port"))
listen_mode.default = "auto"
listen_mode.rmempty = false

local external_port_enabled = s:option(Flag, "external_port_enabled", translate("Enable external port access"))
external_port_enabled.default = "0"
external_port_enabled.rmempty = false

local socket_path = s:option(Value, "socket_path", translate("Unix socket path"))
socket_path.default = "/var/run/dockermanager.sock"
socket_path.rmempty = false
socket_path.readonly = true

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
base_path.readonly = true

return m
