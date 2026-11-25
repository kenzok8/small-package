-- Public routing metadata only. UCI configuration remains private to root.
local s=require('system')
local c=require('contract')
local M={path='/var/run/mise-runtime-root.json'}
function M.publish(root)
  s.need(s.nixio.getuid()==0,'FORBIDDEN','Administrator required')
  c.path(root);s.write(M.path,{schema_version=1,root=root},420)
end
function M.current()
  if s.nixio.getuid()==0 then
    local rc,out=s.pipe_capture({'/sbin/uci','-q','get','mise.main.storage_root'})
    s.need(rc==0,'OFFLINE','Runtime repository is not configured')
    return c.path(out:gsub('%s+$',''))
  end
  local st=s.fs.lstat(M.path)
  s.need(st and st.type=='reg'and st.uid==0 and math.floor((math.floor(st.modedec/10)%10)/2)%2==0 and math.floor((st.modedec%10)/2)%2==0,'OFFLINE','Restart the application to publish the selected repository')
  local r=s.decode(M.path)
  s.need(r and r.schema_version==1,'INTEGRITY','Invalid public repository metadata')
  return c.path(r.root)
end
return M
