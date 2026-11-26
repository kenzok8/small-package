#!/usr/bin/lua
-- Hermes owns releases and venvs; mise-runtime owns the fixed Python SDK.
package.path='/usr/share/mise-runtime/lib/?.lua;'..package.path
local s=require('system')
local c=require('contract')
local store=require('store')
local fs,n=s.fs,s.nixio
local share=assert(arg[0]:match('^(.*)/[^/]+$'))

local function need(value,message)return s.need(value,'HERMES_RUNTIME',message)end
local function writable(st)
  return math.floor((math.floor(st.modedec/10)%10)/2)%2==1 or math.floor((st.modedec%10)/2)%2==1
end
local function app_path(path)
  need(type(path)=='string'and path:sub(1,5)=='/mnt/'and not path:find('[%c:]')and
    not path:find('//',1,true)and path:sub(-1)~='/','Use a normalized Hermes path on a persistent /mnt disk')
  local current=''
  for part in path:gmatch('[^/]+')do
    need(part~='.'and part~='..','Hermes path traversal is forbidden')
    current=current..'/'..part
    local st=fs.lstat(current)
    local sticky=st and current~=path and st.uid==0 and math.floor(st.modedec/1000)%2==1
    need(not st or(st.type=='dir'and(st.uid==0 or current==path)and(not writable(st)or sticky)),
      'Hermes path contains an unsafe directory: '..current)
  end
  return store.filesystem(path)
end
local function protected(path)
  local st=fs.lstat(path)
  need(st and st.type=='reg'and st.uid==0 and not writable(st),'Missing or writable Hermes binding: '..path)
end
local function uci(key)
  if key=='mise.main.storage_root'and n.getuid()~=0 then return require('active-root').current()end
  local rc,out=s.pipe_capture({'/sbin/uci','-q','get',key})
  return rc==0 and out:gsub('%s+$','')or''
end
local function account()
  local user=n.getpw('hermes')
  need(user and user.uid and user.gid and user.uid>0,'Install the dedicated hermes user first')
  return user.uid,user.gid
