local jsonc = require "luci.jsonc"

local agentflow = {}

agentflow.blocks = function()
	local f = io.popen("lsblk -s -f -b -o NAME,FSSIZE,MOUNTPOINT --json", "r")
	local vals = {}
	if f then
		local ret = f:read("*all")
		f:close()
		local obj = jsonc.parse(ret)
		for _, val in pairs(obj and obj["blockdevices"] or {}) do
			local fsize = val["fssize"]
			if fsize ~= nil and string.len(fsize) > 10 and val["mountpoint"] then
				vals[#vals + 1] = val["mountpoint"]
			end
		end
	end
	return vals
end

agentflow.home = function()
	local uci = require "luci.model.uci".cursor()
	local home_dirs = {}
	home_dirs["main_dir"] = uci:get_first("quickstart", "main", "main_dir", "/root")
	home_dirs["Configs"] = uci:get_first("quickstart", "main", "conf_dir", home_dirs["main_dir"] .. "/Configs")
	return home_dirs
end

agentflow.find_paths = function(blocks, home_dirs)
	local default_path = home_dirs["Configs"] .. "/AgentFlow"
	local paths = {}

	if #blocks == 0 then
		table.insert(paths, default_path)
	else
		for _, val in pairs(blocks) do
			table.insert(paths, val .. "/Configs/AgentFlow")
		end
		if default_path == "/root/Configs/AgentFlow" then
			default_path = paths[1]
		end
	end

	return paths, default_path
end

return agentflow
