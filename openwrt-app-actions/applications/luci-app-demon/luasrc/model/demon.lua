local util  = require "luci.util"
local jsonc = require "luci.jsonc"
local nixio = require "nixio"
local uci = luci.model.uci.cursor()

local demon = {}

demon.caches = function()
  local f = io.popen("lsblk -s -f -b -o NAME,FSSIZE,MOUNTPOINT --json", "r")
  local vals = {}
  local old_cache = uci:get("wxedge", "@wxedge[0]", "cache_path") or ""
  if old_cache ~= nil and string.len(old_cache) > 0 then
    vals[#vals+1] = old_cache
  end
  if f then
    local ret = f:read("*all")
    f:close()
    local obj = jsonc.parse(ret)
    for _, val in pairs(obj["blockdevices"]) do
      local fsize = val["fssize"]
      if fsize ~= nil and string.len(fsize) > 10 and val["mountpoint"] and val["mountpoint"] ~= old_cache then
        -- fsize > 1G
        vals[#vals+1] = val["mountpoint"] .. "/demon_cache"
      end
    end
  end
  return vals
end

return demon

