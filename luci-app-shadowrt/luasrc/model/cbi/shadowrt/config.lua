--[[
LuCI - Lua Configuration Interface
]]--

local taskd = require "luci.model.tasks"

local util  = require "luci.util"
local jsonc = require "luci.jsonc"

local block_dir = function()
	local f = io.popen("lsblk -s -f -b -o NAME,FSSIZE,MOUNTPOINT,FSTYPE --json", "r")
	local vals = {}
	if f then
		local ret = f:read("*all")
		f:close()
		local obj = jsonc.parse(ret)
		for _, val in pairs(obj["blockdevices"]) do
			local fsize = val["fssize"]
			if fsize ~= nil and string.len(fsize) > 9 and val["mountpoint"] 
					and val["mountpoint"] ~= "/rom" and val["mountpoint"] ~= "/overlay" and val["mountpoint"] ~= "/ext_overlay" then
				-- fsize > 1GB and has mountpoint
				vals[#vals+1] = {val["mountpoint"], val["fstype"]}
			end
		end
	end
	return vals
end

local homedir = function()
	local uci = require "luci.model.uci".cursor()
	local home_dirs = {}
	home_dirs["main_dir"] = uci:get_first("quickstart", "main", "main_dir", "/root")
	home_dirs["Configs"] = uci:get_first("quickstart", "main", "conf_dir", home_dirs["main_dir"].."/Configs")
	return home_dirs
end

local find_paths = function()
	local blocks = block_dir()
	local home_dirs = homedir()
	local path_name = "Configs"
	local default_path = ''
	local configs = {}

	default_path = home_dirs[path_name] .. "/ShadoWRT"
	if #blocks == 0 then
		table.insert(configs, {default_path, "rootfs"})
	else
		for _, val in pairs(blocks) do
			table.insert(configs, {val[1] .. "/" .. path_name .. "/ShadoWRT", val[2]})
		end
		local without_conf_dir = "/root/" .. path_name .. "/ShadoWRT"
		if default_path == without_conf_dir then
			default_path = configs[1][1]
		end
	end

	return configs, default_path
end

local m, s, o

m = taskd.docker_map("shadowrt", "shadowrt", "/usr/libexec/istorec/shadowrt.sh",
	translate("ShadoWRT"), 
	translate("ShadoWRT uses the host's /rom as the base image for its clones, so it only supports hosts using SquashFS firmware. After the host system is upgraded, the clones will also use the new version.") .. "<br>"
		.. translate("The clone cannot directly access the disk or mount the disk, but /mnt can share the host's.") .. "<br>"
		.. translate("Some services are unavailable in the clone, such as hardware-related services and OAF. In addition, the Docker service is disabled by default because the host already has the Docker service. If you need to enable the Docker service in the clone, you can enable it under the \"Startup\" menu on the clone's LuCI."))

s = m:section(TypedSection, "instance", translate("Configuration"),
		translate("The following network parameters will only take effect during instance fresh installation or after reset:"))
s.addremove=false
s.anonymous=true

o = s:option(Value, "id", "ID".."<b>*</b>", translate("This ID will be used as hostname and container name, only letters, numbers, underscore and hyphen are allowed. Same ID will overwrite existing instance, please avoid using the name as other Docker containers"))
o.rmempty = false
o.datatype = "hostname"

o = s:option(Value, "data", translate("Data Directory").."<b>*</b>", translate("Will create sub-directory by ID under the selected path, so the path can be shared among multiple instances. Please select a file system with good Linux compatibility, such as ext4, btrfs, zfs, etc."))
o.rmempty = false
o.datatype = "string"

o:value("", translate("-- Please choose --"))

local paths, default_path = find_paths()
for _, val in pairs(paths) do
	o:value(val[1], val[1] .. " (" .. val[2] .. ")")
end

o = s:option(Flag, "mnt", translate("Share /mnt"), translate("Share host's /mnt directory"))
o.default = 0

o = s:option(ListValue, "proto", translate("IP Protocol"), translate("Select how this instance gets its IP address"))
o:value("static", translate("Static address"))
o:value("dhcp", translate("DHCP client"))
o.default = "static"

o = s:option(Value, "address", translate("IP Address").."<b>*</b>", translate("Format: xxx.xxx.xxx.xxx/xx"))
o.rmempty = false
o.datatype = "cidr4"
o:depends("proto", "static")

o = s:option(Value, "gateway", translate("Gateway"))
o.datatype = "ip4addr(\"nomask\")"
o:depends("proto", "static")

o = s:option(Value, "dns", translate("DNS Servers"), translate("Multiple DNS servers can be separated by spaces, e.g., '8.8.8.8 8.8.4.4'"))
o.datatype = "string"
o:depends("proto", "static")

o = s:option(Flag, "dhcp_server", translate("DHCP Server"), translate("Enable DHCP server on this instance"))
o.default = 0
o.rmempty = false
o:depends("proto", "static")

return m
