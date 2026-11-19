local jsonc = require "luci.jsonc"

local agent2api = {}

agent2api.blocks = function()
  local f = io.popen("lsblk -s -f -b -o NAME,FSSIZE,MOUNTPOINT --json", "r")
  local vals = {}
  if f then
    local ret = f:read("*all")
    f:close()
    local obj = jsonc.parse(ret)
    if obj and obj["blockdevices"] then
      for _, val in pairs(obj["blockdevices"]) do
        local fsize = val["fssize"]
        if fsize ~= nil and string.len(fsize) > 10 and val["mountpoint"] then
          -- fsize > 1G
          vals[#vals+1] = val["mountpoint"]
        end
      end
    end
  end
  return vals
end

agent2api.home = function()
  local uci = require "luci.model.uci".cursor()
  local home_dirs = {}
  home_dirs["main_dir"] = uci:get_first("quickstart", "main", "main_dir", "/root")
  home_dirs["Configs"] = uci:get_first("quickstart", "main", "conf_dir", home_dirs["main_dir"].."/Configs")
  home_dirs["Public"] = uci:get_first("quickstart", "main", "pub_dir", home_dirs["main_dir"].."/Public")
  home_dirs["Caches"] = uci:get_first("quickstart", "main", "tmp_dir", home_dirs["main_dir"].."/Caches")
  return home_dirs
end

agent2api.find_paths = function(blocks, home_dirs, path_name)
  local appname = '/Agent2API'
  local default_path = home_dirs[path_name] .. appname

  if default_path == "/root/" .. path_name .. appname and #blocks > 0 then
    default_path = blocks[1] .. "/" .. path_name .. appname
  end

  local configs = { default_path }
  local seen = { [default_path] = true }
  for _, val in ipairs(blocks) do
    local path = val .. "/" .. path_name .. appname
    if not seen[path] then
      table.insert(configs, path)
      seen[path] = true
    end
  end

  return configs, default_path
end

return agent2api
