local fs = require "nixio.fs"

local m, s

local function starts_with(value, prefix)
	return value:sub(1, #prefix) == prefix
end

local function decode_mount_path(value)
	return value:gsub("\\040", " "):gsub("\\011", "\t"):gsub("\\012", "\n"):gsub("\\134", "\\")
end

local function is_persistent_mount(path, fstype)
	if path == "" or path == "/" then
		return false
	end
	if starts_with(path, "/tmp") or starts_with(path, "/var") or starts_with(path, "/run") then
		return false
	end
	if starts_with(path, "/dev") or starts_with(path, "/proc") or starts_with(path, "/sys") then
		return false
	end
	if starts_with(path, "/rom") or starts_with(path, "/overlay") then
		return false
	end
	if fstype == "tmpfs" or fstype == "devtmpfs" or fstype == "overlay" or fstype == "squashfs" then
		return false
	end
	return true
end

local function storage_mounts()
	local mounts = {}
	for line in io.lines("/proc/mounts") do
		local device, path, fstype = line:match("^(%S+)%s+(%S+)%s+(%S+)")
		path = path and decode_mount_path(path) or ""
		if device and fstype and is_persistent_mount(path, fstype) then
			mounts[#mounts + 1] = {
				path = path,
				label = string.format("%s (%s)", path, fstype)
			}
		end
	end
	table.sort(mounts, function(a, b) return a.path < b.path end)
	return mounts
end

local function ensure_linkease_config(uci)
	if not fs.access("/etc/config/linkease") then
		fs.writefile("/etc/config/linkease", "")
	end
	uci:load("linkease")
	local section = uci:get_first("linkease", "linkease")
	if not section then
		section = uci:add("linkease", "linkease")
		uci:set("linkease", section, "enabled", "0")
		uci:set("linkease", section, "port", "8897")
		uci:set("linkease", section, "allowPublic", "0")
		uci:commit("linkease")
	end
	return section
end

m = Map("linkeasefull", translate("LinkEase Full"), translate("LinkEase Full uses fixed entries at port 19290 /apps/ and legacy port 8897."))

m:section(SimpleSection).template = "linkeasefull_status"

s = m:section(TypedSection, "linkeasefull", translate("Storage"))
s.addremove = false
s.anonymous = true

s:option(Flag, "enabled", translate("Enable")).rmempty = false

local data = s:option(ListValue, "_local_home", translate("Storage path"), translate("Choose a mounted persistent disk. /tmp is not allowed."))
data.rmempty = false

ensure_linkease_config(m.uci)
local current = m.uci:get_first("linkease", "linkease", "local_home") or ""
local has_current = false
for _, mount in ipairs(storage_mounts()) do
	data:value(mount.path, mount.label)
	if mount.path == current then
		has_current = true
	end
end
if current ~= "" and not has_current and fs.stat(current, "type") == "dir" and is_persistent_mount(current, "") then
	data:value(current, current)
end

function data.validate(self, value)
	if value == nil or value == "" then
		return nil, translate("Please choose a mounted persistent disk.")
	end
	if not is_persistent_mount(value, "") then
		return nil, translate("/tmp and system paths cannot be used for LinkEase Full storage.")
	end
	if fs.stat(value, "type") ~= "dir" then
		return nil, translate("The selected storage path does not exist.")
	end
	return value
end

function data.cfgvalue(self, section)
	m.uci:load("linkease")
	return m.uci:get_first("linkease", "linkease", "local_home") or ""
end

function data.write(self, section, value)
	local linkease_section = ensure_linkease_config(m.uci)
	m.uci:set("linkease", linkease_section, "local_home", value)
	m.uci:commit("linkease")
end

return m
