-- Cloudreve 业务逻辑库
-- 遵循 iStoreOS / openwrt-app-actions 生态标准写法：
--   blocks()     用 lsblk --json 找外置挂载点
--   home()       从 quickstart 读 iStoreOS 的目录约定（Configs / Public / Caches）
--   find_paths() 拼出候选路径
local jsonc = require "luci.jsonc"

local cloudreve = {}

-- 列出所有容量 > 1GiB 且有挂载点的块设备
cloudreve.blocks = function()
	local f = io.popen("lsblk -s -f -b -o NAME,FSSIZE,MOUNTPOINT --json", "r")
	local vals = {}
	if f then
		local ret = f:read("*all")
		f:close()
		local obj = jsonc.parse(ret)
		if obj and obj["blockdevices"] then
			for _, val in pairs(obj["blockdevices"]) do
				local fsize = val["fssize"]
				-- fsize 是字符串形式的字节数，位数 > 10 约等于容量 > 1GiB
				if fsize ~= nil and string.len(fsize) > 10 and val["mountpoint"] then
					vals[#vals + 1] = val["mountpoint"]
				end
			end
		end
	end
	return vals
end

-- iStoreOS 的目录约定来自 quickstart 这个 UCI 命名空间
cloudreve.home = function()
	local uci = require "luci.model.uci".cursor()
	local home_dirs = {}
	home_dirs["main_dir"] = uci:get_first("quickstart", "main", "main_dir", "/root")
	home_dirs["Configs"]  = uci:get_first("quickstart", "main", "conf_dir", home_dirs["main_dir"] .. "/Configs")
	home_dirs["Public"]   = uci:get_first("quickstart", "main", "pub_dir", home_dirs["main_dir"] .. "/Public")
	home_dirs["Caches"]   = uci:get_first("quickstart", "main", "tmp_dir", home_dirs["main_dir"] .. "/Caches")
	return home_dirs
end

-- 拼出候选存储路径（每个挂载点下的 Configs/cloudreve）
cloudreve.find_paths = function(blocks, home_dirs, path_name)
	local appname = "/cloudreve"
	local default_path = ""
	local paths = {}

	if #blocks == 0 then
		default_path = home_dirs[path_name or "Configs"] .. appname
		paths[#paths + 1] = default_path
	else
		for _, val in pairs(blocks) do
			paths[#paths + 1] = val .. "/" .. (path_name or "Configs") .. appname
		end
		default_path = paths[1]
	end

	return paths, default_path
end

return cloudreve
