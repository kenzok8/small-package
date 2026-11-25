-- Public runtime contract, Lua 5.1. No filesystem changes or implicit defaults.
local M = { schema_version = 1 }
local tools = {
  node={glibc=true,musl=true},python={glibc=true,musl=true},
  go={native=true},rust={glibc=true,musl=true},zig={native=true},java={glibc=true}
}
local function demand(ok,message) if not ok then error(message,0) end end
local function object(t,allowed)
  demand(type(t)=='table','expected object')
  for k in pairs(t) do demand(type(k)=='string' and allowed[k],'unknown field: '..tostring(k)) end
end
local function text(v,max)
  return type(v)=='string' and #v>0 and #v<=(max or 256) and not v:find('%c')
end
function M.version(v)
  demand(text(v,80) and v:match('^%d+%.%d+%.%d+$'),'exact numeric version required')
  return v
end
function M.digest(v)
  demand(type(v)=='string' and #v==64 and v:match('^[a-f0-9]+$'),'invalid SHA256')
  return v
end
function M.path(p)
  demand(text(p,1024) and p:sub(1,5)=='/mnt/' and p:match('^/[A-Za-z0-9_./-]+$'),'persistent /mnt path required')
  demand(not p:find('//',1,true) and p:sub(-1)~='/','path must be normalized')
  for part in p:gmatch('[^/]+') do demand(part~='.' and part~='..','path traversal forbidden') end
  return p
end
function M.key(v)
  demand(text(v,240) and v:match('^[A-Za-z0-9][A-Za-z0-9._+%-]*$'),'invalid identifier')
  return v
end
function M.registration_tool(tool)
  demand(tools[tool],'unsupported tool')
  -- core:rust delegates to rustup even for an already-linked install. The
  -- generic backend registers our SDK without installing/changing toolchains.
  return tool=='rust' and 'http:istore-rust' or tool
end
function M.artifact(a)
  object(a,{url=true,sha256=true,bytes=true,format=true,strip=true,component=true})
  demand(text(a.url,2048) and a.url:match('^https://[A-Za-z0-9.-]+/[^%s]+$') and not a.url:find('[#@]'),'invalid HTTPS artifact URL')
  M.digest(a.sha256)
  demand(a.format=='tar.gz' or a.format=='tar.xz' or a.format=='tar.zst' or a.format=='deb','unsupported archive format')
  demand(type(a.strip)=='number' and a.strip>=0 and a.strip<=3 and a.strip%1==0,'invalid archive layout')
  demand(a.bytes==nil or (type(a.bytes)=='number' and a.bytes>0 and a.bytes%1==0),'invalid artifact size')
  if a.component~=nil then M.key(a.component) end
  return a
end
function M.entry(e)
  object(e,{id=true,tool=true,version=true,build=true,arch=true,abi=true,artifacts=true,artifact_set=true,npm=true,source=true,availability=true,reason=true,layout=true})
  M.key(e.id)
  demand(tools[e.tool] and tools[e.tool][e.abi],'unsupported tool/ABI')
  demand(e.arch=='x86_64' or e.arch=='aarch64','unsupported architecture')
  if e.tool=='java' then
    demand(text(e.version,80) and (e.version:match('^temurin%-21%.%d+%.%d+%+%d+$') or e.version:match('^temurin%-25%.%d+%.%d+%+%d+$')),'exact Temurin build required')
  else M.version(e.version) end
  M.key(e.build)
  demand(e.availability=='available' or e.availability=='unavailable','availability required')
  demand(text(e.source,2048) and e.source:match('^https://'),'source provenance required')
  if e.availability=='unavailable' then demand(text(e.reason,1024),'unavailable reason required');return e end
  demand(type(e.artifacts)=='table' and #e.artifacts>0,'artifact set required')
  for k,a in pairs(e.artifacts) do demand(type(k)=='number' and k>=1 and k<=#e.artifacts and k%1==0,'invalid artifact array');M.artifact(a) end
  M.digest(e.artifact_set)
  if e.tool=='node' then M.version(e.npm) else demand(e.npm==nil,'npm only applies to Node') end
  demand(e.reason==nil,'available artifact cannot have failure reason')
  demand(e.layout=='standard' or e.layout=='python' or e.layout=='rust-components' or e.layout=='zig','unsupported SDK layout')
  return e
end
function M.instance_id(e,npm,library)
  M.entry(e);demand(e.availability=='available','artifact unavailable')
  npm=npm or e.npm
  local parts={e.tool,e.version,e.arch,e.abi,e.build}
  if e.tool=='node' then M.version(npm);parts[#parts+1]='npm'..npm
  else demand(npm==nil,'npm not applicable') end
  if e.abi=='glibc' then M.key(library);parts[#parts+1]=library
  else demand(library==nil,'private glibc not applicable') end
  parts[#parts+1]=e.artifact_set
  return M.key(table.concat(parts,'-'))
end
local actions={
  plan={op=true,entry=true,npm=true,source=true},
  submit={op=true,id=true},inspect={op=true,id=true},remove={op=true,id=true},
  cancel={op=true,id=true},recover={op=true,id=true},wrap={op=true,id=true},
  read={op=true},catalog={op=true},['cache-clear']={op=true},['prepare-user']={op=true,uid=true,gid=true},
  ['library-remove']={op=true,id=true},settings={op=true,path=true,acceleration=true}
}
actions.ensure={op=true,entry=true,source=true,library=true}
actions['library-repair']={op=true,id=true,source=true}
function M.request(r)
  demand(type(r)=='table' and actions[r.op],'unsupported operation')
  object(r,actions[r.op])
  if r.op=='plan'or r.op=='ensure' then
    M.key(r.entry);demand(r.source=='origin' or r.source=='ks-cli','explicit download source required')
    if r.npm~=nil then M.version(r.npm) end
    if r.library~=nil then M.key(r.library)end
  elseif r.op=='library-repair'then
    M.key(r.id);demand(r.source=='origin'or r.source=='ks-cli','explicit download source required')
  elseif r.op=='prepare-user'then
    demand(type(r.uid)=='number'and r.uid>=0 and r.uid<2147483647 and r.uid%1==0,'invalid UID')
    demand(r.gid==nil or(type(r.gid)=='number'and r.gid>=0 and r.gid<2147483647 and r.gid%1==0),'invalid GID')
  elseif r.op=='settings' then
    M.path(r.path);demand(type(r.acceleration)=='boolean','acceleration must be boolean')
  elseif actions[r.op].id then M.key(r.id) end
  return r
end
function M.plan(p,revision,now)
  object(p,{schema_version=true,id=true,revision=true,catalog_revision=true,entry=true,instance=true,source=true,created=true,expires=true,path=true})
  demand(p.schema_version==M.schema_version,'unsupported plan schema')
  M.key(p.id);M.key(p.entry);M.key(p.instance);M.digest(p.catalog_revision);M.path(p.path)
  demand(type(p.revision)=='number' and p.revision%1==0 and p.revision>=0 and p.revision==revision,'stale plan revision')
  demand(type(now)=='number' and type(p.created)=='number' and type(p.expires)=='number' and p.created<=now and p.expires>now and p.expires-p.created<=300,'plan expired or invalid lifetime')
  demand(p.source=='origin' or p.source=='ks-cli','invalid source');return p
end
function M.binding(b)
  object(b,{schema_version=true,instance=true,artifact_set=true,library=true,receipt_sha256=true})
  demand(b.schema_version==M.schema_version,'unsupported binding schema');M.key(b.instance);M.digest(b.artifact_set);M.digest(b.receipt_sha256)
  if b.library~=nil then M.key(b.library) end
  return b
end
function M.receipt(r)
  object(r,{schema_version=true,instance=true,entry=true,npm=true,library=true,artifact_set=true,
    installed_at=true,verified=true,probes=true,mise_key=true,root=true})
  demand(r.schema_version==M.schema_version,'unsupported receipt schema')
  M.entry(r.entry);M.digest(r.artifact_set);M.path(r.root);M.key(r.instance)
  demand(r.entry.artifact_set==r.artifact_set,'receipt artifact set mismatch')
  demand(r.instance==M.instance_id(r.entry,r.npm,r.library),'receipt identity mismatch')
  demand(r.mise_key=='istore-'..r.instance,'receipt mise key mismatch')
  demand(type(r.installed_at)=='number' and r.installed_at>0 and r.installed_at%1==0,'invalid installation timestamp')
  demand(type(r.verified)=='boolean' and type(r.probes)=='table','verification state required')
  if r.verified then
    demand(r.probes.version=='passed' and r.probes.arch=='passed' and r.probes.abi=='passed' and r.probes.launcher=='passed','required probes not passed')
  end
  return r
end
M.tools=tools
return M
