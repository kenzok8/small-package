local sys=require('system')
local store=require('store')
local contract=require('contract')
local n,fs=sys.nixio,sys.fs
local M={}
local function directory(ctx,id)contract.key(id);return ctx.root..'/tasks/'..id end
function M.get(ctx,id)return sys.decode(directory(ctx,id)..'/task.json')end
function M.save(ctx,t)sys.write(directory(ctx,t.id)..'/task.json',t)end
function M.phase(ctx,t,phase)
  store.validate(ctx.root)
  t.phase=phase;M.save(ctx,t)
  local f=assert(io.open(directory(ctx,t.id)..'/log','a'));f:write(os.date('!%Y-%m-%dT%H:%M:%SZ')..' '..phase..'\n');f:close()
end
function M.cleanup(ctx,t)
  if t.phase=='committed'and t.publication then require('adapters').publish(ctx,t)end
  require('libraries').recover(ctx,t)
  -- The work path is task-owned; never follow a symlink into another SDK.
  sys.remove(ctx.root..'/work/'..contract.key(t.id))
  if t.pending_environment and t.phase~='committed' then
    local path=ctx.root..'/environments/'..contract.key(t.pending_environment.id)
    local st=fs.lstat(path)
    if st then
      sys.need(st.ino==t.pending_environment.inode,'INTEGRITY','Candidate ownership changed; preserving it')
      sys.remove(path)
    end
  end
end
function M.start(ctx,plan,workfn)
  local id=sys.identifier('task')
  store.lock(ctx,{id=id,boot=sys.boot_id()})
  local dir=directory(ctx,id);sys.mkdir(dir,448)
  local t={schema_version=1,id=id,kind='install',status='running',phase='starting',started=os.time(),plan=plan}
  M.save(ctx,t)
  local pid=n.fork()
  if not pid then store.unlock(ctx,id);sys.fail('OFFLINE','Cannot start worker')end
  if pid==0 then
    n.setsid()
    local out=n.open(dir..'/log','a','600');n.dup(out,n.stdout);n.dup(out,n.stderr);out:close()
    local input=n.open('/dev/null','r');n.dup(input,n.stdin);input:close()
    t.owner=sys.process(n.getpid());t.owner.id=id
    M.save(ctx,t);sys.write(ctx.root..'/.lock/owner.json',t.owner)
    local work=ctx.root..'/work/'..id;sys.mkdir(work,448)
    sys.command_scope=dir..'/processes';sys.mkdir(sys.command_scope,448)
    local ok,result=pcall(function()
      -- procd may run root preparation with the application's non-root HOME.
      -- Management probes/installers must use the repository administrator
      -- HOME; only this fork changes context, never the caller or app process.
      n.setenv('HOME',ctx.root..'/home')
      n.setenv('ISTORE_RUNTIME_HOME',ctx.root..'/home')
      return workfn(ctx,t,work,dir..'/log')
    end)
    local finish_ok,finish_error=pcall(function()
      if ok then
        t.result=result;M.phase(ctx,t,'committed');t.final_status='success'
      else
        t.final_status='failed';t.error=type(result)=='table' and result or {code='PROBE_FAILED',message=tostring(result)}
      end
      -- A terminal status guarantees cleanup and lock release are finished.
      -- Persist the cleanup receipt first so interruption in this publication
      -- window can finish this task without touching a subsequent task's lock.
      M.stop_commands(ctx,id)
      M.cleanup(ctx,t);t.cleaned=true;t.finished=os.time();M.save(ctx,t)
      store.unlock(ctx,id)
      t.status=t.final_status;M.save(ctx,t)
    end)
    if not finish_ok then
      t.status='interrupted';t.error={code='INTERRUPTED',message=tostring(finish_error)}
      pcall(M.save,ctx,t)
    end
    os.exit(ok and finish_ok and 0 or 1)
  end
  -- Wait only for durable owner registration; completion is a separate state.
  for _=1,40 do local current=M.get(ctx,id);if current and current.owner then return current end;n.nanosleep(0,50000000)end
  sys.fail('INTERRUPTED','Worker did not publish its owner record; recover the starting task')
end
function M.stop_group(owner)
  if not owner then return end
  sys.stop_session(owner)
end
function M.stop_commands(ctx,id)
  local path=directory(ctx,id)..'/processes'
  for _,name in ipairs(store.list(path))do
    local owner=sys.decode(path..'/'..name)
    sys.need(owner and owner.session==owner.pid,'INTEGRITY','Invalid command ownership journal')
    sys.stop_session(owner)
    fs.unlink(path..'/'..name)
  end
end
function M.recover(ctx,id,cancel)
  local t=M.get(ctx,id);sys.need(t,'INVALID_INPUT','Task does not exist')
  sys.need(t.status=='running' or t.status=='interrupted','INVALID_INPUT','Task has already finished')
  if cancel then M.stop_group(t.owner)
  else sys.need(not sys.alive(t.owner),'BUSY','Task is still running');M.stop_group(t.owner)end
  M.stop_commands(ctx,id)
  local latest=M.get(ctx,id)
  local owner=sys.decode(ctx.root..'/.lock/owner.json')
  if latest.cleaned then
    if owner and owner.id==id then store.unlock(ctx,id)end
    latest.status=latest.final_status or(latest.phase=='committed' and'success'or'failed')
    latest.finished=latest.finished or os.time();M.save(ctx,latest);return latest
  end
  sys.need(owner and owner.id==id,'BUSY','Task does not own current lock')
  if latest.phase=='committed' or latest.status=='success'then
    M.cleanup(ctx,latest);latest.cleaned=true;latest.final_status='success';latest.finished=latest.finished or os.time();M.save(ctx,latest)
    store.unlock(ctx,id);latest.status='success';M.save(ctx,latest);return latest
  end
  M.cleanup(ctx,latest)
  latest.cleaned=true;latest.final_status='canceled';latest.finished=os.time();latest.result=cancel and 'Canceled and cleaned' or 'Interrupted candidate recovered'
  M.save(ctx,latest);store.unlock(ctx,id);latest.status='canceled';M.save(ctx,latest);return latest
end
return M
