local n=require('nixio')
local fs=require('nixio.fs')
local json=require('luci.jsonc')
local M={fs=fs,nixio=n,json=json}
function M.identifier(prefix)
  local f=assert(io.open('/dev/urandom','rb'));local bytes=assert(f:read(12));f:close()
  local hex=bytes:gsub('.',function(c)return string.format('%02x',c:byte())end)
  return prefix..'-'..os.time()..'-'..hex
end
function M.fail(code,message) error({code=code,message=message},0) end
function M.need(ok,code,message) if not ok then M.fail(code,message) end;return ok end
function M.read(path)
  local f=io.open(path,'rb');if not f then return nil end
  local s=f:read('*a');f:close();return s
end
function M.decode(path)
  local st=fs.lstat(path);if st then M.need(st.type=='reg','INTEGRITY','Refusing non-regular JSON: '..path)end
  local data=M.read(path);if not data then return nil end
  local value=json.parse(data);M.need(type(value)=='table','INTEGRITY','Invalid JSON: '..path);return value
end
function M.pipe_capture(argv)
  local rd,wr=n.pipe();M.need(rd and wr,'OFFLINE','pipe failed')
  local pid=n.fork();M.need(pid,'OFFLINE','fork failed')
  if pid==0 then rd:close();n.dup(wr,n.stdout);wr:close();n.exec(unpack(argv));os.exit(127)end
  wr:close();local result={}
  while true do local data=rd:read(4096);if not data or #data==0 then break end;result[#result+1]=data end
  rd:close();local _,kind,code=n.waitpid(pid)
  return kind=='exited' and code or 125,table.concat(result)
end
function M.mkdir(path,mode)
  local st=fs.lstat(path)
  if st then M.need(st.type=='dir','INTEGRITY','Directory is not a real directory: '..path);return end
  local parent=path:match('^(.*)/[^/]+$')
  if parent and parent~='' then M.mkdir(parent,mode) end
  M.need(fs.mkdir(path,string.format('%o',mode or 448)),'OFFLINE','Cannot create directory: '..path)
  M.need(fs.chmod(path,string.format('%o',mode or 448)),'OFFLINE','Cannot set directory permissions: '..path)
end
function M.write(path,value,mode)
  M.need(not fs.lstat(path) or fs.lstat(path).type=='reg','INTEGRITY','Refusing non-regular file: '..path)
  local tmp=path..'.new.'..n.getpid()
  local f=n.open(tmp,'w','600');M.need(f,'OFFLINE','Cannot create '..tmp)
  local data=type(value)=='string' and value or json.stringify(value)
  local offset=1
  while offset<=#data do local size=f:write(data:sub(offset));M.need(size and size>0,'OFFLINE','Short write');offset=offset+size end
  M.need(fs.chmod(tmp,string.format('%o',mode or 384)),'OFFLINE','Cannot set file permissions: '..tmp)
  M.need(f:sync(),'OFFLINE','Cannot sync '..tmp);f:close()
  M.need(fs.rename(tmp,path),'OFFLINE','Cannot commit '..path)
  local parent=n.open(path:match('^(.*)/[^/]+$'),'r')
  M.need(parent and parent:sync(),'OFFLINE','Cannot sync parent directory');parent:close()
