local jsonc = require "luci.jsonc"

local kaiplus = {}

local function valid_port(port)
  local value = tonumber(port)
  if not value or value < 1 or value > 65535 or value % 1 ~= 0 then
    return nil
  end
  return value
end

kaiplus.ready = function(port)
  local value = valid_port(port)
  if not value then return false end
  local socket = require("nixio").socket("inet", "stream")
  if not socket then return false end
  socket:setopt("socket", "sndtimeo", 1)
  local connected = socket:connect("127.0.0.1", value)
  socket:close()
  return connected == true
end

kaiplus.wait_ready = function(port, attempts, delay_ms)
  attempts = tonumber(attempts) or 30
  delay_ms = tonumber(delay_ms) or 500
  if attempts < 1 then return false end

  for attempt = 1, attempts do
    if kaiplus.ready(port) then return true end
    if attempt < attempts and delay_ms > 0 then
      local seconds = math.floor(delay_ms / 1000)
      local nanoseconds = (delay_ms % 1000) * 1000000
      require("nixio").nanosleep(seconds, nanoseconds)
    end
  end
  return false
end

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

kaiplus.find_paths = function(blocks, home_dirs, path_name, product)
  product = product or "KAIPlus"
  local default_path = home_dirs[path_name] .. "/" .. product
  local paths = {}

  if #blocks == 0 then
    table.insert(paths, default_path)
  else
    for _, val in pairs(blocks) do
      table.insert(paths, val .. "/" .. path_name .. "/" .. product)
    end
    local without_conf_dir = "/root/" .. path_name .. "/" .. product
    if default_path == without_conf_dir then
      default_path = paths[1]
    end
  end

  return paths, default_path
end

return kaiplus
