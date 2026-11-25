local s=require('system')
local store=require('store')
local M={}
function M.save(root,r)
  local gate='/var/lock/mise-runtime-settings'
  if s.fs.lstat(gate)then
    local owner=s.decode(gate..'/owner.json')
    local live=owner and s.process(owner.pid)
    s.need(owner,'BUSY','Unknown settings lock; inspect it before retrying')
    s.need(not live or live.start~=owner.start or live.boot~=owner.boot or live.state=='Z','BUSY','Another settings operation is active')
    s.fs.unlink(gate..'/owner.json');s.fs.rmdir(gate)
  end
  s.need(s.fs.mkdir(gate,'700'),'BUSY','Another storage settings change is active')
  s.write(gate..'/owner.json',s.process(s.nixio.getpid()))
  local held={};local id=s.identifier('settings')
  local function lock(ctx)
    store.lock(ctx,{id=id,boot=s.boot_id()});held[#held+1]=ctx
  end
  local ok,result=pcall(function()
    if root~=''then
      local opened,ctx=pcall(store.open,root)
      if opened then lock(ctx)
      else s.need(type(ctx)=='table'and ctx.code=='OFFLINE','OFFLINE','Cannot inspect current repository')end
    end
    if root~=r.path and root~=''then
      s.need(r.path:sub(1,#root+1)~=root..'/'and root:sub(1,#r.path+1)~=r.path..'/','INVALID_INPUT','Repositories must not contain each other')
    end
    if not s.fs.lstat(r.path..'/.storage.json')then
      s.need(#store.list(r.path)==0,'INVALID_INPUT','Choose an empty directory or an initialized runtime repository')
    end
    local ctx=store.open(r.path,true)
    if r.path~=root or #held==0 then lock(ctx)end
    -- Complete disk/network preparation before changing the active UCI root.
    require('network').refresh(ctx,r.acceleration)
    if os.getenv('MISE_RUNTIME_ROOT')==nil then
      local saved=ctx.root..'/work/'..id;s.mkdir(saved,448)
      local cursor=require('uci').cursor(nil,saved)
      local committed,err=pcall(function()
        s.need(cursor:load('mise'),'OFFLINE','Cannot load runtime settings')
        s.need(cursor:set('mise','main','storage_root',r.path),'OFFLINE','Cannot set storage root')
        s.need(cursor:set('mise','main','acceleration',r.acceleration and'1'or'0'),'OFFLINE','Cannot set download policy')
        s.need(cursor:commit('mise'),'OFFLINE','Cannot commit runtime settings')
      end)
      cursor:unload('mise');s.remove(saved)
      if not committed then error(err,0)end
      require('active-root').publish(r.path)
    end
    return r.path
  end)
  for i=#held,1,-1 do store.unlock(held[i],id)end
  s.fs.unlink(gate..'/owner.json');s.fs.rmdir(gate)
  if not ok then error(result,0)end
  return result
end
return M
