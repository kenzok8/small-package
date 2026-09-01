local m, s
local sys = require "luci.sys"

m = Map("kaiplus", translate("KaiPlus"), translate("KaiPlus is an AI workspace and session service."))
m:section(SimpleSection).template = "kaiplus/kaiplus_status"

m.on_after_commit = function(self)
	sys.call("/etc/init.d/kaiplus restart >/dev/null 2>&1")
	if sys.call("[ -x /etc/init.d/linkease ]") == 0 then
		sys.call("/etc/init.d/linkease restart >/dev/null 2>&1 &")
	end
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
socket_path.default = "/var/run/kaiplus.sock"
socket_path.rmempty = false
socket_path.readonly = true

local port = s:option(Value, "port", translate("Web port"))
port.default = "8189"
port.rmempty = false
port.datatype = "port"
port.description = translate("Port for the KaiPlus web service.")

local bind_addr = s:option(Value, "bind_addr", translate("Bind address"))
bind_addr.default = "0.0.0.0"
bind_addr.rmempty = false

local base_path = s:option(Value, "base_path", translate("Base path"))
base_path.default = "/apps/kaiplus/"
base_path.rmempty = false
base_path.readonly = true

return m
