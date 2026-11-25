local sys=require('system')
local store=require('store')
local contract=require('contract')
local tasks=require('tasks')
local wire=require('wire')
local M={}
local function uci(key)
  local rc,value=sys.pipe_capture({'/sbin/uci','-q','get',key})
  return rc==0 and value:gsub('%s+$','')or''
end
function M.empty(catalog,path)
  local paths,recommended=require('storage-paths').discover(path,uci('quickstart.@main[0].conf_dir'))
  local r={schema_version=1,revision=0,catalog_revision=catalog.revision,arch=sys.nixio.uname().machine,path=path or'',managed_home=uci('mise.main.runtime_dir')~=''and uci('mise.main.runtime_dir')or(path and path~=''and path..'/home'or''),online=false,
    storage_paths=paths,storage_default=recommended,storage_locked=false,
    runtimes=wire.array(),libraries=wire.array(),tasks=wire.array(),warnings=wire.array(),defaults={},defaults_known={},default_pins={},default_paths={},capabilities={},
    free_bytes=wire.null,free_inodes=wire.null,cache_bytes=wire.null,measurements={},library_references={},acceleration=uci('mise.main.acceleration')~='0',gateway=false}
  local ok,adapters=pcall(require,'adapters')
  for tool in pairs(contract.tools)do
    r.defaults[tool]=wire.null;r.defaults_known[tool]=false
    local enabled=ok and adapters.enabled[tool]==true or false
    r.capabilities[tool]={enabled=enabled,reason=not enabled and'此语言的设备适配尚未启用'or nil}
  end
  local port=tonumber(uci('istoreenhance.@istoreenhance[0].adminport'))or 5003
  if port>0 and port<65536 and port%1==0 then
    -- nixio.exec() does not search PATH. A relative curl made every healthy
    -- backend look unavailable and disabled accelerated installs in the UI.
    local rc=sys.pipe_capture({'/usr/bin/curl','--disable','-fsS','--noproxy','*','--max-time','1','-o','/dev/null','http://127.0.0.1:'..port..'/api/download-gateway/routes'})
    r.gateway=rc==0
  end
  local lib=require('libraries').definition(r.arch);r.default_library=lib.id
  return r
end
local function bytes(path)
  local st=sys.fs.lstat(path);if not st then return 0 end
  if st.type=='reg'then return st.size end
  if st.type~='dir'then return 0 end
  local total=0
  for _,name in ipairs(store.list(path))do total=total+bytes(path..'/'..name)end
  return total
end
local function tail(path)
  local f=io.open(path,'rb');if not f then return''end
  local size=f:seek('end');f:seek('set',math.max(0,size-16384));local value=f:read(16384)or'';f:close();return value
end
function M.read(ctx,catalog)
  local r=M.empty(catalog,ctx.root)
  r.online=true;r.revision=store.state(ctx).revision;r.free_bytes=ctx.storage.free_bytes;r.free_inodes=ctx.storage.free_inodes
  r.storage_locked=sys.fs.lstat(ctx.root..'/.lock')~=nil
  local policy=sys.decode(ctx.root..'/network/settings.json');if policy then r.acceleration=policy.acceleration end
  local d=require('defaults').read(ctx);r.defaults_known=d.known;r.default_pins=d.pins;r.default_paths=d.paths
  for tool in pairs(contract.tools)do r.defaults[tool]=d.values[tool]or wire.null end
  for _,id in ipairs(store.list(ctx.root..'/environments'))do
    local ok,receipt=pcall(sys.decode,ctx.root..'/environments/'..id..'/receipt.json')
    if ok and receipt and pcall(contract.receipt,receipt)and sys.fs.access(ctx.root..'/wrap/'..id,'x')then
      r.runtimes[#r.runtimes+1]=receipt
      local measured,size=pcall(bytes,ctx.root..'/environments/'..id)
      r.measurements[id]={size_bytes=measured and size or wire.null}
      if receipt.library then r.library_references[receipt.library]=(r.library_references[receipt.library]or 0)+1 end
    end
  end
  for _,id in ipairs(store.list(ctx.root..'/libraries'))do
    local ok,receipt=pcall(sys.decode,ctx.root..'/libraries/'..id..'/receipt.json')
    if ok and receipt then r.libraries[#r.libraries+1]=receipt end
  end
  local present={};for _,lib in ipairs(r.libraries)do present[lib.id]=true end
  for id in pairs(r.library_references)do if not present[id]then
    local ok,d=pcall(require('dependencies').library,id,r.arch)
    if ok then r.libraries[#r.libraries+1]={schema_version=1,id=id,arch=d.arch,version=d.version,revision=d.revision,verified=false,missing=true}end
  end end
  local ids=store.list(ctx.root..'/tasks');local all={}
  for _,id in ipairs(ids)do
    local ok,t=pcall(tasks.get,ctx,id)
    if ok and t then all[#all+1]=t else r.warnings[#r.warnings+1]='有无法读取的任务记录：'..id end
  end
  table.sort(all,function(a,b)return(a.started or 0)>(b.started or 0)end)
  for i,t in ipairs(all)do
    if i<=32 or t.status=='running'or t.status=='interrupted'then
      if t.status=='running'and not sys.alive(t.owner)then t.status='interrupted'end
      t.logs=wire.array({tail(ctx.root..'/tasks/'..t.id..'/log')});r.tasks[#r.tasks+1]=t
    end
  end
  r.cache_bytes=bytes(ctx.root..'/cache')
  return r
end
return M
