-- Root installer commands use the common durable process/session handshake.
-- The private journal survives SIGKILL; recovery closes it before reaping.
package.path='/usr/share/mise-runtime/lib/?.lua;'..package.path
local s=require('system');local fs,n=s.fs,s.nixio
local function protected(path)
  local st=fs.lstat(path)
  s.need(st and st.type=='dir'and st.uid==0 and st.modedec==700 and fs.realpath(path)==path,'INTEGRITY','Invalid private installer process directory')
end
local function main()
  s.need(n.getuid()==0,'INVALID_INPUT','Administrator required')
  local action,path=arg[1],arg[2]
  protected(path)
  if action=='run'then
    s.need(path:match('/%.install%.[^/]+/commands%.[^/]+$'),'INVALID_INPUT','Invalid command journal path')
    -- Do not recreate this scope: recovery renames it to close the gate.
    s.command_scope=path
    local deadline=tonumber(arg[3])
    s.need(deadline and deadline>=1 and deadline<=3600 and deadline%1==0,'INVALID_INPUT','Invalid command deadline')
    local argv={};for i=4,#arg do argv[#argv+1]=arg[i]end
    return s.run(argv,{timeout=deadline})
  elseif action=='stop'then
    s.need(path:match('/%.install%.[^/]+$'),'INVALID_INPUT','Invalid transaction path')
    for _,name in ipairs(require('store').list(path))do
      if name:match('^commands%.')then
        local scope=path..'/'..name;protected(scope)
        local closed=path..'/commands.'..s.identifier('stopping')
        s.need(fs.rename(scope,closed),'OFFLINE','Cannot close command journal')
        -- A worker still writing its owner cannot rename into the old scope,
        -- so its child never receives permission to exec. Committed owners
        -- are all in the closed directory and are reaped before its removal.
        for file in fs.dir(closed)do
          if file:match('%.json$')then
            local owner=s.decode(closed..'/'..file)
            s.need(owner and type(owner.pid)=='number'and owner.pid>1 and owner.group==owner.pid and owner.session==owner.pid and type(owner.start)=='string'and type(owner.boot)=='string','INTEGRITY','Invalid command ownership record')
            s.stop_session(owner)
          end
        end
        s.remove(closed)
      end
    end
    return 0
  end
  s.fail('INVALID_INPUT','Unknown command ownership action')
end
local ok,code=pcall(main)
if not ok then io.stderr:write(type(code)=='table'and(code.code..': '..code.message)or tostring(code));io.stderr:write('\n');os.exit(1)end
os.exit(code)
