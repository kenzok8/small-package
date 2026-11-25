#!/usr/bin/lua
-- OpenClaw owns its release binding; mise-runtime owns SDKs and libraries.
package.path='/usr/share/mise-runtime/lib/?.lua;'..package.path
local sys=require('system')
local contract=require('contract')
local store=require('store')
local fs,n=sys.fs,sys.nixio
local share=assert(arg[0]:match('^(.*)/[^/]+$'))

local function need(value,message) return sys.need(value,'RUNTIME_BINDING',message) end
local function writable_by_others(st)
  return math.floor((math.floor(st.modedec/10)%10)/2)%2==1 or math.floor((st.modedec%10)/2)%2==1
end
local function app_path(path)
  need(type(path)=='string'and path:sub(1,5)=='/mnt/'and not path:find('[%c:]')and not path:find('//',1,true)and path:sub(-1)~='/','Use a normalized application path on a persistent /mnt disk')
  local current=''
  for part in path:gmatch('[^/]+')do
    need(part~='.'and part~='..','Application path traversal is forbidden')
    current=current..'/'..part
    local st=fs.lstat(current)
    local sticky=st and current~=path and math.floor(st.modedec/1000)%2==1
    need(not st or(st.type=='dir'and st.uid==0 and(not writable_by_others(st)or sticky)),'Application parent must be a protected root-owned directory: '..current)
  end
  return store.filesystem(path)
end
local function protected_file(path)
  local st=fs.lstat(path)
  need(st and st.type=='reg'and st.uid==0 and not writable_by_others(st),'Missing or writable runtime binding/receipt: '..path)
end
local function uci(key)
  if key=='mise.main.storage_root'and n.getuid()~=0 then return require('active-root').current()end
  local rc,out=sys.pipe_capture({'/sbin/uci','-q','get',key})
  return rc==0 and out:gsub('%s+$','')or''
