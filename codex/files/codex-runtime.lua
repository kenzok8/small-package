-- Codex owns its package, state and workspace; mise-runtime owns the SDK.
local s=require('system')
local c=require('contract')
local store=require('store')
local fs,n=s.fs,s.nixio
local M={helper='/usr/libexec/codex-runtime',package='@openai/codex',command='codex',version='0.172.0'}

function M.need(ok,message)return s.need(ok,'CODEX_RUNTIME',message)end
function M.quote(v)return "'"..v:gsub("'","'\\''").."'"end

function M.uci(key)
 if key=='mise.main.storage_root'and n.getuid()~=0 then return require('active-root').current()end
 local rc,out=s.pipe_capture({'/sbin/uci','-q','get',key})
 return rc==0 and out:gsub('%s+$','')or''
end

function M.account()
 local lookup=n.getpwnam or n.getpw
 local user=lookup and lookup('codex')
 M.need(user and user.uid and user.gid and user.uid>0,'The dedicated codex account is missing')
 return user.uid,user.gid
end

function M.directory(path,owner)
 local current=''
 for part in path:gmatch('[^/]+')do
  M.need(part~='.'and part~='..','Path traversal is forbidden')
  current=current..'/'..part
  local st=fs.lstat(current)
  M.need(not st or st.type=='dir','Path contains a symlink or non-directory')
  if st then
   M.need(st.uid==0 or(owner and st.uid==owner),'Path belongs to another account')
   local group_write=math.floor((math.floor(st.modedec/10)%10)/2)%2==1
   local other_write=math.floor((st.modedec%10)/2)%2==1
   local sticky=current~=path and st.uid==0 and math.floor(st.modedec/1000)%2==1
   M.need(not(group_write or other_write)or sticky,'Path parent is writable by another account')
  end
 end
end

