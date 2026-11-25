#!/usr/bin/lua
local share=arg[0]:match('^(.*)/main.lua$')or'/usr/share/mise-runtime'
package.path=share..'/lib/?.lua;'..package.path
local sys=require('system')
local contract=require('contract')
local store=require('store')
local tasks=require('tasks')
local function uci(key)
  local rc,text=sys.pipe_capture({'/sbin/uci','-q','get',key})
  return rc==0 and text:gsub('%s+$','')or''
end
local status=require('status')
local wire=require('wire')
local function dispatch(request)
  contract.request(request)
  local catalog=assert(sys.decode(share..'/catalog.json'))
  if request.op=='catalog'then return catalog end
  local root=os.getenv('MISE_RUNTIME_ROOT')or uci('mise.main.storage_root')
  if request.op=='settings'then
    root=require('settings').save(root,request)
  end
  if root==''then sys.need(request.op=='read','OFFLINE','Configure persistent storage first');return status.empty(catalog)end
  local opened,ctx=pcall(store.open,root)
  if not opened then
    if request.op=='read'and type(ctx)=='table'and ctx.code=='OFFLINE'then local offline=status.empty(catalog,root);offline.storage_error=ctx.message;return offline end
    error(ctx,0)
  end
  ctx.share=share;ctx.catalog=catalog
  ctx.mise_bin=os.getenv('MISE_RUNTIME_MISE_BIN')or'/usr/bin/mise'
  ctx.download_options={ks_cli=os.getenv('MISE_RUNTIME_KS_CLI'),admin_url=os.getenv('MISE_RUNTIME_ADMIN_URL'),download_mode=os.getenv('MISE_RUNTIME_DOWNLOAD_MODE')}
  local state=store.state(ctx)
  if request.op=='read' or request.op=='settings'then
    return status.read(ctx,catalog)
  elseif request.op=='ensure'or request.op=='library-repair'then
    return require('dependencies').ensure(ctx,request)
  elseif request.op=='prepare-user'then
    require('network').refresh(ctx)
    local dir=root..'/users/'..request.uid;sys.mkdir(dir,448)
    local st=sys.fs.lstat(dir);sys.need(st.uid==0 or st.uid==request.uid,'INTEGRITY','User directory ownership differs')
    sys.need(sys.fs.chown(dir,request.uid,request.gid or request.uid),'OFFLINE','Cannot prepare UID directory')
    sys.need(sys.fs.chmod(dir,'700'),'OFFLINE','Cannot protect UID directory')
    local home=request.uid==0 and root..'/home'or dir..'/home'
    sys.mkdir(home,448)
    sys.need(sys.fs.chown(home,request.uid,request.gid or request.uid),'OFFLINE','Cannot prepare UID HOME')
    return {home=home}
  elseif request.op=='cancel' or request.op=='recover'then
    return tasks.recover(ctx,request.id,request.op=='cancel')
  elseif request.op=='inspect' or request.op=='wrap'then
    local dir=root..'/environments/'..request.id
    local receipt=sys.decode(dir..'/receipt.json');sys.need(receipt,'INVALID_INPUT','Environment does not exist');contract.receipt(receipt)
    if request.op=='inspect'then return receipt end
    return sys.read(root..'/wrap/'..request.id)
  elseif request.op=='plan'then
    sys.need(not sys.fs.lstat(root..'/.lock'),'BUSY','Handle the current/interrupted task first')
    local entry
    for _,e in ipairs(catalog.entries)do if e.id==request.entry then entry=e;break end end
    sys.need(entry,'UNSUPPORTED','Unknown catalog entry');contract.entry(entry)
    if request.npm and request.npm~=entry.npm then
      local selected
      for _,e in ipairs(catalog.entries)do
        if e.tool=='node'and entry.tool=='node'and e.version==entry.version and e.arch==entry.arch and e.abi==entry.abi and e.npm==request.npm then selected=e;break end
      end
      sys.need(selected,'UNSUPPORTED','npm version is not in the pinned compatible catalog');entry=selected
    end
    sys.need(entry.arch==sys.nixio.uname().machine,'UNSUPPORTED','Artifact architecture differs from host')
    local ok,adapters=pcall(require,'adapters');sys.need(ok and adapters.enabled[entry.tool],'UNSUPPORTED','Tool adapter is not enabled')
    local library=entry.abi=='glibc' and require('libraries').definition(entry.arch).id or nil
    local id=contract.instance_id(entry,nil,library)
    sys.need(not sys.fs.lstat(root..'/environments/'..id),'BUSY','Exact environment is already installed')
    store.validate(root,2*1024*1024*1024,30000)
    local p={schema_version=1,id=sys.identifier('plan'),revision=state.revision,catalog_revision=catalog.revision,entry=entry.id,instance=id,source=request.source,created=os.time(),expires=os.time()+300,path=root}
    sys.write(root..'/plans/'..p.id..'.json',p);return p
  elseif request.op=='submit'then
    local plan=sys.decode(root..'/plans/'..request.id..'.json');sys.need(plan,'INVALID_INPUT','Plan does not exist')
    local valid,message=pcall(contract.plan,plan,state.revision,os.time())
    sys.need(valid,'STALE_PLAN',tostring(message))
    sys.need(plan.catalog_revision==catalog.revision and plan.path==root,'STALE_PLAN','Catalog or root changed')
    local adapters=require('adapters')
    return tasks.start(ctx,plan,function(c,t,work,log)return adapters.install(c,t,work,log)end)
  elseif request.op=='cache-clear' or request.op=='remove' or request.op=='library-remove'then
    local lock='cleanup-'..sys.nixio.getpid();store.lock(ctx,{id=lock,boot=sys.boot_id()})
    local ok,result=pcall(function()
      if request.op=='cache-clear'then
        for _,name in ipairs(store.list(root..'/cache'))do
          sys.need(#name==64 and name:match('^[a-f0-9]+$'),'INTEGRITY','Unknown cache content; preserving it')
          sys.remove(root..'/cache/'..name)
        end
      elseif request.op=='library-remove'then
        for _,name in ipairs(store.list(root..'/environments'))do
          local r=sys.decode(root..'/environments/'..name..'/receipt.json');sys.need(r,'INTEGRITY','Unknown environment prevents library removal');contract.receipt(r)
          sys.need(r.library~=request.id,'BUSY','Installed environment references this library')
        end
        sys.remove(root..'/libraries/'..request.id)
      else
        local r=sys.decode(root..'/environments/'..request.id..'/receipt.json');sys.need(r,'INVALID_INPUT','Environment missing');contract.receipt(r)
        require('defaults').protect(ctx,r)
        require('registration').unregister(ctx,r)
        sys.remove(root..'/wrap/'..request.id);sys.remove(root..'/environments/'..request.id)
      end
      return {revision=store.bump(ctx)}
    end)
    store.unlock(ctx,lock);if not ok then error(result,0)end;return result
  end
  sys.fail('UNSUPPORTED','Operation not implemented')
end
if arg[1]=='exec'then
  local argv={};for i=4,#arg do argv[#argv+1]=arg[i]end
  local ok,err=pcall(function()require('execution').exec(os.getenv('MISE_RUNTIME_ROOT')or uci('mise.main.storage_root'),arg[2],arg[3]or'--shell',argv)end)
  io.stderr:write(type(err)=='table'and err.message or tostring(err));io.stderr:write('\n');os.exit(1)
end
local ok,value=pcall(function()
  sys.need(sys.nixio.getuid()==0,'INVALID_INPUT','Administrator privileges required')
  sys.need(arg[1]=='request' and arg[2]==nil,'INVALID_INPUT','Usage: mise-runtime request < request.json')
  local raw=io.read(1048577);sys.need(raw and #raw<=1048576,'INVALID_INPUT','Request too large')
  local request=sys.json.parse(raw);sys.need(type(request)=='table','INVALID_INPUT','Invalid JSON request')
  local valid,message=pcall(contract.request,request);sys.need(valid,'INVALID_INPUT',tostring(message))
  return dispatch(request)
end)
local response
if ok then response={schema_version=1,ok=true,value=value}
else response={schema_version=1,ok=false,error=type(value)=='table' and value or{code='INVALID_INPUT',message=tostring(value)}}end
io.write(wire.encode(response)..'\n');os.exit(ok and 0 or 1)
