#!/usr/bin/lua
local share=assert(arg[0]:match('^(.*)/[^/]+$'))
package.path=share..'/?.lua;/usr/share/mise-runtime/lib/?.lua;'..package.path
local s=require('system');local R=require('claude-runtime');local C=require('claude-package')
local function rest(start)local out={};for i=start,#arg do out[#out+1]=arg[i]end;return out end
local function admin()R.need(s.nixio.getuid()==0,'Claude Code runtime management requires administrator privileges')end

local ok,value=pcall(function()
 local action,base=arg[1],arg[2]
 if action=='status'then admin();return C.status(base)
 elseif action=='provider-status'then admin();return C.provider_status(base)
 elseif action=='prepare'then admin();return {data_dir=R.prepare(base)}
 elseif action=='install'then admin();return C.install(base)
 elseif action=='recover'then admin();return C.recover(base)
 elseif action=='installed'then admin();base=R.base(base);C.current(base);return {installed=true}
 elseif action=='npm'then admin();base=R.base(base);return R.exec_admin(base,'npm',rest(3))
 elseif action=='probe'then admin();base=R.base(base);return C.launch(base,arg[3],rest(4))
 elseif action=='release'then base=R.base(base);return C.launch(base,arg[3],rest(4))
 elseif action=='exec'then base=R.base(base);return C.launch(base,C.current(base),rest(3))
 elseif action=='terminal'then return C.terminal(base,arg[3])end
 R.need(false,'Unsupported Claude Code runtime operation')
end)
if not ok then io.stderr:write(type(value)=='table'and value.message or tostring(value),'\n');os.exit(1)end
if value~=nil then print(require('wire').encode(value))end
