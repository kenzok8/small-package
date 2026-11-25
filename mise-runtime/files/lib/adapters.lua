local sys=require('system')
local store=require('store')
local contract=require('contract')
local artifacts=require('artifacts')
local libraries=require('libraries')
local tasks=require('tasks')
local registration=require('registration')
local fs=sys.fs
local M={enabled={node=true,python=true,go=true,zig=true}}
local function quote(value)return "'"..value:gsub("'","'\\''").."'"end
local function launcher(ctx,id,command)
  return '#!/bin/sh\nset -eu\numask 077\nexec /usr/bin/lua '..quote(ctx.share..'/execute.lua')..' '..quote(ctx.root)..' '..quote(id)..' '..(command and quote(command)..' 'or'')..'"$@"\n'
end
M.launcher=launcher
function M.publish(ctx,t)
  local p=t.publication;contract.key(p.instance)
  sys.need(t.pending_environment and p.instance==t.pending_environment.id,'INTEGRITY','Publication candidate differs')
  local sdk=ctx.root..'/environments/'..p.instance
  local st=fs.lstat(sdk);sys.need(st and st.ino==t.pending_environment.inode,'INTEGRITY','Publication candidate ownership changed')
  local r=sys.decode(sdk..'/receipt.json');contract.receipt(r)
  sys.need(r.verified and r.instance==p.instance,'PROBE_FAILED','Publication is not verified')
  sys.need(p.wrap==launcher(ctx,p.instance),'INTEGRITY','Publication wrap differs from manager contract')
  sys.write(ctx.root..'/wrap/'..p.instance,p.wrap,493)
end
function M.install(ctx,t,work,log)
  require('network').refresh(ctx)
  local entry
  for _,e in ipairs(ctx.catalog.entries)do if e.id==t.plan.entry then entry=e;break end end
  sys.need(entry and M.enabled[entry.tool],'UNSUPPORTED','Adapter unavailable')
  contract.entry(entry)
  if entry.tool=='python'then return require('python').install(ctx,t,entry,work,log)end
  if entry.tool=='go'or entry.tool=='zig'then return require('native').install(ctx,t,entry,work,log)end
  local library
  if entry.abi=='glibc'then
    tasks.phase(ctx,t,'library')
    local definition=t.plan.library and require('dependencies').library(t.plan.library,entry.arch)or libraries.definition(entry.arch)
    library=libraries.ensure(ctx,definition,t.plan.source,work,log,ctx.download_options).id
  end
  local id=contract.instance_id(entry,nil,library)
  sys.need(id==t.plan.instance,'STALE_PLAN','Resolved instance differs from plan')
  local sdk=ctx.root..'/environments/'..id
  sys.need(not fs.lstat(sdk),'BUSY','Environment already exists')
  sys.mkdir(sdk,448);t.pending_environment={id=id,inode=fs.lstat(sdk).ino};tasks.phase(ctx,t,'download')
  local archive=artifacts.download(ctx,entry.artifacts[1],t.plan.source,work,log,ctx.download_options)
  tasks.phase(ctx,t,'extract')
  artifacts.extract(archive,entry.artifacts[1],sdk..'/payload',work,log)
  for _,name in ipairs(store.list(sdk..'/payload'))do sys.need(fs.rename(sdk..'/payload/'..name,sdk..'/'..name),'OFFLINE','Cannot stage SDK layout')end
  sys.need(fs.rmdir(sdk..'/payload'),'OFFLINE','Cannot remove empty payload')
  if entry.artifacts[2]then
    local a=entry.artifacts[2];sys.need(a.component=='npm','INTEGRITY','Unexpected Node component')
    local npm=artifacts.download(ctx,a,t.plan.source,work,log,ctx.download_options)
    sys.remove(sdk..'/lib/node_modules/npm')
    artifacts.extract(npm,a,sdk..'/lib/node_modules/npm',work,log)
  end
  libraries.elf(sdk..'/bin/node',entry.arch)
  sys.need(fs.rename(sdk..'/bin/node',sdk..'/bin/node.real'),'OFFLINE','Cannot reserve native Node')
  sys.mkdir(sdk..'/native/bin',493)
  for _,command in ipairs({'node','npm','npx','git'})do
    local path=sdk..'/bin/'..command
    if fs.lstat(path)then sys.remove(path)end
    sys.write(path,launcher(ctx,id,command),493)
  end
  sys.write(sdk..'/native/bin/npm','#!/bin/sh\nexec '..quote(sdk..'/bin/node')..' '..quote(sdk..'/lib/node_modules/npm/bin/npm-cli.js')..' "$@"\n',493)
  sys.need(fs.symlink('/usr/bin/git',sdk..'/native/bin/git'),'OFFLINE','Cannot prepare native Git entry')
  sys.write(sdk..'/node-loader.cjs',assert(sys.read(ctx.share..'/node-loader.cjs')),420)
  local r={schema_version=1,instance=id,entry=entry,npm=entry.npm,library=library,artifact_set=entry.artifact_set,
    installed_at=os.time(),verified=false,probes={},mise_key='istore-'..id,root=ctx.root}
  sys.write(sdk..'/receipt.json',r,420)
  -- The final SDK path is reserved from the start: launchers/embedded prefixes
  -- are probed in place, never moved to a different installation prefix.
  sys.need(sys.run({'chmod','-R','a+rX,go-w',sdk},{output=log,append=true})==0,'OFFLINE','Cannot protect SDK files')
  tasks.phase(ctx,t,'probe')
  local env={MISE_RUNTIME_PROBE=t.id,ISTORE_RUNTIME_ACCELERATION='origin'}
  local function probe(command,args)
    local argv={sdk..'/bin/'..command};for _,value in ipairs(args)do argv[#argv+1]=value end
    local path=work..'/probe-output'
    sys.need(sys.run(argv,{cwd=sdk,env=env,output=path,timeout=45})==0,'PROBE_FAILED','Node '..command..' probe failed: '..(sys.read(path)or''))
    return(sys.read(path)or''):gsub('%s+$','')
  end
  sys.need(probe('node',{'--version'})=='v'..entry.version,'PROBE_FAILED','Node version differs from catalog')
  local js="const n=require('./lib/node_modules/npm/package.json');const s=require('./lib/node_modules/npm/node_modules/semver');if(!s.satisfies(process.versions.node,n.engines.node)){console.error('npm engines '+n.engines.node+' rejects Node '+process.versions.node);process.exit(8);}const h=process.report.getReport().header;console.log(JSON.stringify({arch:process.arch,glibc:h.glibcVersionRuntime||null,execPath:process.execPath}));"
  local report=sys.json.parse(probe('node',{'-e',js}))
  sys.need(report and report.arch==(entry.arch=='x86_64'and'x64'or'arm64'),'PROBE_FAILED','Node architecture differs')
  sys.need((entry.abi=='glibc')==(report.glibc~=nil),'PROBE_FAILED','Node libc differs')
  sys.need(report.execPath==sdk..'/bin/node'or(entry.abi=='musl'and report.execPath==sdk..'/bin/node.real'),'PROBE_FAILED','Node execPath is not fixed')
  sys.need(probe('npm',{'--version'})==entry.npm,'PROBE_FAILED','npm version differs from catalog')
  r.probes={version='passed',arch='passed',abi='passed',launcher='passed',npm='passed',engines='passed'}
  r.verified=true;sys.write(sdk..'/receipt.json',r,420)
  tasks.phase(ctx,t,'registration');registration.register(ctx,r,work,log)
  t.publication={instance=id,wrap=launcher(ctx,id)};tasks.save(ctx,t)
  store.bump(ctx)
  return r
end
return M
