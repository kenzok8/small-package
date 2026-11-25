local s=require('system')
local R=require('agentflow-runtime')
local fs,n=s.fs,s.nixio
local M={}
local function le(bytes,offset,count)
 local value=0;for i=count-1,0,-1 do value=value*256+(bytes:byte(offset+i+1)or 0)end;return value
end
function M.interpreter(path)
 local f=io.open(path,'rb');if not f then return end
 local h=f:read(64)
 if not h or #h<64 or h:sub(1,4)~='\127ELF'then f:close();return end
 R.need(h:byte(5)==2 and h:byte(6)==1,'Unsupported executable ELF format')
 local offset,size,count=le(h,32,8),le(h,54,2),le(h,56,2)
 if count==0 then f:close();return end
 R.need(size>=56 and size<=256 and count<=256 and offset<1048576,'Invalid executable program headers')
 for i=0,count-1 do
  f:seek('set',offset+i*size);local p=f:read(size)
  R.need(p and #p==size,'Truncated executable program headers')
  if le(p,0,4)==3 then
   local pos,length=le(p,8,8),le(p,32,8);R.need(length>0 and length<512 and pos<1048576,'Invalid ELF interpreter')
   f:seek('set',pos);local result=f:read(length);f:close();return result and result:gsub('%z+$','')
  end
 end
 f:close()
end
local function release(base,path)
 local prefix=base..'/.runtime/agents/'
 R.need(path:sub(1,#prefix)==prefix and path:match('/releases/[%w._-]+$')and fs.realpath(path)==path,'Invalid agent release path')
 R.base(path)
 return path
end
function M.patch_native(base,dir)
 -- Only application-owned GNU executables need a private loader. Shared SDKs,
 -- static/musl binaries and .node libraries are not rewritten.
 for name in fs.dir(dir)do if name~='.'and name~='..'then
  local path=dir..'/'..name;local st=fs.lstat(path)
  if st.type=='dir'then M.patch_native(base,path)
  elseif st.type=='reg'and not name:match('%.agentflow%-real$')then
   local interp=M.interpreter(path)
   if interp and interp:find('ld-linux',1,true)then
    R.need(not fs.lstat(path..'.agentflow-real'),'Native launcher collision')
    R.need(fs.rename(path,path..'.agentflow-real'),'Cannot reserve GNU agent executable')
    s.write(path,'#!/bin/sh\nexec '..R.helper..' native '..R.quote(base)..' '..R.quote(path..'.agentflow-real')..' "$@"\n',493)
   end
  end
 end end
end
function M.native(base,path,args)
 local actual=fs.realpath(path);R.need(actual==path,'Invalid native executable path')
 local rel=path:match('^(.-/releases/[%w._-]+)/');R.need(rel,'Native executable is outside an agent release');release(base,rel)
 R.file(path);require('libraries').elf(path,n.uname().machine)
 R.need((M.interpreter(path)or''):find('ld-linux',1,true),'Expected a GNU executable')
 local b=R.binding(base,rel..'/runtime.json');local home=R.home(base)
 local lib=b.storage_root..'/libraries/'..b.library
 local argv={'/usr/bin/env','-u','LD_LIBRARY_PATH','-u','LD_PRELOAD','HOME='..home,
  'XDG_CONFIG_HOME='..home..'/.config','XDG_CACHE_HOME='..home..'/.cache','XDG_DATA_HOME='..home..'/.local/share','XDG_STATE_HOME='..home..'/.local/state',
  'PATH='..base..'/.runtime/bin:/usr/sbin:/usr/bin:/sbin:/bin',lib..'/ld.so','--library-path',lib,path}
 for _,v in ipairs(args)do argv[#argv+1]=v end;n.exec(unpack(argv));R.need(false,'Cannot execute GNU agent')
end
function M.entry(base,dir,agent)
 release(base,dir)
 local root=dir..'/global/lib/node_modules/'..agent.package
 R.file(root..'/package.json');local pkg=s.decode(root..'/package.json')
 R.need(pkg and pkg.name==agent.package and type(pkg.version)=='string','Agent package metadata is invalid')
 local bin=type(pkg.bin)=='string'and pkg.bin or type(pkg.bin)=='table'and pkg.bin[agent.command]
 R.need(type(bin)=='string','Agent package does not provide its command')
 local path=fs.realpath(root..'/'..bin)
 R.need(path and path:sub(1,#dir+1)==dir..'/','Agent command is missing or escapes its release')
 return path,pkg
end
function M.finish(base,dir,agent)
 if agent.id~='opencode'then return false end
 -- Upstream probes host ldd (musl) and tries to install a musl package even
 -- when running inside our GNU Node. Select the already verified GNU optional
 -- package explicitly; use the conservative x64 CPU build when available.
 local arch=n.uname().machine=='x86_64'and'x64'or'arm64'
 local names=arch=='x64'and{'opencode-linux-x64-baseline','opencode-linux-x64'}or{'opencode-linux-arm64'}
 for _,name in ipairs(names)do
  for _,parent in ipairs({dir..'/global/lib/node_modules/opencode-ai/node_modules/',dir..'/global/lib/node_modules/'})do
   local path=parent..name..'/bin/opencode';local real=fs.realpath(path)
   if real and real:sub(1,#dir+1)==dir..'/'then
    local pkg=s.decode(parent..name..'/package.json');R.need(pkg and pkg.version==agent.version,'OpenCode optional package version differs')
    if arch=='x64'and name=='opencode-linux-x64' then
     R.need((s.read('/proc/cpuinfo')or''):find('avx2',1,true),'OpenCode baseline CPU package is required')
    end
    s.write(dir..'/global/lib/node_modules/opencode-ai/bin/opencode.exe',
     '#!/bin/sh\nexec '..R.quote(real)..' "$@"\n',493)
    return true
   end
  end
 end
 R.need(false,'GNU OpenCode binary package is missing')
end
function M.launch(base,dir,agent,args)
 local entry=M.entry(base,dir,agent);local f=assert(io.open(entry,'rb'));local h=f:read(128)or'';f:close()
 if entry:match('%.m?js$')or entry:match('%.cjs$')or h:match('^#![^\n]*node')then
  local argv={entry};for _,v in ipairs(args)do argv[#argv+1]=v end;return R.exec(base,'node',argv,dir..'/runtime.json')
 end
 local home=R.home(base)
 local argv={'/usr/bin/env','-u','LD_LIBRARY_PATH','-u','LD_PRELOAD','HOME='..home,
  'XDG_CONFIG_HOME='..home..'/.config','XDG_CACHE_HOME='..home..'/.cache','XDG_DATA_HOME='..home..'/.local/share','XDG_STATE_HOME='..home..'/.local/state',
  'PATH='..base..'/.runtime/bin:/usr/sbin:/usr/bin:/sbin:/bin',entry}
 for _,v in ipairs(args)do argv[#argv+1]=v end;n.exec(unpack(argv));R.need(false,'Cannot execute agent command')
end
function M.current(base,agent)
 local path=fs.realpath(base..'/.runtime/agents/'..agent.id..'/current')
 R.need(path,'Agent is not installed in the shared runtime integration')
 release(base,path);R.file(path..'/receipt.json')
 local receipt=s.decode(path..'/receipt.json')
 R.need(receipt and receipt.schema_version==1 and receipt.agent==agent.id and receipt.verified,'Agent release is not verified')
 R.binding(base,path..'/runtime.json')
 return path,receipt
end
function M.prepare_runtime(base)
 base=R.prepare(base)
 R.need(not fs.lstat(base..'/.runtime/.install-lock'),'Finish or recover the agent installation before restarting')
 local prepared={}
 local function pin(path)
  local b=s.decode(path)
  local key=b and b.instance
  if key and prepared[key]then
   R.file(path);R.need(b.artifact_set==prepared[key].artifact_set and b.library==prepared[key].library and b.library_manifest_sha256==prepared[key].library_manifest_sha256,'Agent runtime identity differs')
   s.write(path,prepared[key],420);R.binding(base,path)
  else local fresh=R.pin(base,true,path);prepared[fresh.instance]=fresh end
 end
 if fs.lstat(base..'/.runtime/runtime.json')then pin(base..'/.runtime/runtime.json')end
 for _,agent in ipairs(R.agents)do
  local dir=fs.realpath(base..'/.runtime/agents/'..agent.id..'/current')
  if dir then release(base,dir);pin(dir..'/runtime.json')end
 end
 return {prepared=true,storage_root=R.uci('mise.main.storage_root')}
end
function M.install(base,id)
 local agent=R.agent(id);base=R.prepare(base);local manager=base..'/.runtime'
 R.need(fs.mkdir(manager..'/.install-lock','700'),'Another install is active or interrupted; inspect the AgentFlow task before retrying')
 s.write(manager..'/.install-lock/owner.json',{schema_version=1,process=s.process(n.getpid())})
 local dir=manager..'/agents/'..id..'/releases/'..s.identifier('install')
 local ok,result=pcall(function()
  R.pin(base,true);s.mkdir(dir,448)
  s.write(dir..'/runtime.json',s.decode(manager..'/runtime.json'),420)
  local global=dir..'/global';s.mkdir(global,448)
  local function npm(args)
   local argv={R.helper,'npm',base,'--prefix',global}
   for _,v in ipairs(args)do argv[#argv+1]=v end
   R.need(s.run(argv,{cwd=dir,output=dir..'/install.log',append=true,timeout=1200})==0,'Agent package install failed; inspect '..dir..'/install.log')
  end
  print('Installing '..agent.package..'@'..agent.version..' with fixed shared GNU Node');io.stdout:flush()
  -- Leave registry selection to the shared wrapper/ks-cli. A command-line
  -- --registry would override ks-cli's injected gateway environment.
  npm({'install','--global',agent.package..'@'..agent.version,'--ignore-scripts','--no-audit','--no-fund'})
  M.patch_native(base,global)
  if not M.finish(base,dir,agent)then npm({'rebuild','--global',agent.package})end
  M.patch_native(base,global)
  local entry,pkg=M.entry(base,dir,agent);R.need(pkg.version==agent.version,'Agent package version differs from policy')
  R.need(s.run({R.helper,'probe',base,dir,id,'--version'},
   {cwd=dir,output=dir..'/version.log',timeout=20})==0,'Installed agent failed its actual version probe; previous release remains active')
  local version=s.read(dir..'/version.log')or'';R.need(version:find(agent.version,1,true),'Agent command did not report the installed version')
  local b=R.binding(base,dir..'/runtime.json')
  local receipt={schema_version=1,agent=id,package=agent.package,version=pkg.version,instance=b.instance,verified=true,installed_at=os.time()}
  s.write(dir..'/receipt.json',receipt,420)
  s.write(dir..'/command','#!/bin/sh\nexec '..R.helper..' exec '..R.quote(base)..' '..agent.id..' "$@"\n',493)
  R.need(s.run({'chmod','-R','go-w',dir},{timeout=60})==0,'Cannot protect agent release')
  local parent=manager..'/agents/'..id;local next=parent..'/current.new.'..n.getpid()
  R.need(fs.symlink(dir,next)and fs.rename(next,parent..'/current'),'Cannot activate agent release')
  return receipt
 end)
 fs.unlink(manager..'/.install-lock/owner.json');fs.rmdir(manager..'/.install-lock')
 if not ok then error(result,0)end;return result
end
function M.recover(base)
 base=R.base(base);local manager=base..'/.runtime';local lock=manager..'/.install-lock'
 if not fs.lstat(lock)then return {recovered=false}end
 R.file(lock..'/owner.json');local owner=s.decode(lock..'/owner.json')
 R.need(owner and owner.schema_version==1 and owner.process,'Unknown install lock; preserve it for inspection')
 R.need(not R.alive(owner.process),'An install task is still running')
 local journal=s.decode(manager..'/runtime-task.json')
 if journal then
  require('contract').path(journal.root);require('contract').key(journal.plan)
  for _,id in ipairs(require('store').list(journal.root..'/tasks'))do
   local t=s.decode(journal.root..'/tasks/'..id..'/task.json')
   if t and t.plan and t.plan.id==journal.plan and(t.status=='running'or t.status=='interrupted')then
    R.request(journal.root,manager..'/work',{op=t.status=='running'and'cancel'or'recover',id=id})
   end
  end
  fs.unlink(manager..'/runtime-task.json')
 end
 R.need(fs.unlink(lock..'/owner.json')and fs.rmdir(lock),'Cannot recover the install lock')
 return {recovered=true}
end
function M.status(base)
 local result={agents=require('wire').array(),runtime={ready=false},agents_available=false}
 local configured,err=pcall(function()
  base=R.base(base);R.home(base)
  local root=R.uci('mise.main.storage_root');require('contract').path(root);require('store').validate(root)
  result.agents_available=true
 end)
 if not configured then result.runtime.error=type(err)=='table'and err.message or tostring(err);return result end
 local ready,b,r,lib=pcall(R.binding,base)
 if ready then result.runtime={ready=true,provider='mise-runtime',node=r.entry.version,npm=r.npm,abi=r.entry.abi,glibc=lib.version,instance=b.instance,home=R.home(base)}
 else result.runtime.error=type(b)=='table'and b.message or tostring(b)end
 local owner=s.decode(base..'/.runtime/.install-lock/owner.json')
 result.runtime.interrupted=owner and owner.process and not R.alive(owner.process)or false
 for _,agent in ipairs(R.agents)do
  local item={id=agent.id,installed=false}
  local ok,dir,receipt=pcall(M.current,base,agent)
  if ok then
   local work=base..'/.runtime/work';local out=work..'/version-'..agent.id..'-'..n.getpid()
   local rc=s.run({R.helper,'exec',base,agent.id,'--version'},{output=out,timeout=5})
   local version=s.read(out)or'';fs.unlink(out)
   if rc==0 and version:find(receipt.version,1,true)then item.installed=true;item.version=receipt.version end
  end
  result.agents[#result.agents+1]=item
 end
 return result
end
return M
