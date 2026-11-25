-- AgentFlow owns its binding and agent packages; mise-runtime owns all SDKs.
local s=require('system')
local c=require('contract')
local store=require('store')
local fs,n=s.fs,s.nixio
local M={helper='/usr/libexec/agentflow-runtime'}
M.agents={
 {id='codexcli',package='@openai/codex',command='codex',version='0.153.4'},
 {id='claude-code',package='@anthropic-ai/claude-code',command='claude',version='2.1.331'},
 {id='opencode',package='opencode-ai',command='opencode',version='1.19.6'},
 {id='kimi',package='@moonshot-ai/kimi-code',command='kimi',version='2.7.3'},
 {id='reasonix',package='reasonix',command='reasonix',version='2.61.0'}
}
function M.need(ok,message)return s.need(ok,'AGENTFLOW_RUNTIME',message)end
function M.quote(v)return "'"..v:gsub("'","'\\''").."'"end
function M.uci(key)
 if key=='mise.main.storage_root'and n.getuid()~=0 then return require('active-root').current()end
 local rc,out=s.pipe_capture({'/sbin/uci','-q','get',key})
 return rc==0 and out:gsub('%s+$','')or''
end
function M.directory(base)
 local current=''
 for part in base:gmatch('[^/]+')do
  M.need(part~='.'and part~='..','Application path traversal is forbidden')
  current=current..'/'..part;local st=fs.lstat(current)
  M.need(not st or(st.type=='dir'and st.uid==0),'Application parent must be a protected root-owned directory')
  local sticky=st and current~=base and math.floor(st.modedec/1000)%2==1
  if st then M.need(sticky or(math.floor((math.floor(st.modedec/10)%10)/2)%2==0 and math.floor((st.modedec%10)/2)%2==0),'Application parent is writable by other users')end
 end
