#!/usr/bin/lua
local share=assert(arg[0]:match('^(.*)/[^/]+$'))
package.path=share..'/?.lua;/usr/share/mise-runtime/lib/?.lua;'..package.path
local s=require('system');local R=require('agentflow-runtime');local A=require('agentflow-agents')
local function rest(start)local out={};for i=start,#arg do out[#out+1]=arg[i]end;return out end
local ok,value=pcall(function()
 R.need(s.nixio.getuid()==0,'AgentFlow runtime management requires administrator privileges')
 local action,base=arg[1],arg[2]
 if action=='status'then return A.status(base)
 elseif action=='prepare'then R.prepare(base);return
 elseif action=='ensure'then return A.prepare_runtime(base)
 elseif action=='home'then print(R.home(R.base(base)));return
 elseif action=='install'then return A.install(base,arg[3])
 elseif action=='recover'then return A.recover(base)
 elseif action=='exec'then base=R.base(base);local a=R.agent(arg[3]);return A.launch(base,A.current(base,a),a,rest(4))
 elseif action=='probe'then return A.launch(R.base(base),arg[3],R.agent(arg[4]),rest(5))
 elseif action=='native'then return A.native(R.base(base),arg[3],rest(4))
 elseif action=='node'or action=='npm'or action=='npx'or action=='git'then return R.exec(R.base(base),action,rest(3))end
 R.need(false,'Unsupported AgentFlow runtime operation')
end)
if not ok then io.stderr:write(type(value)=='table'and value.message or tostring(value),'\n');os.exit(1)end
if value~=nil then print(require('wire').encode(value))end
