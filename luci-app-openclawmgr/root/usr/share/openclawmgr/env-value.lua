-- Read a literal credential assignment, never execute an application-owned file.
local fs=require('nixio.fs')
local json=require('luci.jsonc')
local path,key=arg[1],arg[2]
local allowed={OPENAI_API_KEY=true,ANTHROPIC_API_KEY=true,MINIMAX_API_KEY=true,MOONSHOT_API_KEY=true}
assert(allowed[key],'Unknown credential field')
local current=''
for part in path:gmatch('[^/]+')do
  assert(part~='.'and part~='..','Invalid credential path')
  current=current..'/'..part
  local st=fs.lstat(current)
  if not st then return end
  assert(st.type~='lnk','Refusing a credential symlink')
end
assert(fs.lstat(path).type=='reg','Credential source must be a regular file')
local file=io.open(path,'r');if not file then return end
for line in file:lines()do
  local name,value=line:match('^([A-Z_]+)=(.*)$')
  if name==key then
    if value:sub(1,1)=='"'then value=json.parse(value);assert(type(value)=='string','Invalid quoted credential')
    elseif value:sub(1,1)=="'"then
      assert(value:sub(-1)=="'",'Invalid quoted credential')
      value=value:sub(2,-2):gsub("'\\''", "'")
    end
    io.write(value);break
  end
end
file:close()