end
function M.base(value)
 local base=value or M.uci('agentflow.@agentflow[0].data_dir')
 M.need(type(base)=='string'and base:match('^/mnt/[^/]+/.+')and not base:find('[%c:]')and not base:find('//',1,true)and base:sub(-1)~='/','Choose an AgentFlow data directory on a persistent disk')
 M.directory(base)
 store.filesystem(base)
 local root=M.uci('mise.main.storage_root')
 if root~=''then M.need(base~=root and base:sub(1,#root+1)~=root..'/'and root:sub(1,#base+1)~=base..'/','Application data and runtime storage must be separate')end
 return base
end
function M.file(path)
 local st=fs.lstat(path)
 M.need(st and st.type=='reg'and st.uid==0 and math.floor((math.floor(st.modedec/10)%10)/2)%2==0 and math.floor((st.modedec%10)/2)%2==0,'Missing or unsafe managed file: '..path)
end
function M.sha(path)
 local program=fs.access('/usr/bin/sha256sum','x')and'/usr/bin/sha256sum'or'/bin/sha256sum'
 local rc,out=s.pipe_capture({program,path})
 M.need(rc==0 and out:match('^[a-f0-9]+'),'Cannot hash managed file')
 return out:match('^([a-f0-9]+)')
end
function M.home(base)
 local home=M.uci('mise.main.runtime_dir')
 if home==''then local root=M.uci('mise.main.storage_root');c.path(root);home=root..'/home'end
 c.path(home);M.directory(home);store.filesystem(home);return home
end
function M.policy(root)
 c.path(root);local catalog=s.decode('/usr/share/mise-runtime/catalog.json');local e
 for _,entry in ipairs(catalog.entries)do
  if entry.tool=='node'and entry.version=='24.22.1'and entry.npm=='11.19.1'and entry.build=='upstream1'and entry.abi=='glibc'and entry.arch==n.uname().machine then e=entry;break end
 end
 M.need(e and e.availability=='available','The tested GNU Node 24.22.1/npm 11.19.1 is not in the runtime catalog')
 local library=require('libraries').definition(e.arch,'r1').id
 return e,c.instance_id(e,nil,library),library
end
function M.binding(base,path)
 path=path or base..'/.runtime/runtime.json';M.file(path)
 local b=s.decode(path);M.need(b and b.schema_version==1 and b.provider=='mise-runtime','Invalid AgentFlow runtime binding')
 c.path(b.storage_root);c.key(b.instance);c.key(b.library)
 M.need(b.storage_root==M.uci('mise.main.storage_root'),'Runtime repository changed; restart AgentFlow or prepare its runtime')
 store.validate(b.storage_root)
 local sdk=b.storage_root..'/environments/'..b.instance;M.file(sdk..'/receipt.json')
 local r=s.decode(sdk..'/receipt.json');c.receipt(r)
 M.need(r.verified and r.root==b.storage_root and r.instance==b.instance and r.entry.tool=='node'and r.entry.abi=='glibc'and r.entry.arch==n.uname().machine,'The fixed GNU Node SDK is unavailable')
 M.need(r.artifact_set==b.artifact_set and r.library==b.library and M.sha(sdk..'/receipt.json')==b.receipt_sha256,'The fixed SDK receipt changed')
 M.file(b.storage_root..'/libraries/'..b.library..'/receipt.json')
 local lib=s.decode(b.storage_root..'/libraries/'..b.library..'/receipt.json')
 M.need(lib and lib.verified and lib.manifest_sha256==b.library_manifest_sha256,'The fixed GNU library receipt changed')
 return b,r,lib
end
function M.request(root,work,value)
 local id=tostring(n.getpid());local input=work..'/request-'..id;local output=work..'/response-'..id
 s.write(input,value)
 local rc=s.run({'/usr/sbin/mise-runtime','request'},{stdin=input,output=output,timeout=60,env={MISE_RUNTIME_ROOT=root}})
 local response=s.decode(output);fs.unlink(input);fs.unlink(output)
 M.need(rc==0 and response and response.ok,response and response.error and response.error.message or'Runtime request failed')
 return response.value
end
function M.pin(base,install,path)
 path=path or base..'/.runtime/runtime.json'
 if not install and fs.lstat(path)then return M.binding(base,path)end
 local root=M.uci('mise.main.storage_root');c.path(root);store.open(root)
 local e,id,library=M.policy(root);local previous
 if fs.lstat(path)then
  M.file(path);previous=s.decode(path)
  M.need(previous and previous.provider=='mise-runtime'and previous.schema_version==1,'Invalid existing runtime binding')
  c.key(previous.instance);c.key(previous.library);c.digest(previous.artifact_set)
  local found
  for _,candidate in ipairs(s.decode('/usr/share/mise-runtime/catalog.json').entries)do
   if candidate.tool=='node'and candidate.abi=='glibc'and candidate.arch==n.uname().machine and candidate.availability=='available'and c.instance_id(candidate,nil,previous.library)==previous.instance and candidate.artifact_set==previous.artifact_set then found=candidate;break end
  end
  M.need(found,'Original fixed SDK is no longer in the supported catalog')
  e=found;id=previous.instance;library=previous.library
 end
 local work=base..'/.runtime/work';s.mkdir(work,448)
 local receipt=root..'/environments/'..id..'/receipt.json'
 if install then
  local source=M.uci('mise.main.acceleration')=='0'and'origin'or'ks-cli'
  require('dependency-client').ensure(root,e.id,library,source,work,base..'/.runtime/runtime-task.json')
 else M.need(fs.lstat(receipt),'Prepare the fixed GNU Node environment first')end
 M.need(root==M.uci('mise.main.storage_root'),'Runtime repository changed during preparation; retry')
 require('active-root').publish(root)
 M.file(receipt);local r=s.decode(receipt);c.receipt(r);M.need(r.verified and r.instance==id,'Runtime is not verified')
 local lr=s.decode(root..'/libraries/'..library..'/receipt.json');M.need(lr and lr.verified,'GNU library is not verified')
 if previous then M.need(previous.library_manifest_sha256==lr.manifest_sha256,'Restored GNU library content differs from the fixed binding')end
 local b={schema_version=1,provider='mise-runtime',storage_root=root,instance=id,library=library,
  artifact_set=r.artifact_set,receipt_sha256=M.sha(receipt),library_manifest_sha256=lr.manifest_sha256}
 local candidate=work..'/binding-'..n.getpid()..'.json'
 s.write(candidate,b,420);M.binding(base,candidate)
 M.need(fs.rename(candidate,path),'Cannot activate prepared runtime binding')
 return M.binding(base,path)
end
function M.prepare(base)
 base=M.base(base);s.mkdir(base,493)
 for _,dir in ipairs({'/.runtime','/.runtime/bin','/.runtime/work','/.runtime/agents'})do s.mkdir(base..dir,dir=='/.runtime/bin'and 493 or 448)end
 local home=M.home(base);s.mkdir(home,448)
 for _,dir in ipairs({'.config','.cache','.local/share','.local/state'})do s.mkdir(home..'/'..dir,448)end
 for _,command in ipairs({'node','npm','npx','git'})do
  s.write(base..'/.runtime/bin/'..command,'#!/bin/sh\nexec '..M.helper..' '..command..' '..M.quote(base)..' "$@"\n',493)
 end
 for _,agent in ipairs(M.agents)do
  local script='#!/bin/sh\nexec '..M.helper..' exec '..M.quote(base)..' '..agent.id..' "$@"\n'
  local current=fs.realpath(base..'/.runtime/agents/'..agent.id..'/current')
  if current and current:sub(1,#(base..'/.runtime/agents/'..agent.id..'/releases/'))==base..'/.runtime/agents/'..agent.id..'/releases/'then
   M.file(current..'/receipt.json');local receipt=s.decode(current..'/receipt.json')
   M.need(receipt and receipt.verified and receipt.agent==agent.id,'Invalid active agent release')
   if not fs.lstat(current..'/command')then s.write(current..'/command',script,493)end
  end
  local target='../agents/'..agent.id..'/current/command';local path=base..'/.runtime/bin/'..agent.command
  local st=fs.lstat(path)
  if st and not(st.type=='lnk'and fs.readlink(path)==target)then
   M.need(st.type=='reg'and s.read(path)==script,'Unknown application command; refusing to replace it')
   M.need(fs.unlink(path),'Cannot replace an old managed command')
   st=nil
  end
  if not st then M.need(fs.symlink(target,path),'Cannot create agent command link')end
 end
 -- Preparing a service never downloads software or changes global versions.
 pcall(M.pin,base,false)
 return base
end
function M.exec(base,command,args,binding_path)
 local b=M.binding(base,binding_path);local home=M.home(base)
 if command=='npm'then
  local prefix=false;for _,v in ipairs(args)do if v=='--prefix'or v:match('^%-%-prefix=')then prefix=true end end
  if not prefix then table.insert(args,1,base..'/.runtime/npm');table.insert(args,1,'--prefix')end
 end
 n.setenv('HOME',home);n.setenv('ISTORE_RUNTIME_HOME',home);n.setenv('MISE_RUNTIME_ROOT',b.storage_root)
 local argv={'/usr/sbin/mise-runtime','exec',b.instance,command}
 for _,v in ipairs(args)do argv[#argv+1]=v end
 n.exec(unpack(argv));M.need(false,'Cannot execute fixed runtime')
end
function M.agent(id)
 for _,a in ipairs(M.agents)do if a.id==id then return a end end
 M.need(false,'Unsupported agent')
end
function M.alive(owner)
 local live=owner and s.process(owner.pid)
 -- taskd and interactive shells need not make this Lua process a session
 -- leader. PID/start/boot identity, rather than group leadership, owns a lock.
 return live and live.boot==owner.boot and live.start==owner.start and live.state~='Z'
end
return M