function M.base(value)
 local base=value
 if type(base)~='string'or base==''then base=n.getenv('CODEX_DATA_DIR')or''end
 if base==''then base=M.uci('codex.main.data_dir')end
 c.path(base);M.directory(base)
 local root=M.uci('mise.main.storage_root')
 if root~=''then
  c.path(root)
  M.need(base~=root and base:sub(1,#root+1)~=root..'/'and root:sub(1,#base+1)~=base..'/','Codex data and runtime storage must be separate')
 end
 return base
end

function M.workspace(base,value)
 local uid=M.account()
 local path=value
 if type(path)~='string'or path==''then path=n.getenv('CODEX_WORKSPACE_DIR')or''end
 if path==''then path=M.uci('codex.main.workspace_dir')end
 if path==''then path=base..'/workspace'end
 c.path(path);M.directory(path,uid)
 local st=fs.lstat(path)
 M.need(st and st.type=='dir'and st.uid==uid,'Workspace must exist and belong to the codex account')
 return path
end

function M.home(base)
 local uid=M.account();local home=base..'/home'
 c.path(home);M.directory(home,uid)
 local st=fs.lstat(home)
 M.need(st and st.type=='dir'and st.uid==uid,'Codex HOME is missing or has unsafe ownership')
 return home
end

function M.orchestrator_home()
	if n.getuid() ~= 0 or n.getenv('AGENTFLOW_PROVIDER_MODE') ~= '1' then return nil end
	local home = n.getenv('HOME') or ''
	c.path(home);M.directory(home)
	local st = fs.lstat(home)
	local group_write = st and math.floor((math.floor(st.modedec / 10) % 10) / 2) % 2 == 1
	local other_write = st and math.floor((st.modedec % 10) / 2) % 2 == 1
	M.need(st and st.type == 'dir' and st.uid == 0 and not group_write and not other_write,
		'AgentFlow HOME is missing or has unsafe ownership')
	local codex_home = home .. '/.codex'
	if not fs.lstat(codex_home) then s.mkdir(codex_home,448) end
	M.directory(codex_home)
	local codex_st = fs.lstat(codex_home)
	M.need(codex_st and codex_st.type == 'dir' and codex_st.uid == 0,
		'AgentFlow Codex home is missing or has unsafe ownership')
	return home
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

function M.policy()
 local catalog=s.decode('/usr/share/mise-runtime/catalog.json');local entry
 for _,candidate in ipairs(catalog.entries)do
  if candidate.tool=='node'and candidate.version=='24.22.1'and candidate.npm=='11.19.1'and
   candidate.build=='upstream1'and candidate.abi=='musl'and candidate.arch==n.uname().machine then entry=candidate;break end
 end
 M.need(entry and entry.availability=='available','The tested musl Node 24.22.1/npm 11.19.1 is not in the runtime catalog')
 return entry,c.instance_id(entry,nil,nil)
end

function M.binding(base,path)
 path=path or base..'/.runtime/runtime.json';M.file(path)
 local binding=s.decode(path)
 M.need(binding and binding.schema_version==1 and binding.provider=='mise-runtime','Invalid Codex runtime binding')
 c.path(binding.storage_root);c.key(binding.instance);c.digest(binding.artifact_set);c.digest(binding.receipt_sha256)
 M.need(binding.storage_root==M.uci('mise.main.storage_root'),'Runtime repository changed; prepare Codex again')
 store.validate(binding.storage_root)
 local sdk=binding.storage_root..'/environments/'..binding.instance
 M.file(sdk..'/receipt.json')
 local receipt=s.decode(sdk..'/receipt.json');c.receipt(receipt)
 M.need(receipt.verified and receipt.root==binding.storage_root and receipt.instance==binding.instance and
  receipt.entry.tool=='node'and receipt.entry.abi=='musl'and receipt.entry.arch==n.uname().machine,'The fixed musl Node SDK is unavailable')
 M.need(receipt.library==nil and receipt.artifact_set==binding.artifact_set and M.sha(sdk..'/receipt.json')==binding.receipt_sha256,'The fixed SDK receipt changed')
 return binding,receipt
end

function M.pin(base,install,path)
 path=path or base..'/.runtime/runtime.json'
 if not install and fs.lstat(path)then return M.binding(base,path)end
 local root=M.uci('mise.main.storage_root');c.path(root);store.open(root)
 local entry,id=M.policy();local previous
 if fs.lstat(path)then
  M.file(path);previous=s.decode(path)
  M.need(previous and previous.provider=='mise-runtime'and previous.schema_version==1,'Invalid existing runtime binding')
  c.key(previous.instance);c.digest(previous.artifact_set)
  local found
  for _,candidate in ipairs(s.decode('/usr/share/mise-runtime/catalog.json').entries)do
   if candidate.tool=='node'and candidate.abi=='musl'and candidate.arch==n.uname().machine and
    candidate.availability=='available'and c.instance_id(candidate,nil,nil)==previous.instance and
    candidate.artifact_set==previous.artifact_set then found=candidate;break end
  end
  M.need(found,'Original fixed SDK is no longer in the supported catalog')
  entry=found;id=previous.instance
 end
 local work=base..'/.runtime/work';s.mkdir(work,448)
 local receipt=root..'/environments/'..id..'/receipt.json'
 if install then
  local source=M.uci('mise.main.acceleration')=='0'and'origin'or'ks-cli'
  require('dependency-client').ensure(root,entry.id,nil,source,work,base..'/.runtime/runtime-task.json')
 else M.need(fs.lstat(receipt),'Prepare the fixed Node environment first')end
 M.need(root==M.uci('mise.main.storage_root'),'Runtime repository changed during preparation; retry')
 require('active-root').publish(root)
 M.file(receipt);local actual=s.decode(receipt);c.receipt(actual)
 M.need(actual.verified and actual.instance==id and actual.library==nil,'Runtime is not verified')
 local binding={schema_version=1,provider='mise-runtime',storage_root=root,instance=id,
  artifact_set=actual.artifact_set,receipt_sha256=M.sha(receipt)}
 local candidate=work..'/binding-'..n.getpid()..'.json'
 s.write(candidate,binding,420);M.binding(base,candidate)
 M.need(fs.rename(candidate,path),'Cannot activate prepared runtime binding')
 return M.binding(base,path)
end

local function owned_dir(path,uid,gid,mode)
 local st=fs.lstat(path)
 if not st then s.mkdir(path,mode);st=fs.lstat(path)end
 M.need(st and st.type=='dir','Cannot prepare application directory: '..path)
 if st.uid==0 then M.need(fs.chown(path,uid,gid),'Cannot assign Codex application directory')
 else M.need(st.uid==uid,'Application directory belongs to another account')end
 M.need(fs.chmod(path,string.format('%o',mode)),'Cannot protect Codex application directory')
end

function M.prepare(value)
 local base=M.base(value);local uid,gid=M.account()
 s.mkdir(base,493);store.filesystem(base)
 for _,item in ipairs({{path='/.runtime',mode=493},{path='/.runtime/releases',mode=493},{path='/.runtime/work',mode=448},{path='/.runtime/installer-home',mode=448}})do
  s.mkdir(base..item.path,item.mode);M.need(fs.chmod(base..item.path,string.format('%o',item.mode)),'Cannot protect managed directory')
 end
 owned_dir(base..'/home',uid,gid,448)
 local workspace=M.uci('codex.main.workspace_dir')
 if workspace==''then workspace=base..'/workspace'end
 c.path(workspace);M.directory(workspace,uid)
 if not fs.lstat(workspace)then s.mkdir(workspace,488)end
 owned_dir(workspace,uid,gid,488)
 for _,path in ipairs({'/.codex','/.config','/.cache','/.local','/.local/share','/.local/state'})do owned_dir(base..'/home'..path,uid,gid,448)end
 pcall(M.pin,base,false)
 return base
end

function M.exec_admin(base,command,args,binding_path)
 local binding=M.binding(base,binding_path)
 n.setenv('MISE_RUNTIME_ROOT',binding.storage_root)
 n.setenv('ISTORE_RUNTIME_HOME',base..'/.runtime/installer-home')
 local argv={'/usr/sbin/mise-runtime','exec',binding.instance,command}
 for _,value in ipairs(args or{})do argv[#argv+1]=value end
 n.exec(unpack(argv));M.need(false,'Cannot execute fixed runtime')
end

function M.alive(owner)
 local live=owner and s.process(owner.pid)
 return live and live.boot==owner.boot and live.start==owner.start and live.state~='Z'
end

return M
