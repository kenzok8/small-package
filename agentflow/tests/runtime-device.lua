-- Real installed shared SDK and application-owned agents; no model/API keys.
package.path='/usr/share/agentflow/?.lua;/usr/share/mise-runtime/lib/?.lua;'..package.path
local s=require('system');local R=require('agentflow-runtime');local A=require('agentflow-agents')
local base,work=arg[1],arg[2];R.base(base)
assert(work:match('^/mnt/[^/]+/acceptance/agentflow%-runtime%-[%w-]+$'))
s.mkdir(work,448)
local checks={};local config=s.read('/etc/config/mise')
local function check(name,fn)fn();checks[#checks+1]={name=name,passed=true}end
local function command(args,env)
 local rc=s.run(args,{output=work..'/probe.out',timeout=30,env=env})
 return rc,s.read(work..'/probe.out')or''
end
local ok,error=pcall(function()
 local b,r,lib=R.binding(base);local sdk=b.storage_root..'/environments/'..b.instance
 local receipt_hash=R.sha(sdk..'/receipt.json')
 check('fixed GNU Node binding and private glibc identity',function()
  assert(r.entry.version=='24.22.1'and r.npm=='11.19.1'and r.entry.abi=='glibc'and lib.version=='2.39')
 end)
 check('generated Node and npm commands use persistent HOME and application prefix',function()
  local rc,out=command({base..'/.runtime/bin/node','-p','process.env.HOME'},{HOME='/root'});assert(rc==0 and out:gsub('%s+$','')==R.home(base))
  rc,out=command({base..'/.runtime/bin/npm','prefix','--global'});assert(rc==0 and out:gsub('%s+$','')==base..'/.runtime/npm')
 end)
 local state=A.status(base)
 for _,agent in ipairs(R.agents)do
  check(agent.id..' actual command and package version agree',function()
   local found;for _,item in ipairs(state.agents)do if item.id==agent.id then found=item end end
   assert(found and found.installed and found.version==agent.version)
   local rc,out=command({base..'/.runtime/bin/'..agent.command,'--version'});assert(rc==0 and out:find(agent.version,1,true))
  end)
 end
 check('failed accelerated install preserves the current verified release',function()
  local before=s.fs.readlink(base..'/.runtime/agents/codexcli/current')
  local rc=command({R.helper,'install',base,'codexcli'},{ISTORE_RUNTIME_KS_CLI='/not-an-agentflow-test-client'})
  assert(rc~=0 and s.fs.readlink(base..'/.runtime/agents/codexcli/current')==before)
  assert(not s.fs.lstat(base..'/.runtime/.install-lock'))
  local _,receipt=A.current(base,R.agent('codexcli'));assert(receipt.version==R.agent('codexcli').version)
 end)
 check('live non-session-leader lock cannot be recovered; stale identity can',function()
  local isolated=work..'/RecoveryProbe';R.prepare(isolated)
  assert(not s.fs.access(isolated..'/.runtime/bin/codex','x'),'uninstalled agent must not appear runnable')
  local home=isolated..'/private-home';s.mkdir(home,448)
  local uci=R.uci;R.uci=function(key)if key=='mise.main.runtime_dir'then return home end;return uci(key)end
  local valid,path=pcall(R.home,isolated);R.uci=uci;assert(valid and path==home,'private mode-700 HOME must be accepted')
  local lock=isolated..'/.runtime/.install-lock';assert(s.fs.mkdir(lock,'700'))
  local process=s.process(s.nixio.getpid());s.write(lock..'/owner.json',{schema_version=1,process=process})
  local rc=command({R.helper,'recover',isolated});assert(rc~=0 and s.fs.lstat(lock))
  process.start='0';s.write(lock..'/owner.json',{schema_version=1,process=process})
  s.write(isolated..'/preserved-marker','keep')
  rc=command({R.helper,'recover',isolated});assert(rc==0 and not s.fs.lstat(lock)and s.read(isolated..'/preserved-marker')=='keep')
 end)
 check('application data cannot be placed in shared SDK storage',function()
  assert(not pcall(R.base,b.storage_root..'/AgentFlow'))
 end)
 check('system mise configuration and shared SDK receipt remain unchanged',function()
  assert(s.read('/etc/config/mise')==config and R.sha(sdk..'/receipt.json')==receipt_hash)
 end)
end)
local report={passed=ok,checks=checks,error=not ok and(type(error)=='table'and error.message or tostring(error))or nil}
s.write(work..'/runtime-device.json',report);print(s.json.stringify(report));os.exit(ok and 0 or 1)