end
local function preflight(base)
  local storage=app_path(base)
  need(base~=storage.mount.point,'Use a Hermes subdirectory, not the disk mount root')
  need(not fs.lstat(base..'/.storage.json'),'Hermes data cannot be a mise storage root')
  local root=uci('mise.main.storage_root')
  need(root~='','Configure Runtime Environments storage first')
  root=fs.realpath(root)or root;c.path(root)
  need(base~=root and base:sub(1,#root+1)~=root..'/'and root:sub(1,#base+1)~=base..'/',
    'Hermes and shared runtime directories must not contain each other')
  return root
end
local function request(work,value,root)
  c.path(root);s.mkdir(work,448)
  local input=work..'/request.json';local output=work..'/response.json'
  s.write(input,value)
  local rc=s.run({'/usr/sbin/mise-runtime','request'},{stdin=input,output=output,timeout=60,env={MISE_RUNTIME_ROOT=root}})
  local response=s.decode(output);fs.unlink(input);fs.unlink(output)
  need(rc==0 and response and response.ok,response and response.error and response.error.message or'Runtime request failed')
  return response.value
end
local function binding(path)
  path=need(fs.realpath(path),'Hermes runtime binding is missing');protected(path)
  local release=need(path:match('^(.*)/runtime.json$'),'Invalid Hermes binding path');app_path(release)
  local b=need(s.decode(path),'Invalid Hermes runtime binding')
  need(b.schema_version==1 and b.provider=='mise-runtime'and b.tool=='python','Unsupported Hermes runtime binding')
  c.path(b.storage_root);c.key(b.instance);c.digest(b.artifact_set);c.digest(b.receipt_sha256)
  need(b.storage_root==uci('mise.main.storage_root'),'Runtime repository changed; prepare Hermes again')
  store.validate(b.storage_root)
  local receipt_path=b.storage_root..'/environments/'..b.instance..'/receipt.json';protected(receipt_path)
  local r=need(s.decode(receipt_path),'Fixed Python receipt is missing');c.receipt(r)
  need(r.verified and r.root==b.storage_root and r.instance==b.instance and r.entry.tool=='python',
    'Fixed Python is unavailable or unverified')
  need(r.entry.arch==n.uname().machine and r.entry.version==b.python and r.entry.abi==b.abi and
    r.artifact_set==b.artifact_set,'Hermes binding no longer matches its Python SDK')
  local rc,out=s.pipe_capture({'/usr/bin/sha256sum',receipt_path})
  need(rc==0 and out:match('^([a-f0-9]+)')==b.receipt_sha256,'Fixed Python receipt changed')
  local venv=release..'/venv'
  local ref=need(s.decode(venv..'/.istore-python-runtime.json'),'Hermes venv receipt is missing')
  need(ref.state=='ready'and ref.storage_root==b.storage_root and ref.instance==b.instance and
    ref.path==venv and ref.version==b.python,'Hermes venv belongs to another Python SDK')
  return b,r,release,venv
end
local function ensure(txn,source,candidate)
  need(n.getuid()==0,'Administrator privileges required to prepare Hermes')
  app_path(txn);need(source=='origin'or source=='ks-cli','Explicit download policy required')
  local base=assert(txn:match('^(.*)/%.install%.[^/]+$'));local root=preflight(base)
  local prefix=base..'/releases/'
  need(type(candidate)=='string'and candidate:sub(1,#prefix)==prefix and
    candidate:sub(#prefix+1):match('^[a-zA-Z0-9_.-]+$'),'Invalid Hermes release directory')
  app_path(candidate)
  local policy=need(s.decode(share..'/runtime-policy.json'),'Hermes runtime policy is missing')
  need(policy.schema_version==1 and policy.python and policy.python.abi=='musl','Unsupported Hermes Python policy')
  local work=txn..'/runtime-client';local catalog=request(work,{op='catalog'},root);local entry
  for _,candidate in ipairs(catalog.entries)do
    if candidate.tool=='python'and candidate.version==policy.python.version and
      candidate.build==policy.python.build and candidate.abi==policy.python.abi and
      candidate.arch==n.uname().machine then entry=candidate;break end
  end
  need(entry and entry.availability=='available','Pinned Hermes Python is not in the mise catalog')
  local receipt=require('dependency-client').ensure(root,entry.id,nil,source,work,txn..'/runtime-task.json')
  need(root==uci('mise.main.storage_root'),'Runtime repository changed during Hermes preparation')
  c.receipt(receipt);need(receipt.verified and receipt.entry.id==entry.id,'Hermes Python verification failed')
  local uid,gid=account();local venv=candidate..'/venv'
  need(fs.lstat(candidate)and fs.stat(candidate).uid==uid,'Hermes candidate must belong to the service user')
  local rc=s.run({'/usr/share/mise-runtime/native/bin/exec-user',tostring(uid),tostring(gid),receipt.instance,'--create-venv',venv},
    {timeout=300,env={MISE_RUNTIME_ROOT=root,ISTORE_RUNTIME_HOME=assert(txn:match('^(.*)/%.install%.[^/]+$'))..'/data',ISTORE_RUNTIME_ACCELERATION=source},output=txn..'/venv.log'})
  need(rc==0,'Cannot create the fixed Hermes venv; inspect '..txn..'/venv.log')
  local receipt_path=root..'/environments/'..receipt.instance..'/receipt.json'
  local hash_rc,hash=s.pipe_capture({'/usr/bin/sha256sum',receipt_path})
  need(hash_rc==0 and hash:match('^[a-f0-9]+'),'Cannot hash the fixed Python receipt')
  local b={schema_version=1,provider='mise-runtime',tool='python',storage_root=root,instance=receipt.instance,
    artifact_set=receipt.artifact_set,receipt_sha256=hash:match('^([a-f0-9]+)'),python=receipt.entry.version,abi=receipt.entry.abi}
  s.write(candidate..'/runtime.json',b,420);binding(candidate..'/runtime.json')
  print('Fixed Hermes Python '..b.python..' ('..b.abi..'), '..b.instance)
end
local function cancel(txn)
  need(n.getuid()==0,'Administrator required to recover Hermes')
  app_path(txn)
  local journal=s.decode(txn..'/runtime-task.json');if not journal then return end
  need(journal.schema_version==1,'Unknown shared runtime task journal')
  c.path(journal.root);c.key(journal.plan)
  local work=txn..'/runtime-client';s.mkdir(work,448)
  for _,id in ipairs(store.list(journal.root..'/tasks'))do
    c.key(id)
    local task=s.decode(journal.root..'/tasks/'..id..'/task.json')
    if task and task.plan and task.plan.id==journal.plan and
      (task.status=='running'or task.status=='interrupted')then
      request(work,{op=task.status=='running'and'cancel'or'recover',id=id},journal.root)
    end
  end
end
local function as_app(path,command,argv)
  need(n.getuid()==0,'Administrator required to select the Hermes UID')
  local b,_,release,venv=binding(path);local uid,gid=account()
  local base=release:match('^(.*)/releases/[^/]+$')or release:match('^(.*)/%.install%.[^/]+/candidate$')
  need(base,'Hermes release belongs to an unknown application directory')
  local home=base..'/data';local st=fs.lstat(home)
  need(st and st.type=='dir'and st.uid==uid,'Hermes HOME is missing or belongs to another user')
  n.setenv('HOME',home);n.setenv('USER','hermes');n.setenv('LOGNAME','hermes')
  n.setenv('HERMES_HOME',home..'/.hermes');n.setenv('ISTORE_RUNTIME_HOME',home)
  n.setenv('MISE_RUNTIME_ROOT',b.storage_root);n.setenv('ISTORE_RUNTIME_ACCELERATION','origin')
  need(n.chdir(home),'Hermes HOME is unavailable')
  local program={'/usr/share/mise-runtime/native/bin/exec-user',tostring(uid),tostring(gid),b.instance,'--venv',venv,command}
  for _,value in ipairs(argv)do program[#program+1]=value end
  n.exec(unpack(program));need(false,'Cannot execute Hermes fixed Python')
end
local function main()
  local action=arg[1]
  if action=='preflight'then preflight(arg[2])
  elseif action=='ensure'then ensure(arg[2],arg[3],arg[4])
  elseif action=='cancel'then cancel(arg[2])
  elseif action=='inspect'then local b=binding(arg[2]);print(s.json.stringify(b))
  elseif action=='as-app'then local argv={};for i=4,#arg do argv[#argv+1]=arg[i]end;as_app(arg[2],arg[3],argv)
  else need(false,'Unknown Hermes runtime operation')end
end
local ok,err=pcall(main)
if not ok then io.stderr:write(type(err)=='table'and(err.code..': '..err.message)or tostring(err));io.stderr:write('\n');os.exit(1)end
