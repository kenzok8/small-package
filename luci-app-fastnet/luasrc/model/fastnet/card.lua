-- The public authenticated adapter. No shell commands, core tokens or probes.
local M = {}
local SOCKET = "/var/run/fastnet-card.sock"
local STATE = "/etc/fastnet/card-state.json"
local MAX_BODY, MAX_RESPONSE = 1024, 8192

local function socket_request(method, path, body)
 local nixio = require "nixio"
 local socket = nixio.socket("unix", "stream")
 if not socket then return nil, nil, "service_unavailable" end
 local deadline = os.time() + 6
 local function timeout()
  local remaining = deadline - os.time()
  if remaining <= 0 then return false end
  socket:setopt("socket", "sndtimeo", remaining)
  socket:setopt("socket", "rcvtimeo", remaining)
  return true
 end
 local function fail(reason) socket:close(); return nil, nil, reason end
 timeout()
 if not socket:connect(SOCKET) then return fail("service_unavailable") end
 body = body or ""
 local request = method .. " /api/card/" .. path .. " HTTP/1.0\r\nHost: localhost\r\nConnection: close\r\nContent-Type: application/json\r\nContent-Length: " .. #body .. "\r\n\r\n" .. body
 local offset = 1
 while offset <= #request do
  if not timeout() then return fail("upstream_timeout") end
  local sent = socket:send(request:sub(offset))
  if not sent or sent <= 0 then return fail("upstream_timeout") end
  offset = offset + sent
 end
 local chunks, length = {}, 0
 while true do
  if not timeout() then return fail("upstream_timeout") end
  local chunk = socket:recv(2048)
  if not chunk then return fail("upstream_timeout") end
  if chunk == "" then break end
  length = length + #chunk
  if length > MAX_RESPONSE + 4096 then return fail("upstream_too_large") end
  chunks[#chunks + 1] = chunk
 end
 socket:close()
 local raw = table.concat(chunks)
 local headers, response = raw:match("^(.-)\r\n\r\n(.*)$")
 local status = headers and tonumber(headers:match("^HTTP/1%.[01]%s+(%d%d%d)"))
 if not status or not headers:lower():match("content%-type:%s*application/json") or #response > MAX_RESPONSE then return nil, nil, "invalid_upstream" end
 return status, response
end

local function defaults()
 local nixio, fs = require "nixio", require "nixio.fs"
 local function read(path, maximum)
  local file = nixio.open(path, "r")
  if not file then return nil end
  local parts, length = {}, 0
  while true do
   local part=file:read(4096)
   if not part then file:close();return nil end
   if part=="" then break end
   length=length+#part
   if length>maximum then file:close();return nil end
   parts[#parts+1]=part
  end
  file:close();return table.concat(parts)
 end
 return {http=require "luci.http",ctx=require("luci.dispatcher").context,json=require "luci.jsonc",fs=fs,
  enabled=function() return require("luci.model.uci").cursor():get_first("fastnet", "fastnet", "enabled") ~= "0" end,
  state=function() return read(STATE, 128*1024) end,request=socket_request}
end

function M.new(deps)
 local d = deps or defaults()
 local http, ctx, json = d.http, d.ctx, d.json
 local function reply(status, value)
  http.status(status)
  http.prepare_content("application/json")
  http.header("Cache-Control", "no-store")
  http.header("X-Content-Type-Options", "nosniff")
  http.write(type(value)=="string" and value or json.stringify(value))
 end
 local function error_reply(status, code) return reply(status, {error=code}) end
 -- jsonc drops null object members when decoding. Forward live core JSON as
 -- bytes; reconstruct nullable fields explicitly only for a stopped service.
 local function atom(value) return value==nil and "null" or json.stringify(value) end
 local function measurement(value)
  if type(value)~="table" then return '{"status":"not_tested","value":null,"measuredAt":null,"error":null}' end
  return '{"status":'..atom(value.status)..',"value":'..atom(value.value)..',"measuredAt":'..atom(value.measuredAt)..',"error":'..atom(value.error)..',"runId":'..atom(value.runId)..'}'
 end
 local function stopped_summary(reason)
  local raw=d.state();local disk=raw and json.parse(raw) or nil
  local latest=type(disk)=="table" and (disk.schemaVersion==1 or disk.schemaVersion==2) and disk.latest or nil
  local result="null"
  if type(latest)=="table" then
   result='{"runId":'..atom(latest.runId)..',"measuredAt":'..atom(latest.measuredAt)..',"download":'..measurement(latest.download)..',"upload":'..measurement(latest.upload)..',"nat":'..measurement(latest.nat)..',"ipv6":'..measurement(latest.ipv6)
   if type(latest.bandwidth)=="table" then result=result..',"bandwidth":'..json.stringify(latest.bandwidth) end
   result=result..'}'
  end
  local state = d.enabled() and "unavailable" or "disabled"
  return reply(200,'{"schemaVersion":1,"instanceId":"","service":{"state":'..atom(state)..',"reason":'..atom(reason)..'},"latest":'..result..',"latestResults":'..json.stringify(type(disk)=="table" and disk.latestResults or {})..',"task":null}')
 end
 return {handle=function(_, action)
  if type(ctx.authsession)~="string" or ctx.authsession=="" then return error_reply(401,"unauthenticated") end
  if ctx.authuser~="root" then return error_reply(403,"forbidden") end
  local writing=action=="run" or action=="cancel"
  local method=http.getenv("REQUEST_METHOD")
  if method~=(writing and "POST" or "GET") then return error_reply(405,"method") end
  if not d.fs.access("/etc/config/fastnet") then return error_reply(503,"installation_incomplete") end
  if not d.fs.access("/usr/sbin/FastNet") then return error_reply(503,"core_missing") end
  local body, path = nil, action
  if writing then
   local site=http.getenv("HTTP_SEC_FETCH_SITE")
   if site and site~="same-origin" and site~="none" then return error_reply(403,"cross_origin") end
   local origin=http.getenv("HTTP_ORIGIN")
   local secure=http.getenv("HTTPS");local scheme=(secure=="on" or secure=="1") and "https" or "http"
   if origin and origin~=scheme.."://"..(http.getenv("HTTP_HOST") or "") then return error_reply(403,"cross_origin") end
   -- Some uhttpd builds omit custom CGI headers. The standard LuCI query
   -- token is read without consuming the JSON request body.
   local csrf=http.getenv("HTTP_X_CSRF_TOKEN") or http.getenv("HTTP_X-CSRF-TOKEN") or http.formvalue("token",true)
   if type(ctx.authtoken)~="string" or ctx.authtoken=="" or csrf~=ctx.authtoken then return error_reply(403,"csrf") end
   local kind=(http.getenv("CONTENT_TYPE") or ""):match("^%s*([^;]+)")
   if kind~="application/json" then return error_reply(422,"content_type") end
   local size=tonumber(http.getenv("CONTENT_LENGTH"))
   if size and size>MAX_BODY then return error_reply(413,"body_too_large") end
   body=http.content()
   if type(body)~="string" or #body>MAX_BODY then return error_reply(413,"body_too_large") end
   local key=action=="run" and "idempotencyKey" or "id"
   local value=body:match('^%s*{%s*"'..key..'"%s*:%s*"([A-Za-z0-9_-]+)"%s*}%s*$')
   if not value or #value>(action=="run" and 64 or 96) or #value<(action=="run" and 16 or 1) then return error_reply(422,"invalid_request") end
  elseif action=="task" then
   local id=http.formvalue("id")
   if type(id)~="string" or #id<1 or #id>96 or not id:match("^[A-Za-z0-9_-]+$") then return error_reply(422,"invalid_id") end
   path="task?id="..id
  elseif action~="summary" then return error_reply(404,"not_found") end
  local status, raw, reason=d.request(method,path,body)
  if not status then
   if action=="summary" and reason=="service_unavailable" then return stopped_summary(reason) end
   return error_reply(reason=="service_unavailable" and 503 or 502,reason or "invalid_upstream")
  end
  local value=type(raw)=="string" and #raw<=MAX_RESPONSE and json.parse(raw) or nil
  if type(value)~="table" then return error_reply(502,"invalid_upstream") end
  if status>=400 then
   local allowed={busy=true,not_found=true,invalid_id=true,invalid_request=true,persistence_failed=true,local_only=true,method=true}
   return error_reply(status,allowed[value.error] and value.error or "core_error")
  end
  if action=="summary" then
   if value.schemaVersion~=1 or type(value.service)~="table" then return error_reply(502,"invalid_upstream") end
  elseif type(value.id)~="string" or type(value.state)~="string" then return error_reply(502,"invalid_upstream") end
  return reply(status,raw)
 end}
end
return M
