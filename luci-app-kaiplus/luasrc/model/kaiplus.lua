local jsonc = require "luci.jsonc"

local kaiplus = {}

kaiplus.blocks = function()
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

kaiplus.home = function()
  local uci = require "luci.model.uci".cursor()
  local home_dirs = {}
  home_dirs["main_dir"] = uci:get_first("quickstart", "main", "main_dir", "/root")
  home_dirs["Configs"] = uci:get_first("quickstart", "main", "conf_dir", home_dirs["main_dir"] .. "/Configs")
  home_dirs["Public"] = uci:get_first("quickstart", "main", "pub_dir", home_dirs["main_dir"] .. "/Public")
  home_dirs["Downloads"] = uci:get_first("quickstart", "main", "dl_dir", home_dirs["Public"] .. "/Downloads")
  home_dirs["Caches"] = uci:get_first("quickstart", "main", "tmp_dir", home_dirs["main_dir"] .. "/Caches")
  return home_dirs
end

kaiplus.find_paths = function(blocks, home_dirs, path_name)
  local default_path = home_dirs[path_name] .. "/KAIPlus"
  local paths = {}

  if #blocks == 0 then
    table.insert(paths, default_path)
  else
    for _, val in pairs(blocks) do
      table.insert(paths, val .. "/" .. path_name .. "/KAIPlus")
    end
    local without_conf_dir = "/root/" .. path_name .. "/KAIPlus"
    if default_path == without_conf_dir then
      default_path = paths[1]
    end
  end

  return paths, default_path
end

return kaiplus
