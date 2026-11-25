package.path='/usr/share/mise-runtime/lib/?.lua;'..package.path
local s=require('system');local fs,n=s.fs,s.nixio
local function main()
  local self=assert(arg[1],'Fixed entry path missing')
  local base=assert(self:match('^(.*)/bin/[^/]+$'),'Invalid fixed Python entry')
  local sdk=s.decode(base..'/.python-sdk.json')
  local ref=sdk or s.decode(base..'/.istore-python-runtime.json')
  s.need(ref and ref.schema_version==1,'INVALID_INPUT','Python launcher identity is missing; use a verified fixed environment')
  if sdk then
    s.need(fs.stat(base).uid==0,'INTEGRITY','Fixed SDK ownership changed')
    n.setenv('ISTORE_PYTHON_VENV','')
  else
    n.setenv('ISTORE_PYTHON_VENV',base)
    if not os.getenv('ISTORE_RUNTIME_HOME')and ref.home then n.setenv('ISTORE_RUNTIME_HOME',ref.home)end
  end
  n.setenv('MISE_RUNTIME_ROOT',ref.storage_root)
  local program={'/usr/sbin/mise-runtime','exec',ref.instance,'python'}
  for i=2,#arg do program[#program+1]=arg[i]end
  n.exec(unpack(program));s.fail('OFFLINE','Cannot execute fixed Python runtime')
end
local ok,error=pcall(main)
if not ok then io.stderr:write(type(error)=='table'and error.message or tostring(error));io.stderr:write('\n');os.exit(1)end
