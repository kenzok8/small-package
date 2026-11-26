local s=require('system')
local R=require('claude-runtime')
local fs,n=s.fs,s.nixio
local M={}

local function selected_native()
 local selected=R.native[n.uname().machine]
 R.need(selected,'Unsupported Claude Code platform')
 return selected
end

local function release(base,path)
 local prefix=base..'/.runtime/releases/'
 R.need(path:sub(1,#prefix)==prefix and path:match('/releases/[%w._-]+$')and fs.realpath(path)==path,'Invalid Claude Code release path')
 R.directory(path)
 return path
end

local function package_root(dir,name)return dir..'/global/lib/node_modules/'..name end

function M.entry(base,dir)
 release(base,dir)
 local native=selected_native();local native_root=package_root(dir,native.package)
 R.file(native_root..'/package.json')
 local native_meta=s.decode(native_root..'/package.json')
 R.need(native_meta and native_meta.name==native.package and native_meta.version==R.version,'Claude Code native package metadata differs from policy')
 local path=fs.realpath(native_root..'/'..native.binary)
 R.need(path and path:sub(1,#native_root+1)==native_root..'/','Claude Code binary is missing or escapes its release')
 R.file(path)
 return path,native_meta,native
end

function M.current(base)
 local path=fs.realpath(base..'/.runtime/current');R.need(path,'Claude Code is not installed')
 release(base,path);R.file(path..'/receipt.json')
 local receipt=s.decode(path..'/receipt.json')
 R.need(receipt and receipt.schema_version==1 and receipt.package==R.package and receipt.version==R.version and receipt.verified,'Claude Code release is not verified')
 R.binding(base,path..'/runtime.json')
 return path,receipt
end

function M.launch(base,dir,args)
	local entry=M.entry(base,dir);local orchestrator_home=R.orchestrator_home()
	local home=orchestrator_home or R.home(base)
	if n.getuid()==0 and not orchestrator_home then
  local argv={'/usr/bin/su','-s','/bin/sh','-c','exec /usr/libexec/claude-runtime release "$@"','claude','--','sh',base,dir}
  for _,value in ipairs(args or{})do argv[#argv+1]=value end
  n.exec(unpack(argv));R.need(false,'Cannot lower privileges for Claude Code')
 end
	if not orchestrator_home then
		local uid=R.account();R.need(n.getuid()==uid,'Claude Code must run as its dedicated account')
	end
 n.setenv('HOME',home);n.setenv('XDG_CONFIG_HOME',home..'/.config');n.setenv('XDG_CACHE_HOME',home..'/.cache')
 n.setenv('XDG_DATA_HOME',home..'/.local/share');n.setenv('XDG_STATE_HOME',home..'/.local/state')
	n.setenv('USER',orchestrator_home and'root'or'claude');n.setenv('LOGNAME',orchestrator_home and'root'or'claude')
 local argv={entry};for _,value in ipairs(args or{})do argv[#argv+1]=value end
 n.exec(unpack(argv));R.need(false,'Cannot execute Claude Code')
end

function M.terminal(base,workspace_value)
 base=R.base(base);M.current(base)
 local uid=R.account();R.need(n.getuid()==uid,'Claude Code terminal must run as its dedicated account')
 local home=R.home(base);local workspace=R.workspace(base,workspace_value)
 n.setenv('HOME',home);n.setenv('USER','claude');n.setenv('LOGNAME','claude')
 n.setenv('PATH','/usr/local/bin:/usr/bin:/usr/sbin:/bin:/sbin')
 R.need(n.chdir(workspace),'Cannot enter the configured Claude Code workspace')
 io.stdout:write('\27[1;36mClaude Code for iStoreOS\27[0m\n工作区: '..workspace..'\n')
 io.stdout:write('首次登录请运行: claude auth login\n输入 claude 启动，输入 exit 退出终端。\n\n');io.stdout:flush()
 n.exec('/bin/sh','-i');R.need(false,'Cannot start terminal shell')
end

function M.install(value)
 local base=R.prepare(value);local manager=base..'/.runtime';local native=selected_native()
 R.need(fs.mkdir(manager..'/.install-lock','700'),'Another Claude Code install is active or interrupted')
 s.write(manager..'/.install-lock/owner.json',{schema_version=1,process=s.process(n.getpid())})
 local dir=manager..'/releases/'..s.identifier('claude-'..R.version)
 local ok,result=pcall(function()
  R.pin(base,true);s.mkdir(dir,493);s.write(dir..'/runtime.json',s.decode(manager..'/runtime.json'),420)
  local global=dir..'/global';s.mkdir(global,493)
  print('Installing '..native.package..'@'..R.version..' with fixed shared musl Node');io.stdout:flush()
  local rc=s.run({R.helper,'npm',base,'--prefix',global,'install','--global',native.package..'@'..R.version,
   '--ignore-scripts','--omit=optional','--no-audit','--no-fund'}, {cwd=dir,output=dir..'/install.log',append=true,timeout=1800})
  R.need(rc==0,'Claude Code native package install failed; inspect '..dir..'/install.log')
  R.need(s.run({'chmod','-R','u=rwX,go=rX',dir},{timeout=120})==0,'Cannot normalize Claude Code release permissions')
  local entry,native_meta=M.entry(base,dir);R.need(fs.chmod(entry,'755'),'Cannot make Claude Code executable')
  R.need(s.run({R.helper,'probe',base,dir,'--version'},{cwd=base..'/workspace',output=dir..'/version.log',timeout=30})==0,'Installed Claude Code failed its version probe')
  local version=s.read(dir..'/version.log')or'';R.need(version:find(R.version,1,true),'Claude Code did not report the pinned version')
  local binding=R.binding(base,dir..'/runtime.json')
  local receipt={schema_version=1,package=R.package,native_package=native.package,version=native_meta.version,instance=binding.instance,verified=true,installed_at=os.time()}
  s.write(dir..'/receipt.json',receipt,420);R.need(s.run({'chmod','-R','go-w',dir},{timeout=120})==0,'Cannot protect Claude Code release')
  local next=manager..'/current.new.'..n.getpid();R.need(fs.symlink(dir,next)and fs.rename(next,manager..'/current'),'Cannot activate Claude Code release')
  s.run({'rm','-rf',manager..'/installer-home/.cache/npm'},{timeout=120})
  return receipt
 end)
 fs.unlink(manager..'/.install-lock/owner.json');fs.rmdir(manager..'/.install-lock')
 if not ok then error(result,0)end
 return result
end

function M.recover(value)
 local base=R.base(value);local manager=base..'/.runtime';local lock=manager..'/.install-lock'
 if not fs.lstat(lock)then return {recovered=false}end
 R.file(lock..'/owner.json');local owner=s.decode(lock..'/owner.json')
 R.need(owner and owner.schema_version==1 and owner.process,'Unknown install lock; preserve it for inspection')
 R.need(not R.alive(owner.process),'A Claude Code install is still running')
 local journal=s.decode(manager..'/runtime-task.json')
 if journal then
  require('contract').path(journal.root);require('contract').key(journal.plan)
  for _,id in ipairs(require('store').list(journal.root..'/tasks'))do
   local task=s.decode(journal.root..'/tasks/'..id..'/task.json')
   if task and task.plan and task.plan.id==journal.plan and(task.status=='running'or task.status=='interrupted')then
    local input=manager..'/work/recover-'..n.getpid()..'.json';local output=input..'.out'
    s.write(input,{op=task.status=='running'and'cancel'or'recover',id=id})
    s.run({'/usr/sbin/mise-runtime','request'},{stdin=input,output=output,timeout=60,env={MISE_RUNTIME_ROOT=journal.root}})
    fs.unlink(input);fs.unlink(output)
   end
  end
  fs.unlink(manager..'/runtime-task.json')
 end
 R.need(fs.unlink(lock..'/owner.json')and fs.rmdir(lock),'Cannot recover the install lock')
 return {recovered=true}
end

function M.provider_status(value)
	local result={configured=false,installed=false,version=R.version}
	local ok,base=pcall(function()return R.base(value)end)
	if not ok then return result end
	result.configured=true
	local installed,_,receipt=pcall(M.current,base)
	if installed then result.installed=true;result.version=receipt.version end
	return result
end

function M.status(value)
 local result={configured=false,installed=false,authenticated=false,runtime={ready=false},version=R.version}
 local ok,base=pcall(function()return R.base(value)end)
 if not ok then result.error=type(base)=='table'and base.message or tostring(base);return result end
 result.configured=true
 local root=R.uci('mise.main.storage_root');result.runtime.storage_configured=root~=''
 if root==''then result.runtime.error='Persistent runtime storage is not configured'
 else
  local ready,binding,receipt=pcall(R.binding,base)
  if ready then result.runtime={ready=true,storage_configured=true,provider='mise-runtime',node=receipt.entry.version,npm=receipt.npm,abi=receipt.entry.abi,instance=binding.instance}
  else result.runtime.error=type(binding)=='table'and binding.message or tostring(binding)end
 end
 local owner=s.decode(base..'/.runtime/.install-lock/owner.json');result.interrupted=owner and owner.process and not R.alive(owner.process)or false
 local current,dir,installed=pcall(M.current,base)
 if current then
  result.installed=true;result.version=installed.version
  local output=base..'/.runtime/work/login-status-'..n.getpid()
  local rc=s.run({R.helper,'probe',base,dir,'auth','status'},{output=output,timeout=15})
  fs.unlink(output);result.authenticated=rc==0
 end
 result.data_dir=base;local workspace_ok,workspace=pcall(R.workspace,base);result.workspace=workspace_ok and workspace or''
 return result
end

return M
