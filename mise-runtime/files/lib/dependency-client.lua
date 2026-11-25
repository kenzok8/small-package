-- Application-side wait loop. No app inventory and no version selection.
local s=require('system')
local M={}
function M.ensure(root,entry,library,source,work,journal)
  local c=require('contract');c.path(root);c.key(entry)
  s.mkdir(work,448)
  local deadline=os.time()+1800
  local function request(value)
    local input=work..'/dependency-'..s.nixio.getpid()..'.json'
    local output=input..'.out';s.write(input,value)
    local rc=s.run({'/usr/sbin/mise-runtime','request'},{stdin=input,output=output,timeout=60,env={MISE_RUNTIME_ROOT=root}})
    local response=s.decode(output);s.fs.unlink(input);s.fs.unlink(output)
    s.need(rc==0 and response and response.ok,'DEPENDENCY_FAILED',response and response.error and response.error.message or'Runtime preparation request failed')
    return response.value
  end
  while os.time()<deadline do
    local result=request({op='ensure',entry=entry,library=library,source=source})
    local t=result.task;c.key(t.id)
    if journal and result.owned then s.write(journal,{schema_version=1,root=root,plan=t.plan.id,task=t.id})end
    while os.time()<deadline do
      t=require('tasks').get({root=root},t.id)
      s.need(t,'DEPENDENCY_FAILED','Runtime task disappeared')
      if t.status~='running'then break end
      s.need(s.alive(t.owner),'INTERRUPTED','Runtime task interrupted; recover it in Runtime Environments')
      s.nixio.nanosleep(1)
    end
    s.need(os.time()<deadline,'DEPENDENCY_FAILED','Runtime preparation timed out; inspect its task')
    s.need(t.status=='success','DEPENDENCY_FAILED',t.error and t.error.message or'Runtime preparation failed; inspect its task')
    if result.owned then
      if journal then s.fs.unlink(journal)end
      return t.result
    end
  end
  s.fail('DEPENDENCY_FAILED','Runtime preparation timed out')
end
return M
