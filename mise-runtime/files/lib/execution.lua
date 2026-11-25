local sys=require('system')
local store=require('store')
local contract=require('contract')
local n,fs=sys.nixio,sys.fs
local M={}
local share=arg[0]:match('^(.*)/[^/]+$')or'/usr/share/mise-runtime'
function M.home(root)
  local uid=n.getuid()
  local home=os.getenv('ISTORE_RUNTIME_HOME')
  if not home or home==''then home=uid==0 and root..'/home'or root..'/users/'..uid..'/home'end
  sys.need(home:sub(1,5)=='/mnt/'and not home:find('[%c:]')and not home:find('//',1,true)and home:sub(-1)~='/','INVALID_INPUT','HOME must be a normalized persistent /mnt path')
  local current=''
  for part in home:gmatch('[^/]+')do
    sys.need(part~='.'and part~='..','INVALID_INPUT','HOME traversal is forbidden')
    current=current..'/'..part
    local st=fs.lstat(current)
    sys.need(not st or st.type=='dir','INVALID_INPUT','HOME contains a symlink or non-directory')
    if st then
      sys.need(st.uid==0 or st.uid==uid,'INVALID_INPUT','HOME parent belongs to another UID')
      local writable=math.floor((math.floor(st.modedec/10)%10)/2)%2==1 or math.floor((st.modedec%10)/2)%2==1
      local protected_sticky=current~=home and st.uid==0 and math.floor(st.modedec/1000)%2==1
      sys.need(not writable or protected_sticky,'INVALID_INPUT','HOME parent is writable by another user')
    end
  end
  local inside=home==root or home:sub(1,#root+1)==root..'/'
  local own=home:sub(1,#(root..'/users/'..uid..'/'))==root..'/users/'..uid..'/'
    or uid==0 and(home==root..'/home'or home:sub(1,#root+6)==root..'/home/')
  sys.need(not inside or own,'INVALID_INPUT','HOME cannot use shared SDK or manager directories')
  local nearest=home
  while not fs.lstat(nearest)do nearest=assert(nearest:match('^(.*)/[^/]+$'))end
  sys.need(fs.realpath(nearest)==nearest,'INVALID_INPUT','HOME path is not canonical')
  local parent=fs.stat(nearest)
  sys.need(parent.uid==uid,'INVALID_INPUT','Ask administrator to prepare this UID home, or choose an owned ISTORE_RUNTIME_HOME')
  store.filesystem(home)
  sys.mkdir(home,448)
  return home
end
function M.exec(root,id,command,args)
  contract.path(root);contract.key(id);args=args or{}
  store.validate(root)
  local sdk=root..'/environments/'..id
  local st=fs.lstat(sdk);sys.need(st and st.type=='dir'and st.uid==0,'OFFLINE','Fixed SDK missing or disk offline')
  local receipt=sys.decode(sdk..'/receipt.json');sys.need(receipt,'OFFLINE','Fixed SDK receipt missing');contract.receipt(receipt)
  sys.need(receipt.instance==id and receipt.root==root,'INTEGRITY','Fixed SDK identity mismatch')
  if not receipt.verified or not fs.access(root..'/wrap/'..id,'x')then
    local task=os.getenv('MISE_RUNTIME_PROBE')
    local lock=n.getuid()==0 and task and sys.decode(root..'/.lock/owner.json')
    local t=lock and lock.id==task and sys.decode(root..'/tasks/'..task..'/task.json')
    sys.need(t and t.status=='running'and t.pending_environment and t.pending_environment.id==id and t.pending_environment.inode==st.ino,'PROBE_FAILED','Environment is not verified')
  end
  local home=M.home(root)
  local cwd=fs.realpath('.')
  if not cwd or not fs.access(cwd,'rx')then sys.need(n.chdir(home),'OFFLINE','Cannot enter persistent HOME')end
  local env={HOME=home,ISTORE_RUNTIME_HOME=home,ISTORE_RUNTIME_ID=id,ISTORE_RUNTIME_STORAGE=root,
    XDG_CONFIG_HOME=home..'/.config',XDG_CACHE_HOME=home..'/.cache',XDG_DATA_HOME=home..'/.local/share',XDG_STATE_HOME=home..'/.local/state',
    TMPDIR=home..'/.cache/runtime/'..id..'/tmp',
    MISE_DATA_DIR=root..'/mise/'..receipt.entry.arch..'-'..receipt.entry.abi,
    MISE_CONFIG_DIR=home..'/.config/mise/'..receipt.entry.arch..'-'..receipt.entry.abi,
    MISE_CACHE_DIR=home..'/.cache/mise',MISE_STATE_DIR=home..'/.local/state/mise',MISE_NOT_FOUND_AUTO_INSTALL='0'}
  env.PATH=sdk..'/bin:/usr/sbin:/usr/bin:/sbin:/bin'
  for _,key in ipairs({'XDG_CONFIG_HOME','XDG_CACHE_HOME','XDG_DATA_HOME','XDG_STATE_HOME','TMPDIR','MISE_CONFIG_DIR','MISE_CACHE_DIR','MISE_STATE_DIR'})do sys.mkdir(env[key],448)end
  local accel=os.getenv('ISTORE_RUNTIME_ACCELERATION')
  sys.need(not accel or accel=='origin'or accel=='ks-cli','INVALID_INPUT','Invalid acceleration policy')
  if not accel then local policy=sys.decode(root..'/network/settings.json');accel=policy and policy.acceleration and'ks-cli'or'origin'end
  local program,extra_unset
  if receipt.entry.tool=='node'then
    env.npm_config_prefix=home..'/.local/npm/'..id;env.npm_config_cache=home..'/.cache/npm/'..id
    env.npm_config_libc=receipt.entry.abi;env.npm_config_update_notifier='false'
    env.PATH=sdk..'/bin:'..env.npm_config_prefix..'/bin:/usr/sbin:/usr/bin:/sbin:/bin'
    sys.mkdir(env.npm_config_prefix,448);sys.mkdir(env.npm_config_cache,448)
    if command=='node'then
      program={sdk..'/bin/node.real'}
      if receipt.entry.abi=='glibc'then
        local lib=root..'/libraries/'..receipt.library
        program={lib..'/ld.so','--library-path',lib,sdk..'/bin/node.real','--require',sdk..'/node-loader.cjs'}
      end
    elseif command=='npm'or command=='npx'then
      if command=='npm'and accel=='ks-cli'then
        env.PATH=share..'/native/bin:'..sdk..'/native/bin:'..env.PATH
        program={os.getenv('ISTORE_RUNTIME_KS_CLI')or'/usr/bin/ks-cli','npm'}
      else program={sdk..'/bin/node',sdk..'/lib/node_modules/npm/bin/'..(command=='npm'and'npm-cli.js'or'npx-cli.js')}end
    elseif command=='git'then
      env.PATH=share..'/native/bin:'..sdk..'/native/bin:'..env.PATH
      program=accel=='ks-cli'and{os.getenv('ISTORE_RUNTIME_KS_CLI')or'/usr/bin/ks-cli','git'}or{'/usr/bin/git'}
    elseif command=='--shell'then program={'/bin/sh'}end
    if not os.getenv('npm_config_git')and not os.getenv('NPM_CONFIG_GIT')then env.npm_config_git=sdk..'/bin/git'end
  elseif receipt.entry.tool=='python'then
    program,args,extra_unset=require('python').command(root,id,command,args,home,sdk,receipt,env,not receipt.verified,accel,share)
  elseif receipt.entry.tool=='go'or receipt.entry.tool=='zig'then
    program,args=require('native').command(root,id,command,args,home,sdk,receipt,env,accel,share)
  end
  sys.need(program,'UNSUPPORTED','Command is not allowed for this runtime')
  local argv={'/usr/bin/env'}
  for _,key in ipairs({'HOME','ENV','BASH_ENV','NODE_OPTIONS','NODE_PATH','NODE_REPL_EXTERNAL_MODULE','LD_LIBRARY_PATH','LD_PRELOAD',
    'NPM_CONFIG_PREFIX','NPM_CONFIG_CACHE','MISE_NODE_VERSION','MISE_PYTHON_VERSION','MISE_RUST_VERSION','MISE_GO_VERSION','MISE_ZIG_VERSION','MISE_JAVA_VERSION'})do argv[#argv+1]='-u';argv[#argv+1]=key end
  for _,key in ipairs(extra_unset or{})do argv[#argv+1]='-u';argv[#argv+1]=key end
  for key,value in pairs(env)do argv[#argv+1]=key..'='..value end
  for _,value in ipairs(program)do argv[#argv+1]=value end
  for _,value in ipairs(args)do sys.need(type(value)=='string'and not value:find('%z'),'INVALID_INPUT','Invalid argument');argv[#argv+1]=value end
  n.exec(unpack(argv));sys.fail('OFFLINE','Cannot execute fixed runtime')
end
return M
