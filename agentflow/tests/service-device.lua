-- Capture the actual procd init contract without enabling a global service,
-- then run the pinned AgentFlow binary with exactly that environment.
package.path='/usr/share/agentflow/?.lua;/usr/share/mise-runtime/lib/?.lua;'..package.path
local s=require('system');local R=require('agentflow-runtime');local n=s.nixio
local base,work,binary=arg[1],arg[2],arg[3];R.base(base)
assert(work:match('^/mnt/[^/]+/acceptance/agentflow%-runtime%-[%w-]+$'))
assert(R.sha(binary)=='213d44adfde5537eada6ed24bc1d90dfc6e955f103d3650d3d6876d644dfbb48','official pinned binary required')
assert(s.fs.chmod(binary,'700'))
local port
for p=19035,19045 do local sock=n.socket('inet','stream');if sock:bind('127.0.0.1',p)then port=p end;sock:close();if port then break end end
assert(port,'test port unavailable')
local init=assert(s.read('/etc/init.d/agentflow')):gsub('/usr/sbin/agentflow',binary)
local script=init..'\n'..[[
config_load() { return 0; }
config_foreach() { "$1" main; }
config_get_bool() { enabled=1; }
config_get() {
 case "$3" in
 data_dir) data_dir=]]..R.quote(base)..[[;;
 host) host=127.0.0.1;;
 port) port=]]..port..[[;;
 esac
}
procd_open_instance() { :; }
procd_close_instance() { :; }
procd_set_param() {
 kind="$1"; shift
 case "$kind" in
 env) printf '%s\n' "$@" > ]]..R.quote(work..'/service-env')..[[;;
 command) printf '%s\n' "$@" > ]]..R.quote(work..'/service-command')..[[;;
 esac
}
start_service
]]
s.write(work..'/init-probe.sh',script,448)
assert(s.run({'/bin/sh',work..'/init-probe.sh'},{output=work..'/init-probe.log',timeout=30})==0,'init contract failed')
local env={};for line in s.read(work..'/service-env'):gmatch('[^\n]+')do local key,value=line:match('^([%w_]+)=(.*)$');assert(key);env[key]=value end
assert(env.HOME==R.home(base)and env.PATH:sub(1,#base+14)==base..'/.runtime/bin:')
assert(s.read(work..'/service-command')==binary..'\n')
local pid=n.fork();assert(pid)
if pid==0 then
 assert(n.setsid());assert(n.chdir(work))
 -- Use an isolated database, while retaining the init's environment contract.
 env.AGENT_FLOW_DATA=work..'/service-data'
 for k,v in pairs(env)do n.setenv(k,v)end
 local log=assert(n.open(work..'/service.log','w','600'));n.dup(log,n.stdout);n.dup(log,n.stderr);log:close()
 n.exec(binary);os.exit(127)
end
local owner
for _=1,50 do owner=s.process(pid);if owner and owner.session==pid then break end;n.nanosleep(0,10000000)end
assert(owner and owner.session==pid)
local health
local ok,error=pcall(function()
 for _=1,60 do
  local rc=s.run({'/usr/bin/curl','--disable','-fsS','--noproxy','*','--max-time','1','-o',work..'/health.json','http://127.0.0.1:'..port..'/healthz'},
   {output=work..'/health-probe.log',timeout=3})
  if rc==0 then health=s.decode(work..'/health.json');break end
  assert(s.alive(owner),'AgentFlow exited before health check');n.nanosleep(0,100000000)
 end
 assert(health and(health.status=='ok'or health.data and health.data.status=='ok'),'AgentFlow health endpoint failed')
end)
s.stop_session(owner);n.waitpid(pid)
local report={passed=ok,process_stopped=true,port=port,home=env.HOME,uses_application_wrap_path=true,
 scope='actual init environment captured; pinned binary health tested with isolated DB; no global service enable or package install',
 error=not ok and tostring(error)or nil}
s.write(work..'/service-device.json',report);print(s.json.stringify(report));os.exit(ok and 0 or 1)
