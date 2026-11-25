-- Read-only suggestions. Initializing or switching storage still goes through
-- the public settings transaction and store.validate/open.
local sys=require('system')
local store=require('store')
local wire=require('wire')
local M={}
function M.discover(current,configs)
  local paths,seen,mounts=wire.array(),{},{}
  local function add(path)
    if not seen[path]then paths[#paths+1]=path;seen[path]=true end
  end
  for line in (sys.read('/proc/mounts')or''):gmatch('[^\n]+')do
    local dev,point,kind,options=line:match('^(%S+) (%S+) (%S+) (%S+)')
    -- iStoreOS disk roots live directly under /mnt. Container/bind mounts
    -- below an existing disk are not separate storage choices.
    if point and point:match('^/mnt/[^/]+$')and dev:sub(1,5)=='/dev/'
      and not dev:match('^/dev/loop')and not dev:match('^/dev/ram')
      and kind~='tmpfs'and kind~='overlay'
      and not (','..options..','):find(',ro,',1,true)
      and not (','..options..','):find(',noexec,',1,true)then
      local path=point..'/Configs/Runtime'
      if pcall(store.validate,path)then mounts[point]=path end
    end
  end
  local sorted={};for _,path in pairs(mounts)do sorted[#sorted+1]=path end;table.sort(sorted)
  local recommended=sorted[1]or''
  if type(configs)=='string'and configs~=''then
    local candidate=configs:gsub('/+$','')..'/Runtime'
    local mount=candidate:match('^(/mnt/[^/]+)/')
    if mounts[mount]and pcall(store.validate,candidate)then recommended=candidate end
  end
  if current and current~=''then add(current)end
  if recommended~=''then add(recommended)end
  for _,path in ipairs(sorted)do add(path)end
  return paths,recommended
end
return M
