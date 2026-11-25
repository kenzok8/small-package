local n=require('nixio')
local M={}
local function redirect(fd,target)
  -- uhttpd may enter Lua with fd 0 closed. pipe()/open() can reuse that
  -- number; dup2(fd,fd) followed by close would then discard stdin. Copy
  -- through a distinct descriptor so dup2 also clears close-on-exec.
  if fd:fileno()==target:fileno()then
    local copy=n.dup(fd);if not copy then os.exit(127)end
    fd:close();fd=copy
  end
  if not n.dup(fd,target)then os.exit(127)end
  fd:close()
end
function M.request(raw)
  local input_r,input_w=n.pipe();local output_r,output_w=n.pipe()
  if not input_r or not output_r then return nil,'Cannot open backend pipes'end
  local pid=n.fork()
  if not pid then return nil,'Cannot start backend'end
  if pid==0 then
    input_w:close();output_r:close();redirect(input_r,n.stdin);redirect(output_w,n.stdout)
    local err=n.open('/dev/null','w');if not err then os.exit(127)end;redirect(err,n.stderr)
    n.exec('/usr/sbin/mise-runtime','request');os.exit(127)
  end
  input_r:close();output_w:close()
  local offset=1
  while offset<=#raw do local size=input_w:write(raw:sub(offset));if not size or size<=0 then break end;offset=offset+size end
  input_w:close()
  local result={};local bytes=0
  while true do
    local part=output_r:read(8192);if not part or #part==0 then break end
    bytes=bytes+#part
    if bytes>2097152 then n.kill(pid,9);output_r:close();n.waitpid(pid);return nil,'Backend response too large'end
    result[#result+1]=part
  end
  output_r:close();n.waitpid(pid)
  return table.concat(result)
end
return M
