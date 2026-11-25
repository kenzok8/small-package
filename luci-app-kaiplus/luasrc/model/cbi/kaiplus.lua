local m, s
local sys = require "luci.sys"
local kaiplus_model = require "luci.model.kaiplus"

m = Map("kaiplus", translate("KaiPlus"), translate("KaiPlus is an AI workspace and session service."))
m:section(SimpleSection).template = "kaiplus/kaiplus_status"

m.on_after_commit = function(self)
	sys.call("/etc/init.d/kaiplus restart >/dev/null 2>&1")
	if self.uci:get_first("kaiplus", "kaiplus", "enabled") == "1" then
		local port = self.uci:get_first("kaiplus", "kaiplus", "port") or "8189"
		kaiplus_model.wait_ready(port, 30, 500)
	end
	if sys.call("[ -x /etc/init.d/linkease ]") == 0 then
		sys.call("/etc/init.d/linkease restart >/dev/null 2>&1 &")
	end
end

s = m:section(TypedSection, "kaiplus", translate("Global settings"))
s.addremove = false
s.anonymous = true

s:option(Flag, "enabled", translate("Enable")).rmempty = false

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

local backup_dir = s:option(Value, "backup_dir", translate("Backup directory"))
backup_dir.rmempty = false
backup_dir.description = translate("Required. Device recovery points are stored here. The default TimeMachine folder is at the disk root, next to Configs.")

local backup_paths, default_backup_path = kaiplus_model.find_root_paths(blocks, home, "TimeMachine")
for _, val in pairs(backup_paths) do
	backup_dir:value(val, val)
end
backup_dir.default = default_backup_path

local port = s:option(Value, "port", translate("Access port"))
port.default = "8189"
port.rmempty = false
port.datatype = "port"
port.description = translate("KaiPlus is available at http://router-address:port/apps/kaiplus/.")

return m