end
function M.run(argv,options)
  options=options or {}
  M.need(type(argv)=='table' and #argv>0,'INVALID_INPUT','argv required')
  for _,v in ipairs(argv)do M.need(type(v)=='string' and not v:find('%z'),'INVALID_INPUT','Invalid argv')end
  -- The child may not execute until its independent session is journaled.
  -- A worker crash before acknowledgement closes the pipe, so no command runs
  -- without a durable ownership record.
  local ready_r,ready_w=n.pipe();local gate_r,gate_w=n.pipe()
  M.need(ready_r and gate_r,'OFFLINE','Cannot create process handshake')
  local pid=n.fork();M.need(pid,'OFFLINE','fork failed')
  if pid==0 then
    ready_r:close();gate_w:close()
    if not n.setsid()then os.exit(125)end
    ready_w:write('R');ready_w:close()
    local granted=gate_r:read(1);gate_r:close()
    if granted~='G'then os.exit(125)end
    if options.cwd then n.chdir(options.cwd) end
    for k,v in pairs(options.env or {})do n.setenv(k,v)end
    if options.output then
      local f=n.open(options.output,options.append and 'a' or 'w','600')
      if not f then os.exit(125)end
      n.dup(f,n.stdout);n.dup(f,n.stderr);f:close()
    end
    if options.stdin then local f=n.open(options.stdin,'r');if not f then os.exit(125)end;n.dup(f,n.stdin);f:close() end
    if options.uid then
      if not n.setgid(options.gid or options.uid)or not n.setuid(options.uid)then os.exit(125)end
    end
    local args=argv
    if args[1]:sub(1,1)~='/'then
      local found
      for _,dir in ipairs({'/usr/sbin','/usr/bin','/sbin','/bin'})do
        if fs.access(dir..'/'..args[1],'x')then found=dir..'/'..args[1];break end
      end
      if found then args[1]=found end
    end
    n.exec(unpack(args))
    io.stderr:write('Cannot execute '..args[1]..'\n')
    os.exit(127)
  end
  ready_w:close();gate_r:close()
  local ready=ready_r:read(1);ready_r:close()
  M.need(ready=='R','OFFLINE','Command did not establish its session')
  local owner=M.process(pid)
  M.need(owner and owner.group==pid and owner.session==pid,'OFFLINE','Command ownership unavailable')
  local journal=M.command_scope and M.command_scope..'/'..pid..'-'..owner.start..'.json'
  local registered,err=pcall(function()if journal then M.write(journal,owner)end end)
  if not registered then gate_w:close();n.waitpid(pid);error(err,0)end
  gate_w:write('G');gate_w:close()
  local ticks=0
  while true do
    local waited,kind,code=n.waitpid(pid,'nohang')
    if waited==pid then
      M.stop_session(owner)
      if journal then fs.unlink(journal)end
      return kind=='exited' and code or 128+(code or 0)
    end
    if options.timeout and ticks>=options.timeout*20 then
      M.stop_session(owner);n.waitpid(pid)
      if journal then fs.unlink(journal)end
      return 124
    end
    n.nanosleep(0,50000000);ticks=ticks+1
  end
end
function M.capture(argv,work,timeout)
  local out=work..'/capture.'..n.getpid()
  local rc=M.run(argv,{output=out,timeout=timeout or 30})
  local data=M.read(out)or'';fs.unlink(out)
  return rc,data
end
function M.sha(path,work)
  local rc,data=M.capture({'sha256sum',path},work)
  M.need(rc==0,'INTEGRITY','Cannot hash '..path)
  local hash=data:match('^([a-f0-9]+)');M.need(hash and #hash==64,'INTEGRITY','Invalid SHA256 output');return hash
end
function M.remove(path)
  local st=fs.lstat(path);if not st then return end
  if st.type=='dir' then
    for name in fs.dir(path)do if name~='.' and name~='..' then M.remove(path..'/'..name)end end
    M.need(fs.rmdir(path),'OFFLINE','Cannot remove directory '..path)
  else M.need(fs.unlink(path),'OFFLINE','Cannot remove file '..path)end
end
function M.boot_id()return (M.read('/proc/sys/kernel/random/boot_id')or''):gsub('%s+$','')end
function M.process(pid)
  if type(pid)~='number' or pid<2 or pid%1~=0 then return nil end
  local raw=M.read('/proc/'..pid..'/stat');if not raw then return nil end
  local tail=raw:match('^%d+ %b() (.*)$');if not tail then return nil end
  local a={};for v in tail:gmatch('%S+')do a[#a+1]=v end
  return {pid=pid,state=a[1],parent=tonumber(a[2]),group=tonumber(a[3]),session=tonumber(a[4]),start=a[20],boot=M.boot_id()}
end
function M.session_members(owner)
  if not owner or owner.boot~=M.boot_id()then return {}end
  local leader=M.process(owner.pid)
  M.need(not leader or(leader.start==owner.start and leader.session==owner.pid),'BUSY','Process identity changed; preserving journal')
  local result={}
  for name in fs.dir('/proc')do
    local p=M.process(tonumber(name))
    if p and p.session==owner.pid and p.state~='Z'then result[#result+1]=p end
  end
  return result
end
function M.stop_session(owner)
  for _,signal in ipairs({15,9})do
    local members=M.session_members(owner)
    if #members==0 then return end
    for _,p in ipairs(members)do
      local live=M.process(p.pid)
      if live and live.start==p.start and live.session==owner.pid then n.kill(p.pid,signal)end
    end
    for _=1,40 do
      n.waitpid(owner.pid,'nohang')
      if #M.session_members(owner)==0 then return end
      n.nanosleep(0,50000000)
    end
  end
  M.need(#M.session_members(owner)==0,'BUSY','Owned command processes remain; journal retained')
end
function M.alive(owner)
  local p=owner and M.process(owner.pid)
  return p and p.boot==owner.boot and p.start==owner.start and p.group==owner.pid and p.state~='Z'
end
return M
