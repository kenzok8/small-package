-- Preserve empty arrays and nulls on the public JSON interface with json-c.
local json=require('luci.jsonc')
local M={null={}}
local array={}
function M.array(value)return setmetatable(value or{},array)end
function M.encode(value)
  if value==M.null or value==nil then return'null'end
  if type(value)~='table'then return assert(json.stringify(value))end
  local out={}
  if getmetatable(value)==array or #value>0 then
    for i=1,#value do out[#out+1]=M.encode(value[i])end
    return'['..table.concat(out,',')..']'
  end
  local keys={};for key in pairs(value)do assert(type(key)=='string');keys[#keys+1]=key end;table.sort(keys)
  for _,key in ipairs(keys)do out[#out+1]=json.stringify(key)..':'..M.encode(value[key])end
  return'{'..table.concat(out,',')..'}'
end
return M
