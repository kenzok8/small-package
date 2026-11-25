-- Exact-version, root-scoped dependency preparation. Tasks own all mutation.
local s=require('system')
local store=require('store')
local c=require('contract')
local tasks=require('tasks')
local libs=require('libraries')
local M={}
function M.library(id,arch)
  for _,revision in ipairs({'r1','r2'})do
    local d=libs.definition(arch,revision);if d.id==id then return d end
  end
  s.fail('UNSUPPORTED','Unknown pinned library recipe')
end
local function existing(ctx)
  if not s.fs.lstat(ctx.root..'/.lock')then return end
  local owner=s.decode(ctx.root..'/.lock/owner.json')
  local t=owner and tasks.get(ctx,owner.id)
  s.need(t and t.status=='running'and s.alive(t.owner),'BUSY','Finish or recover the active repository operation')
  return {ready=false,owned=false,task=t,waiting=true}
end
local function validate_sdk(ctx,id,work,log)
  local r=s.decode(ctx.root..'/environments/'..id..'/receipt.json');c.receipt(r)
  s.need(r.verified and r.root==ctx.root and r.instance==id,'INTEGRITY','Installed SDK does not match the repository')
  if r.library then libs.check(ctx,r.library,work)end
  local commands={node={'node','--version'},python={'python','--version'},go={'go','version'},zig={'zig','version'}}
  local args={ctx.root..'/wrap/'..id};for _,v in ipairs(commands[r.entry.tool]or{})do args[#args+1]=v end
  s.need(#args>1 and s.run(args,{output=log,timeout=45,env={ISTORE_RUNTIME_ACCELERATION='origin'}})==0,'PROBE_FAILED','Installed SDK cannot execute')
  return r
end
function M.ensure(ctx,r)
  local busy=existing(ctx);if busy then return busy end
  local entry,definition,id
  if r.op=='library-repair'then definition=M.library(r.id,s.nixio.uname().machine)
  else
    for _,e in ipairs(ctx.catalog.entries)do if e.id==r.entry then entry=e;break end end
    s.need(entry and entry.arch==s.nixio.uname().machine and entry.availability=='available','UNSUPPORTED','Exact SDK is unavailable')
    s.need(require('adapters').enabled[entry.tool],'UNSUPPORTED','Tool adapter is not enabled')
    if entry.abi=='glibc'then definition=M.library(r.library or libs.definition(entry.arch).id,entry.arch)
    else s.need(r.library==nil,'INVALID_INPUT','This SDK does not use a GNU library')end
    id=c.instance_id(entry,nil,definition and definition.id)
    if not s.fs.lstat(ctx.root..'/environments/'..id)then store.validate(ctx.root,2*1024^3,30000)end
  end
  local plan={schema_version=1,id=s.identifier('dependency'),revision=store.state(ctx).revision,
    catalog_revision=ctx.catalog.revision,entry=entry and entry.id,instance=id,library=definition and definition.id,
    source=r.source,created=os.time(),path=ctx.root,kind=entry and'ensure'or'library-repair'}
  local started,t=pcall(tasks.start,ctx,plan,function(cx,task,work,log)
    if definition then
      tasks.phase(cx,task,'library')
      if not pcall(libs.check,cx,definition.id,work)then
        local options={};for k,v in pairs(cx.download_options or{})do options[k]=v end
        options.repair=true;options.task=task
        libs.ensure(cx,definition,r.source,work,log,options)
      end
    end
    if not entry then store.bump(cx);return {library=definition.id,verified=true}end
    if not s.fs.lstat(cx.root..'/environments/'..id)then return require('adapters').install(cx,task,work,log)end
    tasks.phase(cx,task,'probe');return validate_sdk(cx,id,work,log)
  end)
  if not started then
    if type(t)=='table'and t.code=='BUSY'then return existing(ctx)end
    error(t,0)
  end
  return {ready=false,owned=true,task=t,waiting=false}
end
return M
