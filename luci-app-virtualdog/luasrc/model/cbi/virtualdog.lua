local m, s

m = Map("virtualdog", translate("VirtualDog"), translate("VirtualDog provides a QEMU/KVM VM management UI."))
m:section(SimpleSection).template = "virtualdog/virtualdog_status"

s = m:section(TypedSection, "virtualdog", translate("Global settings"))
s.addremove = false
s.anonymous = true

s:option(Flag, "enabled", translate("Enable")).rmempty = false

local virtualdog_model = require "luci.model.virtualdog"

local data_dir = s:option(Value, "data_dir", translate("Data directory"))
data_dir.rmempty = false
data_dir.description = translate("Required. VirtualDog stores VM metadata, runtime files and disk images under this directory.")

local port = s:option(Value, "port", translate("Listen port"))
port.default = "8080"
port.rmempty = false
port.datatype = "port"
port.description = translate("Port for VirtualDog HTTP server.")

local access_token = s:option(Value, "access_token", translate("Access token"))
access_token.password = true
access_token.optional = true

local help = s:option(DummyValue, "_kvm_help", translate("KVM packages"))
help.rawhtml = true
function help.cfgvalue()
	return "<pre>" .. virtualdog_model.kvm_help() .. "</pre>"
end

return m
