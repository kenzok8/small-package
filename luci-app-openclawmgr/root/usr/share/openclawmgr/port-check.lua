-- Refuse unrelated listeners before downloading or activating a release.
local s=require('system')
local M={}
function M.check(base,port,pid)
  port=tonumber(port)
  s.need(port and port%1==0 and port>1024 and port<=65535,'INVALID_INPUT','Invalid Gateway port')
  local owned={}
  pid=tonumber(pid)
  local function home(candidate)
    for value in(s.read('/proc/'..candidate..'/environ')or''):gmatch('[^%z]+')do
      if value:sub(1,5)=='HOME='then return value:sub(6)end
    end
  end
  if pid and pid>1 and pid%1==0 then
    -- A procd instance from an old data directory is a different instance.
    if home(pid)==base..'/data'then
      -- The official CLI spawns the actual listener below the procd PID.
      local parents={}
      for candidate in s.fs.dir('/proc')do
        if candidate:match('^%d+$')then
          parents[tonumber(candidate)]=tonumber((s.read('/proc/'..candidate..'/status')or''):match('PPid:%s+(%d+)'))
        end
      end
      local function related(candidate)
        for _=1,64 do
          if candidate==pid then return true end
          candidate=parents[candidate];if not candidate or candidate<=1 then return false end
        end
        return false
      end
      parents[pid]=parents[pid]or 1
      for candidate in pairs(parents)do if related(candidate)and home(candidate)==base..'/data'then
        local path='/proc/'..candidate..'/fd'
        local files=s.fs.dir(path)
        if files then for name in files do
          local inode=(s.fs.readlink(path..'/'..name)or''):match('^socket:%[(%d+)%]$')
          if inode then owned[inode]=true end
        end end
      end end
    end
  end
  for _,path in ipairs({'/proc/net/tcp','/proc/net/tcp6'})do
    local contents=s.read(path)
    if not contents and path=='/proc/net/tcp6'and not s.fs.lstat(path)then contents=''end
    s.need(contents,'OFFLINE','Cannot inspect listening Gateway ports')
    for line in contents:gmatch('[^\n]+')do
      local fields={};for value in line:gmatch('%S+')do fields[#fields+1]=value end
      local local_port=fields[2]and fields[2]:match(':([%x]+)$')
      if fields[4]=='0A'and tonumber(local_port,16)==port then
        s.need(owned[fields[10]],'PORT_IN_USE','Gateway port '..port..' is already used outside this application instance; stop the previous Gateway or choose another port in settings')
      end
    end
  end
  return {available=true}
end
return M
