-- A standard npm script-shell adapter for one audited download script.
-- Other lifecycle commands retain their original shell and destinations.
package.path='/usr/share/mise-runtime/lib/?.lua;'..package.path
local s=require('system');local fs,n=s.fs,s.nixio
local function native()
  local argv={'/bin/sh'};for _,value in ipairs(arg)do argv[#argv+1]=value end
  n.exec(unpack(argv));error('Cannot execute lifecycle shell')
end
local function hash(file)
  local rc,value=s.pipe_capture({'/usr/bin/sha256sum',file})
  assert(rc==0,'Cannot hash native artifact')
  return assert(value:match('^([a-f0-9]+)'))
end
local function run(argv)
  -- Inherit npm's durably owned session: do not detach another process group.
  local pid=assert(n.fork())
  if pid==0 then n.exec(unpack(argv));os.exit(127)end
  local _,kind,code=n.waitpid(pid)
  return kind=='exited'and code or 125
end
local function main()
  local share=assert(arg[0]:match('^(.*)/[^/]+$'))
  local policy=s.decode(share..'/native-downloads.json')
  if not policy or arg[1]~='-c'or arg[2]~=policy.command or #arg~=2
    or os.getenv('npm_package_name')~=policy.package or os.getenv('npm_package_version')~=policy.version
    or os.getenv('npm_lifecycle_event')~=policy.event then return native()end
  local base,txn=os.getenv('OPENCLAWMGR_BASE_DIR'),os.getenv('OPENCLAWMGR_TXN')
  if not base or not txn then return native()end
  assert(n.getuid()==0 and fs.realpath(base)==base and fs.realpath(txn)==txn,'Invalid installer context')
  assert(txn:sub(1,#base+10)==base..'/.install.'and not txn:sub(#base+11):find('/'),'Invalid transaction')
  local st=fs.lstat(txn);assert(st.type=='dir'and st.uid==0 and st.modedec==700,'Unsafe transaction')
  local cwd=assert(fs.realpath('.'))
  assert(cwd==txn..'/candidate/global/lib/node_modules/openclaw/node_modules/'..policy.package,'Unexpected lifecycle directory')
  local pkg=s.decode(cwd..'/package.json')
  assert(pkg.name==policy.package and pkg.version==policy.version,'Lifecycle package identity changed')
  assert(hash(cwd..'/download-lib.js')==policy.script_sha256,'Audited native download script changed')
  assert(os.getenv('npm_config_libc')=='glibc','Expected fixed GNU Node runtime')
  local asset=assert(policy.assets[n.uname().machine],'Unsupported native artifact architecture')
  local cache=base..'/npm-cache/native';s.mkdir(cache,448)
  assert(fs.realpath(cache)==cache and fs.stat(cache).uid==0,'Unsafe native cache')
  local file=cache..'/'..asset.sha256
  local function valid(path)
    local item=fs.lstat(path)
    return item and item.type=='reg'and item.uid==0 and item.size==asset.bytes and hash(path)==asset.sha256
  end
  if not valid(file)then
    if fs.lstat(file)then assert(fs.lstat(file).type=='reg'and fs.unlink(file),'Unsafe cached artifact')end
    local part=txn..'/native-'..asset.sha256..'.part.'..n.getpid();assert(not fs.lstat(part))
    local url='https://github.com/matrix-org/matrix-rust-sdk-crypto-nodejs/releases/download/v'..policy.version..'/'..asset.filename
    local argv
    if os.getenv('OPENCLAWMGR_ACCELERATED')=='1'then
      argv={'/usr/bin/ks-cli','download','--mode','auto','--timeout','3300s','--progress','plain','-O',part,url}
    else
      argv={'/usr/bin/curl','--disable','--fail','--location','--proto','=https','--connect-timeout','15','--max-time','3300','--output',part,url}
    end
    print('Fetching verified native artifact '..asset.filename);io.stdout:flush()
    local rc=run(argv)
    if rc~=0 then
      fs.unlink(part)
      -- The original Matrix script logs download failure and exits zero.
      -- Preserve that optional integration behavior; native checks record it.
      io.stderr:write('Optional Matrix native download failed (exit '..rc..'); Gateway capability checks continue\n')
      return 0
    end
    assert(valid(part),'Native artifact SHA256/size mismatch')
    assert(fs.rename(part,file))
  else print('Using verified native artifact cache '..asset.filename)end
  local output=cwd..'/'..asset.filename
  local item=fs.lstat(output);assert(not item or item.type=='reg','Unsafe native output')
  assert(run({'/bin/cp','--',file,output})==0,'Cannot install verified native artifact')
  assert(valid(output),'Installed native artifact differs')
  return 0
end
local ok,rc=pcall(main)
if not ok then io.stderr:write(tostring(rc)..'\n');os.exit(1)end
os.exit(rc)
