module('luci.controller.mise',package.seeall)

function index()
  local page=entry({'admin','services','mise'},call('page'),_('运行时环境'),65)
  page.dependent=false;page.acl_depends={'luci-app-mise'}
  local api=entry({'admin','services','mise','request'},post('request'))
  api.leaf=true;api.acl_depends={'luci-app-mise'}
end

local function permitted(mode)
  local sid=require('luci.dispatcher').context.authsession
  if not sid then return false end
  local result=require('luci.util').ubus('session','access',{
    ubus_rpc_session=sid,scope='access-group',object='luci-app-mise',['function']=mode
  })
  return result and result.access==true
end

function page()
  require('luci.template').render('mise/index',{writable=permitted('write')})
end

local function failure(status,code,message)
  local http=require('luci.http')
  http.status(status);http.prepare_content('application/json')
  http.write_json({schema_version=1,ok=false,error={code=code,message=message}})
end

function request()
  local http=require('luci.http');local json=require('luci.jsonc')
  if http.getenv('REQUEST_METHOD')~='POST'then return failure(405,'INVALID_INPUT','POST required')end
  local token=require('luci.dispatcher').context.authtoken
  if type(token)~='string'or token==''or http.formvalue('token')~=token then return failure(403,'FORBIDDEN','CSRF verification failed')end
  local raw=http.formvalue('request')
  if type(raw)~='string'or #raw>32768 then return failure(400,'INVALID_INPUT','Invalid request size')end
  local r=json.parse(raw)
  local read={read=true,catalog=true,inspect=true,wrap=true}
  local write={plan=true,submit=true,settings=true,remove=true,['library-remove']=true,['library-repair']=true,['cache-clear']=true,cancel=true,recover=true}
  if type(r)~='table'or not(read[r.op]or write[r.op])then return failure(400,'INVALID_INPUT','Unsupported operation')end
  if not permitted(read[r.op]and'read'or'write')then return failure(403,'FORBIDDEN','Permission denied')end
  -- Fixed executable and stdin JSON. No shell, user command or filename is accepted.
  local body,message=require('luci.model.mise.transport').request(raw)
  if not body then return failure(503,'OFFLINE',message)end
  local response=json.parse(body)
  if type(response)~='table'or response.schema_version~=1 or type(response.ok)~='boolean'then return failure(503,'OFFLINE','Invalid backend response')end
  if not response.ok then
    local code=response.error and response.error.code
    http.status((code=='BUSY'or code=='STALE_PLAN')and 409 or(code=='OFFLINE'and 503 or 400))
  end
  http.prepare_content('application/json');http.header('Cache-Control','no-store');http.write(body)
end
