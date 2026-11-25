local s=require('system')
local fs,n=s.fs,s.nixio
local store=require('store')
local contract=require('contract')
local M={}
local function need(ok,message)return s.need(ok,'PROBE_FAILED',message)end
local function quote(value)return "'"..value:gsub("'","'\\''").."'"end
local function writable(st)return math.floor((math.floor(st.modedec/10)%10)/2)%2==1 or math.floor((st.modedec%10)/2)%2==1 end
local function regular(path,uid)
  local st=fs.lstat(path);need(st and st.type=='reg'and st.uid==uid,'Missing/foreign Python entry: '..path)
  return st
end
local function path(value,root)
  need(type(value)=='string'and value:sub(1,5)=='/mnt/'and not value:find('[%c:]')and not value:find('//',1,true)and value:sub(-1)~='/','Use a normalized persistent virtual environment path')
  need(value~=root and root:sub(1,#value+1)~=value..'/','Virtual environment cannot contain shared storage')
  local task=n.getuid()==0 and os.getenv('MISE_RUNTIME_PROBE')
  local probe=task and value==root..'/work/'..task..'/probe-venv'
  if probe then local t=s.decode(root..'/tasks/'..task..'/task.json');probe=t and t.status=='running'and t.pending_environment~=nil end
  for _,name in ipairs({'environments','libraries','mise','wrap','cache','tasks','plans','work','network'})do
    local shared=root..'/'..name;need(probe or(value~=shared and value:sub(1,#shared+1)~=shared..'/'),'Virtual environment cannot use SDK/manager directories')
  end
  local current=''
  for part in value:gmatch('[^/]+')do
    need(part~='.'and part~='..','Virtual environment traversal is forbidden');current=current..'/'..part
    local st=fs.lstat(current)
    if st then
      local sticky=current~=value and st.uid==0 and math.floor(st.modedec/1000)%2==1
      need(st.type=='dir'and(st.uid==0 or st.uid==n.getuid())and(not writable(st)or sticky),'Unsafe virtual environment parent: '..current)
    end
  end
  store.filesystem(value)
  return value
end
function M.validate_venv(root,id,sdk,receipt,value)
  path(value,root);need(fs.realpath(value)==value and fs.stat(value).uid==n.getuid(),'Virtual environment must be owned by this caller')
  regular(value..'/.istore-python-runtime.json',n.getuid())
  local ref=s.decode(value..'/.istore-python-runtime.json')
  need(ref and ref.schema_version==1 and ref.kind=='venv'and ref.storage_root==root and ref.instance==id and ref.sdk==sdk and ref.path==value and ref.version==receipt.entry.version,'Virtual environment belongs to another SDK or directory')
  if ref.state~='ready'then
    local owner=ref.creator_pid and s.process(ref.creator_pid)
    need(ref.state=='preparing'and ref.creation_nonce==os.getenv('ISTORE_PYTHON_CREATING')and owner and owner.start==ref.creator_start and owner.boot==ref.creator_boot and fs.stat('/proc/'..ref.creator_pid).uid==n.getuid(),'Virtual environment creation is incomplete; no shared Python fallback')
  end
  local original=s.read(sdk..'/bin/python3');need(original,'Fixed SDK Python launcher missing')
  local minor=receipt.entry.version:match('^(%d+%.%d+)')
  for _,name in ipairs({'python','python3','python'..minor})do
    local file=value..'/bin/'..name;local st=regular(file,n.getuid())
    need(not writable(st)and s.read(file)==original,'Virtual environment launcher changed; recreate this environment')
  end
  regular(value..'/pyvenv.cfg',n.getuid())
  local config=s.read(value..'/pyvenv.cfg')
  need(type(ref.config_text)=='string'and config==ref.config_text,'Virtual environment configuration changed')
  local home,system
  for line in config:gmatch('[^\n]+')do
    home=home or line:match('^home%s*=%s*(.-)%s*$')
    system=system or line:match('^include%-system%-site%-packages%s*=%s*(.-)%s*$')
  end
  need(home==sdk..'/bin'and system=='false','Virtual environment does not isolate the selected SDK')
  return value
end
function M.command(root,id,command,args,home,sdk,receipt,env,probing,acceleration,share)
  local marker=s.decode(sdk..'/.python-sdk.json')
  need(marker and marker.schema_version==1 and marker.storage_root==root and marker.instance==id,'Fixed Python launcher identity missing')
  env.PYTHONNOUSERSITE='1';env.PYTHONPYCACHEPREFIX=home..'/.cache/python/'..id..'/pycache'
  env.PIP_CACHE_DIR=home..'/.cache/pip/'..id;env.PIP_DISABLE_PIP_VERSION_CHECK='1'
  env.PIP_REQUIRE_VIRTUALENV=probing and'false'or'true'
  env.ISTORE_RUNTIME_ACCELERATION=acceleration
  for _,key in ipairs({'PYTHONPYCACHEPREFIX','PIP_CACHE_DIR'})do s.mkdir(env[key],448)end
  if not os.getenv('SSL_CERT_FILE')and fs.stat('/etc/ssl/certs/ca-certificates.crt')then env.SSL_CERT_FILE='/etc/ssl/certs/ca-certificates.crt'end
  if not os.getenv('OPENSSL_CONF')then env.OPENSSL_CONF=share..'/python-openssl.cnf'end
  local virtual=os.getenv('ISTORE_PYTHON_VENV')
  if command=='--create-venv'or command=='--venv'then virtual=nil end
  if virtual==''then virtual=nil end
  if virtual then M.validate_venv(root,id,sdk,receipt,virtual)end
  env.ISTORE_PYTHON_VENV=virtual or''
  env.VIRTUAL_ENV=virtual or''
  env.PATH=(virtual and(virtual..'/bin:')or'')..sdk..'/bin:/usr/sbin:/usr/bin:/sbin:/bin'
  local entry=(virtual or sdk)..'/bin/python3'
  local program={sdk..'/bin/python.real'}
  if receipt.entry.abi=='glibc'then
    local library=root..'/libraries/'..receipt.library
    program={library..'/ld.so','--library-path',sdk..'/lib:'..library,sdk..'/bin/python.real'}
  end
  if command=='--shell'then program={'/bin/sh'}
  else env.__PYVENV_LAUNCHER__=entry end
  if command=='python'or command=='python3'then
  elseif command=='pip'then
    need(args[1]=='--version'or args[1]=='-V'or args[1]=='--help'or args[1]=='-h'or args[1]=='help','Shared pip is for version/help; create and use an application --venv')
    table.insert(args,1,'pip');table.insert(args,1,'-m')
  elseif command=='--create-venv'or command=='--venv'then
    need(#args>=1,'Virtual environment path required');path(args[1],root)
    table.insert(args,1,command=='--create-venv'and'create'or'run')
    for _,value in ipairs({id,sdk,root,share..'/python-venv.py'})do table.insert(args,1,value)end
  elseif command~='--shell'then need(false,'Unsupported fixed Python command')end
  return program,args,{'PYTHONHOME','PYTHONPATH','PYTHONUSERBASE','PYTHONEXECUTABLE','__PYVENV_LAUNCHER__','_PYTHON_HOST_PLATFORM','_PYTHON_SYSCONFIGDATA_NAME','PYTHONPLATLIBDIR','VIRTUAL_ENV','PIP_USER','PIP_PREFIX','PIP_TARGET','PIP_PYTHON'}
end
function M.install(ctx,t,entry,work,log)
  local tasks=require('tasks');local artifacts=require('artifacts');local libraries=require('libraries')
  local library
  if entry.abi=='glibc'then
    tasks.phase(ctx,t,'library')
    local definition=t.plan.library and require('dependencies').library(t.plan.library,entry.arch)or libraries.definition(entry.arch)
    library=libraries.ensure(ctx,definition,t.plan.source,work,log,ctx.download_options).id
  end
  local id=contract.instance_id(entry,nil,library);need(id==t.plan.instance,'Python plan identity changed')
  local sdk=ctx.root..'/environments/'..id;need(not fs.lstat(sdk),'Python SDK already exists')
  s.mkdir(sdk,448);t.pending_environment={id=id,inode=fs.stat(sdk).ino};tasks.phase(ctx,t,'download')
  local archive=artifacts.download(ctx,entry.artifacts[1],t.plan.source,work,log,ctx.download_options)
  tasks.phase(ctx,t,'extract');artifacts.extract(archive,entry.artifacts[1],sdk..'/payload',work,log)
  for _,name in ipairs(store.list(sdk..'/payload'))do need(fs.rename(sdk..'/payload/'..name,sdk..'/'..name),'Cannot reserve Python SDK layout')end
  need(fs.rmdir(sdk..'/payload'),'Cannot remove empty Python payload')
  local minor=entry.version:match('^(%d+%.%d+)');local executable=sdk..'/bin/python'..minor
  libraries.elf(executable,entry.arch);need(fs.rename(executable,sdk..'/bin/python.real'),'Cannot reserve actual Python ELF')
  local launcher=ctx.share..'/native/bin/python-launch-'..entry.abi
  libraries.elf(launcher,entry.arch)
  for _,name in ipairs({'python','python3','python'..minor,'pip','pip3','pip'..minor})do
    if fs.lstat(sdk..'/bin/'..name)then s.remove(sdk..'/bin/'..name)end
  end
  s.write(sdk..'/bin/python3',assert(s.read(launcher)),493)
  need(fs.symlink('python3',sdk..'/bin/python')and fs.symlink('python3',sdk..'/bin/python'..minor),'Cannot create fixed Python aliases')
  s.write(sdk..'/.python-sdk.json',{schema_version=1,kind='sdk',storage_root=ctx.root,instance=id},420)
  s.mkdir(sdk..'/native/bin',493)
  s.write(sdk..'/native/bin/pip','#!/bin/sh\nset -eu\nif [ -n "${ISTORE_PYTHON_VENV:-}" ]; then exec "$ISTORE_PYTHON_VENV/bin/python3" -m pip "$@"; fi\nexec '..quote(sdk..'/bin/python3')..' -m pip "$@"\n',493)
  for _,name in ipairs({'pip','pip3','pip'..minor})do s.write(sdk..'/bin/'..name,require('adapters').launcher(ctx,id,'pip'),493)end
  local receipt={schema_version=1,instance=id,entry=entry,library=library,artifact_set=entry.artifact_set,installed_at=os.time(),verified=false,probes={},mise_key='istore-'..id,root=ctx.root}
  s.write(sdk..'/receipt.json',receipt,420)
  need(s.run({'chmod','-R','a+rX,go-w',sdk},{output=log,append=true})==0,'Cannot protect Python SDK')
  tasks.phase(ctx,t,'probe')
  local function probe(args)
    local argv={sdk..'/bin/python3'};for _,v in ipairs(args)do argv[#argv+1]=v end
    local file=work..'/python-probe'
    local rc=s.run(argv,{cwd=sdk,env={MISE_RUNTIME_PROBE=t.id,ISTORE_RUNTIME_ACCELERATION='origin'},output=file,timeout=90})
    need(rc==0,'Python probe failed: '..(s.read(file)or''));return(s.read(file)or''):gsub('%s+$','')
  end
  need(probe({'--version'})=='Python '..entry.version,'Python version differs from catalog')
  probe({'-m','ensurepip','--upgrade','--default-pip'})
  local code=[=[import ctypes,json,os,platform,site,sqlite3,ssl,subprocess,sys,venv,ensurepip
from importlib.metadata import version
from pip._vendor.packaging.tags import sys_tags
assert not site.ENABLE_USER_SITE
lib=ctypes.CDLL(None);assert lib.getpid()==os.getpid()
try:
 f=lib.gnu_get_libc_version;f.restype=ctypes.c_char_p;libc='glibc';libc_version=f().decode()
except AttributeError:libc='musl';libc_version=None
db=sqlite3.connect(':memory:');assert db.execute('select ?,?',('a\x00b',b'a\x00b')).fetchone()==('a\x00b',b'a\x00b');db.close()
assert ssl.create_default_context().cert_store_stats()['x509_ca']>0
child=json.loads(subprocess.check_output([sys.executable,'-I','-c','import json,sys;print(json.dumps([sys.executable,sys.prefix]))'],text=True))
assert child==[sys.executable,sys.prefix]
tags=[str(t)for t in sys_tags()]
print(json.dumps(dict(version=platform.python_version(),arch=platform.machine(),abi=libc,libc=libc_version,prefix=sys.prefix,base=sys.base_prefix,executable=sys.executable,pip=version('pip'),ensurepip=ensurepip.version(),manylinux=any('manylinux_'in t for t in tags),musllinux=any('musllinux_'in t for t in tags),ssl=ssl.OPENSSL_VERSION,sqlite=sqlite3.sqlite_version)))
]=]
  local result=s.json.parse(probe({'-c',code}))
  need(result and result.version==entry.version and result.arch==entry.arch and result.abi==entry.abi,'Python actual version/architecture/ABI differs')
  need(result.prefix==sdk and result.base==sdk and result.executable==sdk..'/bin/python3','Python launcher/prefix is not fixed')
  need((entry.abi=='glibc'and result.manylinux and not result.musllinux)or(entry.abi=='musl'and result.musllinux and not result.manylinux),'pip native wheel ABI tags do not match fixed Python')
  -- The active root-owned installation probe may use its own task work dir;
  -- ordinary application venvs may never write any manager/SDK directory.
  local venv=work..'/probe-venv'
  probe({ctx.share..'/python-venv.py',ctx.root,sdk,id,'create',venv})
  probe({ctx.share..'/python-venv.py',ctx.root,sdk,id,'run',venv,'python','-c',"import sys;assert sys.prefix!=sys.base_prefix"})
  s.remove(venv)
  need(s.run({'chmod','-R','a+rX,go-w',sdk},{output=log,append=true})==0,'Cannot protect probed Python SDK')
  receipt.probes={version='passed',arch='passed',abi='passed',launcher='passed',ssl='passed',sqlite='passed',ctypes='passed',subprocess='passed',pip='passed',venv='passed',pip_version=result.pip,pip_source='bundled-ensurepip',ensurepip_version=result.ensurepip,wheel_abi=entry.abi=='glibc'and'manylinux'or'musllinux'}
  receipt.verified=true;s.write(sdk..'/receipt.json',receipt,420)
  tasks.phase(ctx,t,'registration');require('registration').register(ctx,receipt,work,log)
  t.publication={instance=id,wrap=require('adapters').launcher(ctx,id)};tasks.save(ctx,t);store.bump(ctx)
  return receipt
end
return M
