local jsonc = require "luci.jsonc"
local opencode = {}

function opencode.blocks()
	local f = io.popen("lsblk -s -f -b -o NAME,FSSIZE,MOUNTPOINT --json", "r")
	local values = {}
	if f then
		local object = jsonc.parse(f:read("*all"))
		f:close()
		for _, value in pairs(object and object.blockdevices or {}) do
			if value.fssize and #tostring(value.fssize) > 10 and value.mountpoint then
				values[#values + 1] = value.mountpoint
			end
		end
	end
	return values
end

function opencode.home()
	local uci = require "luci.model.uci".cursor()
	local main = uci:get_first("quickstart", "main", "main_dir", "/root")
	return uci:get_first("quickstart", "main", "conf_dir", main .. "/Configs")
end

function opencode.find_paths()
	local default = opencode.home() .. "/OpenCode"
	local values = {}
	for _, mount in pairs(opencode.blocks()) do values[#values + 1] = mount .. "/Configs/OpenCode" end
	if #values == 0 then values[1] = default end
	if default == "/root/Configs/OpenCode" then default = values[1] end
	return values, default
end

return opencode
