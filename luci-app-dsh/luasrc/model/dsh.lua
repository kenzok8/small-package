local jsonc = require "luci.jsonc"

local dsh = {}

function dsh.blocks()
	local pipe = io.popen("lsblk -s -f -b -o NAME,FSSIZE,MOUNTPOINT --json", "r")
	local values = {}
	if pipe then
		local parsed = jsonc.parse(pipe:read("*all"))
		pipe:close()
		for _, device in pairs(parsed and parsed.blockdevices or {}) do
			local size = device.fssize
			local mountpoint = device.mountpoint
			if size ~= nil and string.len(size) > 10 and mountpoint and mountpoint:match("^/mnt/") then
				values[#values + 1] = mountpoint
			end
		end
	end
	return values
end

function dsh.paths(blocks)
	local data_paths = {}
	local workspace_paths = {}
	for _, mountpoint in ipairs(blocks) do
		data_paths[#data_paths + 1] = mountpoint .. "/Configs/DSH"
		workspace_paths[#workspace_paths + 1] = mountpoint .. "/Public/DSH"
	end
	return data_paths, workspace_paths, data_paths[1] or "", workspace_paths[1] or ""
end

return dsh