end
local function preflight(base)
  local storage=app_path(base)
  need(base~=storage.mount.point,'Use a dedicated application subdirectory, not the disk mount root')
  need(not fs.lstat(base..'/.storage.json'),'Application data cannot be a shared runtime storage root')
  local root=uci('mise.main.storage_root')
  if root~=''then
    root=fs.realpath(root)or root
    need(base~=root and base:sub(1,#root+1)~=root..'/'and root:sub(1,#base+1)~=base..'/',
      'Application and shared runtime directories must not contain each other')
  end
end
local function binding(path)
  path=need(fs.realpath(path),'Runtime binding is missing')
  protected_file(path)
  local release=need(path:match('^(.*)/runtime.json$'),'Invalid binding filename')
  app_path(release)
  local b=need(sys.decode(path),'Invalid binding JSON')
  need(b.schema_version==1 and b.provider=='mise-runtime'and b.tool=='node','Unsupported application runtime binding')
  contract.path(b.storage_root);contract.key(b.instance);contract.key(b.library)
  need(b.storage_root==uci('mise.main.storage_root'),'Runtime repository changed; restart OpenClaw to prepare its fixed environment')
  store.validate(b.storage_root)
  local sdk=b.storage_root..'/environments/'..b.instance
  protected_file(sdk..'/receipt.json')
  local r=sys.decode(sdk..'/receipt.json');contract.receipt(r)
  need(r.verified and r.root==b.storage_root and r.instance==b.instance and r.entry.tool=='node'and r.entry.abi=='glibc','Fixed shared SDK is unavailable or unverified')
  need(r.entry.arch==n.uname().machine and r.entry.version==b.node and r.npm==b.npm and r.library==b.library and r.artifact_set==b.artifact_set,'Runtime binding no longer matches its fixed SDK')
  local lib=b.storage_root..'/libraries/'..b.library
  protected_file(lib..'/receipt.json')
  local lr=sys.decode(lib..'/receipt.json')
  need(lr and lr.verified and lr.id==b.library and lr.manifest_sha256==b.library_manifest_sha256,'Fixed library receipt changed')
  return b,r,release,sdk
end
local function request(work,value,root)
  contract.path(root)
  sys.write(work..'/request.json',value)
  local rc=sys.run({'/usr/sbin/mise-runtime','request'},{stdin=work..'/request.json',output=work..'/response.json',timeout=60,env={MISE_RUNTIME_ROOT=root}})
  local response=sys.decode(work..'/response.json')
  need(rc==0 and response and response.ok,response and response.error and response.error.message or'Public runtime request failed')
  return response.value
end
local function ensure(txn,source)
  need(n.getuid()==0,'Runtime installation requires administrator privileges')
  app_path(txn)
  need(source=='origin'or source=='ks-cli','Explicit download policy required')
  local work=txn..'/runtime-client';sys.mkdir(work,448)
  local policy=need(sys.decode(share..'/runtime-policy.json'),'Application runtime policy missing')
  need(policy.schema_version==1 and policy.tool=='node'and policy.abi=='glibc','Unsupported application runtime policy')
  local root=uci('mise.main.storage_root');contract.path(root)
  local state=request(work,{op='read'},root);need(state.path==root,'Public runtime returned another storage root')
  local catalog=request(work,{op='catalog'},root);local entry
  for _,e in ipairs(catalog.entries)do
    if e.tool==policy.tool and e.version==policy.version and e.build==policy.build and e.abi==policy.abi and e.npm==policy.npm and e.arch==n.uname().machine then entry=e;break end
  end
  need(entry and entry.availability=='available','Pinned application SDK is not in the supported catalog')
  local library=require('libraries').definition(entry.arch,policy.library_revision).id
  local id=contract.instance_id(entry,nil,library)
  local receipt=require('dependency-client').ensure(root,entry.id,library,source,work,txn..'/runtime-task.json')
  need(root==uci('mise.main.storage_root'),'Runtime repository changed during installation; retry')
  contract.receipt(receipt)
  local lr=need(sys.decode(state.path..'/libraries/'..library..'/receipt.json'),'Fixed library missing')
  local b={schema_version=1,provider='mise-runtime',tool='node',storage_root=state.path,instance=id,
    library=library,library_manifest_sha256=lr.manifest_sha256,artifact_set=receipt.artifact_set,node=receipt.entry.version,npm=receipt.npm}
  local candidate=txn..'/candidate';sys.mkdir(candidate,493);sys.mkdir(candidate..'/node',493);sys.mkdir(candidate..'/node/bin',493)
  sys.write(candidate..'/runtime.json',b,420)
  binding(candidate..'/runtime.json')
  for _,command in ipairs({'node','npm','npx','git'})do
    local script='#!/bin/sh\nset -eu\nself="$(readlink -f "$0")"\nref="$(readlink -f "$(dirname "$self")/../../runtime.json")"\nexec /usr/bin/lua /usr/share/openclawmgr/shared-runtime.lua exec "$ref" '..command..' "$@"\n'
    sys.write(candidate..'/node/bin/'..command,script,493)
  end
  sys.write(candidate..'/node/.mise-runtime','1\n',420)
  print('Fixed shared Node '..b.node..', npm '..b.npm..', '..b.instance)
end
local function prepare(path)
  need(n.getuid()==0,'Administrator required to prepare application dependencies')
  path=need(fs.realpath(path),'Runtime binding is missing');protected_file(path)
  local release=need(path:match('^(.*)/runtime.json$'),'Invalid binding path');app_path(release)
  local old=need(sys.decode(path),'Invalid runtime binding')
  need(old.schema_version==1 and old.provider=='mise-runtime'and old.tool=='node','Unsupported runtime binding')
  contract.key(old.instance);contract.key(old.library);contract.digest(old.artifact_set)
  local root=uci('mise.main.storage_root');contract.path(root);store.open(root)
  local base=need(release:match('^(.*)/releases/[^/]+$'),'Expected an installed application release')
  preflight(base)
  local entry
  for _,e in ipairs(sys.decode('/usr/share/mise-runtime/catalog.json').entries)do
    if e.tool=='node'and e.abi=='glibc'and e.arch==n.uname().machine and e.availability=='available'and e.version==old.node and e.npm==old.npm and e.artifact_set==old.artifact_set and contract.instance_id(e,nil,old.library)==old.instance then entry=e;break end
  end
  need(entry,'The original fixed SDK is not in the supported catalog')
  local work=base..'/log/runtime-prepare';sys.mkdir(work,448)
  local generation=os.getenv('OPENCLAWMGR_START_GENERATION')
  local previous=sys.decode(work..'/status.json')
  need(not(generation and previous and previous.status=='failed'and previous.generation==generation and previous.storage_root==root),'Runtime preparation failed for this start attempt; inspect its task and restart to retry')
  sys.write(work..'/status.json',{status='preparing',storage_root=root,generation=generation,started=os.time()})
  local ok,result=pcall(function()
    local source=uci('mise.main.acceleration')=='0'and'origin'or'ks-cli'
    local r=require('dependency-client').ensure(root,entry.id,old.library,source,work,work..'/runtime-task.json')
    need(root==uci('mise.main.storage_root'),'Runtime repository changed during preparation; restart again')
    local lr=sys.decode(root..'/libraries/'..old.library..'/receipt.json')
    need(lr and lr.verified and lr.manifest_sha256==old.library_manifest_sha256,'Restored library differs from the fixed application binding')
    local fresh={};for k,v in pairs(old)do fresh[k]=v end;fresh.storage_root=root
    local candidate=work..'/binding';sys.mkdir(candidate,493)
    sys.write(candidate..'/runtime.json',fresh,420);binding(candidate..'/runtime.json')
    need(fs.rename(candidate..'/runtime.json',path),'Cannot activate the prepared runtime binding')
    require('active-root').publish(root)
    sys.write(work..'/status.json',{status='ready',storage_root=root,generation=generation,finished=os.time()})
    return r
  end)
  if not ok then
    sys.write(work..'/status.json',{status='failed',storage_root=root,generation=generation,error=type(result)=='table'and result.message or tostring(result),finished=os.time()})
    error(result,0)
  end
  return result
end
local function cancel(txn)
  need(n.getuid()==0,'Administrator required')
  app_path(txn)
  local journal=sys.decode(txn..'/runtime-task.json');if not journal then return end
  need(journal.schema_version==1,'Unknown shared task journal');contract.path(journal.root);contract.key(journal.plan)
  local work=txn..'/runtime-client';sys.mkdir(work,448)
  for _,id in ipairs(store.list(journal.root..'/tasks'))do
    contract.key(id)
    local t=sys.decode(journal.root..'/tasks/'..id..'/task.json')
    if t and t.plan and t.plan.id==journal.plan and(t.status=='running'or t.status=='interrupted')then
      request(work,{op=t.status=='running'and'cancel'or'recover',id=id},journal.root)
    end
  end
end
local function execute(path,command,argv)
  local b,r,release=binding(path)
  need(command=='node'or command=='npm'or command=='npx'or command=='git','Unsupported fixed runtime command')
  if not os.getenv('ISTORE_RUNTIME_HOME')then
    local home=os.getenv('HOME');local st=home and fs.lstat(home)
    local base=release:match('^(.*)/releases/[^/]+$')or release:match('^(.*)/%.install%.[^/]+/candidate$')
    if base and home and home:sub(1,#base+1)==base..'/'and st and st.type=='dir'and st.uid==n.getuid()then n.setenv('ISTORE_RUNTIME_HOME',home)end
  end
  n.setenv('ISTORE_RUNTIME_ACCELERATION',os.getenv('OPENCLAWMGR_ACCELERATED')=='1'and'ks-cli'or'origin')
  if command=='npm'and argv[1]~='--version'and argv[1]~='-v'then
    table.insert(argv,1,release..'/global');table.insert(argv,1,'--prefix')
  end
  -- Use the public entry, whose module context and acceleration shims belong
  -- to mise-runtime; never import its execution module under an app's arg[0].
  n.setenv('MISE_RUNTIME_ROOT',b.storage_root)
  local program={'/usr/sbin/mise-runtime','exec',b.instance,command}
  for _,value in ipairs(argv)do program[#program+1]=value end
  n.exec(unpack(program))
  need(false,'Cannot execute the public fixed runtime entry')
end
local function as_app(base,kind,argv)
  need(n.getuid()==0,'Administrator required to select the application UID')
  app_path(base)
  local user=n.getpw('openclawmgr')
  need(user and user.uid>0 and user.gid>0,'Install the dedicated openclawmgr user before starting')
  local b,r,release=binding(base..'/current/runtime.json')
  need(release:match('^(.*)/releases/[^/]+$')==base,'Release belongs to another application directory')
  local args
  if kind=='native'then args={share..'/runtime-check.cjs','native',release..'/global',release..'/receipt.json'}
  elseif kind=='cli'or kind=='gateway'then
    local prefix=release..'/global/lib/node_modules/openclaw/'
    local entry=fs.stat(prefix..'openclaw.mjs')and prefix..'openclaw.mjs'or prefix..'dist/cli.js'
    protected_file(entry);args={entry};for _,value in ipairs(argv)do args[#args+1]=value end
  else need(false,'Unknown application command')end
  n.setenv('HOME',base..'/data');n.setenv('ISTORE_RUNTIME_HOME',base..'/data')
  n.setenv('USER','openclawmgr');n.setenv('LOGNAME','openclawmgr')
  n.setenv('OPENCLAW_HOME',base..'/data');n.setenv('OPENCLAW_STATE_DIR',base..'/data/.openclaw')
  n.setenv('OPENCLAW_CONFIG_PATH',base..'/data/.openclaw/openclaw.json')
  n.setenv('MISE_RUNTIME_ROOT',b.storage_root);n.setenv('ISTORE_RUNTIME_ACCELERATION','origin')
  need(n.chdir(base..'/data'),'Application data directory is unavailable')
  local program={'/usr/share/mise-runtime/native/bin/exec-user',tostring(user.uid),tostring(user.gid),b.instance,'node'}
  if kind=='gateway'then
    program={'/usr/share/mise-runtime/native/bin/exec-user',tostring(user.uid),tostring(user.gid),b.instance,'--shell',share..'/gateway.sh',base}
    for _,value in ipairs(args)do program[#program+1]=value end
  else for _,value in ipairs(args)do program[#program+1]=value end end
  n.exec(unpack(program));need(false,'Cannot start the application UID runtime')
end
local function main()
  local action=arg[1]
  if action=='preflight'then preflight(arg[2])
  elseif action=='port-check'then
    app_path(arg[2])
    local result=assert(loadfile(share..'/port-check.lua'))().check(arg[2],arg[3],arg[4])
    print(sys.json.stringify(result))
  elseif action=='ensure'then ensure(arg[2],arg[3])
  elseif action=='cancel'then cancel(arg[2])
  elseif action=='exec'then local args={};for i=4,#arg do args[#args+1]=arg[i]end;execute(arg[2],arg[3],args)
  elseif action=='as-app'then local args={};for i=4,#arg do args[#args+1]=arg[i]end;as_app(arg[2],arg[3],args)
  elseif action=='prepare'then prepare(arg[2])
  elseif action=='service'then
    local base=arg[2];prepare(base..'/current/runtime.json')
    local args={};for i=3,#arg do args[#args+1]=arg[i]end
    as_app(base,'gateway',args)
  elseif action=='inspect'then local b=binding(arg[2]);print(sys.json.stringify(b))
  elseif action=='describe'then
    local b,r=binding(arg[2])
    local lib=sys.decode(b.storage_root..'/libraries/'..b.library..'/receipt.json')
    print(sys.json.stringify({provider=b.provider,instance=b.instance,tool=b.tool,
      node=b.node,npm=b.npm,abi=r.entry.abi,arch=r.entry.arch,verified=true,
      libc={name='glibc',version=lib.version,id=b.library}}))
  elseif action=='check'then
    local b=binding(arg[2]);local work=arg[3];app_path(work);sys.mkdir(work,448)
    require('libraries').check({root=b.storage_root},b.library,work)
  else need(false,'Unknown runtime binding operation')end
end
local ok,error=pcall(main)
if not ok then io.stderr:write(type(error)=='table'and(error.code..': '..error.message)or tostring(error));io.stderr:write('\n');os.exit(1)end
