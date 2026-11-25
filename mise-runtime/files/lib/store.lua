local sys=require('system')
local fs=sys.fs
local contract=require('contract')
local M={}
function M.validate(root,need_bytes,need_inodes)
  contract.path(root)
  local current=''
  for part in root:gmatch('[^/]+')do
    current=current..'/'..part
    local s=fs.lstat(current)
    sys.need(not s or s.type=='dir','OFFLINE','Path contains a link or non-directory: '..current)
    sys.need(not s or (s.modedec%10)%2==1,'OFFLINE','Shared SDK parent must allow directory traversal: '..current)
  end
  local nearest=root
  while not fs.stat(nearest)do nearest=assert(nearest:match('^(.*)/[^/]+$'))end
  sys.need(fs.realpath(nearest)==nearest,'OFFLINE','Storage path is not canonical')
  return M.filesystem(root,need_bytes,need_inodes,nearest)
end
function M.filesystem(root,need_bytes,need_inodes,nearest)
  nearest=nearest or root
  while not fs.stat(nearest)do nearest=assert(nearest:match('^(.*)/[^/]+$'))end
  local selected
  for line in (sys.read('/proc/mounts')or''):gmatch('[^\n]+')do
    local dev,point,kind,options=line:match('^(%S+) (%S+) (%S+) (%S+)')
    if point and (root==point or root:sub(1,#point+1)==point..'/') and (not selected or #point>#selected.point)then
      selected={device=dev,point=point,kind=kind,options=options}
    end
  end
  sys.need(selected and selected.point:sub(1,5)=='/mnt/' and selected.device:sub(1,5)=='/dev/' and selected.kind~='tmpfs' and selected.kind~='overlay','OFFLINE','Persistent disk is not mounted')
  sys.need(not (','..selected.options..','):find(',ro,',1,true) and not (','..selected.options..','):find(',noexec,',1,true),'OFFLINE','Storage must be writable and executable')
  local stat=fs.statvfs(nearest);sys.need(stat,'OFFLINE','Cannot inspect filesystem')
  local bytes=stat.bavail*(stat.frsize or stat.bsize)
  sys.need(bytes>=(need_bytes or 0),'NO_SPACE','Insufficient free disk space')
  sys.need(stat.ffree==0 and stat.files==0 or stat.ffree>=(need_inodes or 0),'NO_SPACE','Insufficient free inodes')
  return {mount=selected,device=fs.stat(nearest).dev,free_bytes=bytes,free_inodes=stat.ffree}
end
function M.open(root,initialize)
  local storage=M.validate(root)
  sys.need(sys.nixio.getuid()==0,'INVALID_INPUT','Runtime management requires administrator privileges')
  local marker=root..'/.storage.json';local existing=sys.decode(marker)
  sys.need(existing or initialize,'OFFLINE','Storage is not initialized; configure its persistent root explicitly')
  local rc,info=sys.pipe_capture({'/sbin/block','info',storage.mount.device})
  local uuid=info:match(' UUID="([^"]+)"')
  sys.need(rc==0 and uuid,'OFFLINE','Cannot identify backing filesystem UUID')
  if existing then
    sys.need(existing.uuid==uuid and existing.mount==storage.mount.point,'OFFLINE','Mounted disk identity changed')
  end
  sys.mkdir(root,493)
  -- Only explicit initialization creates the compatible administrator HOME.
  -- Existing installations create it on execution; read-only discovery does
  -- not silently move or adopt their previous users/0/home contents.
  if initialize then sys.mkdir(root..'/home',448)end
  for _,name in ipairs({'environments','libraries','wrap','mise','users'})do sys.mkdir(root..'/'..name,493)end
  for _,name in ipairs({'tasks','plans','cache','work'})do sys.mkdir(root..'/'..name,448)end
  if not existing then sys.write(marker,{schema_version=1,uuid=uuid,mount=storage.mount.point,source=storage.mount.device})end
  return {root=root,storage=storage}
end
function M.state(ctx)
  return sys.decode(ctx.root..'/state.json')or{schema_version=1,revision=0}
end
function M.bump(ctx)
  local state=M.state(ctx);state.revision=state.revision+1;sys.write(ctx.root..'/state.json',state);return state.revision
end
function M.lock(ctx,owner)
  local path=ctx.root..'/.lock'
  sys.need(fs.mkdir(path,'700'),'BUSY','Another operation or interrupted transaction holds the lock')
  sys.write(path..'/owner.json',owner)
end
function M.unlock(ctx,id)
  local path=ctx.root..'/.lock';local owner=sys.decode(path..'/owner.json')
  sys.need(owner and owner.id==id,'BUSY','Lock ownership changed')
  sys.remove(path)
end
function M.list(path)
  local result={}
  if not fs.stat(path)then return result end
  for name in fs.dir(path)do if name~='.' and name~='..'then result[#result+1]=name end end
  table.sort(result);return result
end
return M
