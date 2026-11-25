-- Non-secret compatibility view for old ks-cli versions that read root UCI.
local sys=require('system')
local M={}
local function option(name,fallback)
  local rc,value=sys.pipe_capture({'/sbin/uci','-q','get','istoreenhance.@istoreenhance[0].'..name})
  value=rc==0 and value:gsub('%s+$','')or fallback
  return value
end
function M.refresh(ctx,acceleration)
  local root=ctx.root..'/network';sys.mkdir(root,493);sys.mkdir(root..'/uci',493)
  local function port(name,fallback)
    local value=option(name,fallback);local number=tonumber(value)
    sys.need(number and number%1==0 and number>0 and number<=65535,'INVALID_INPUT','Invalid KSpeeder '..name)
    return tostring(number)
  end
  local enabled=option('enabled','0');sys.need(enabled=='0'or enabled=='1','INVALID_INPUT','Invalid KSpeeder enabled state')
  local public="config istoreenhance\n\toption enabled '"..enabled.."'\n\toption port '"..port('port','5443').."'\n\toption adminport '"..port('adminport','5003').."'\n\toption cache ''\n"
  sys.write(root..'/uci/istoreenhance',public,420)
  if acceleration==nil then
    local old=sys.decode(root..'/settings.json')
    if old then acceleration=old.acceleration
    else local rc,value=sys.pipe_capture({'/sbin/uci','-q','get','mise.main.acceleration'});acceleration=not(rc==0 and value:match('^0'))end
  end
  sys.need(type(acceleration)=='boolean','INTEGRITY','Invalid public acceleration policy')
  sys.write(root..'/settings.json',{schema_version=1,acceleration=acceleration},420)
end
return M
