local sys=require('system')
local contract=require('contract')
local M={}
function M.read(ctx)
  local result={values={},paths={},known={},pins={}}
  for tool in pairs(contract.tools)do result.known[tool]=true end
  local rc,legacy=sys.pipe_capture({'/sbin/uci','-q','get','mise.main.runtime_dir'})
  legacy=rc==0 and legacy:gsub('%s+$','')or''
  if legacy==''then legacy=ctx.root..'/home'end
  local scopes={}
  if legacy~=''then
    local valid=pcall(contract.path,legacy)
    if not valid then for tool in pairs(contract.tools)do result.known[tool]=false end;return result end
    scopes[#scopes+1]={home=legacy,data=legacy..'/.local/share/mise',config=legacy..'/.config/mise'}
  end
  for _,abi in ipairs({'glibc','musl','native'})do
    scopes[#scopes+1]={home=ctx.root..'/home',data=ctx.root..'/mise/'..sys.nixio.uname().machine..'-'..abi,
      config=ctx.root..'/users/0/mise/'..sys.nixio.uname().machine..'-'..abi..'/config'}
  end
  if ctx.default_scopes then
    scopes=ctx.default_scopes -- Internal test Interface, never JSON input.
    for tool in pairs(contract.tools)do result.known[tool]=true end
  end
  for _,scope in ipairs(scopes)do
    local config=sys.read(scope.config..'/config.toml')
    if config and not sys.fs.stat(scope.home)then
      -- This mise version silently ignores config when HOME is absent.
      -- Never infer "no defaults" from that empty result or create HOME on read.
      for tool in pairs(contract.tools)do result.known[tool]=false end
      config=nil
    end
    if config then
      local argv={'/usr/bin/env','-u','MISE_NODE_VERSION','-u','MISE_PYTHON_VERSION','-u','MISE_RUST_VERSION','-u','MISE_GO_VERSION','-u','MISE_ZIG_VERSION','-u','MISE_JAVA_VERSION',
        'HOME='..scope.home,'MISE_DATA_DIR='..scope.data,'MISE_CONFIG_DIR='..scope.config,'MISE_CACHE_DIR='..ctx.root..'/work/mise-default-query',
        'MISE_STATE_DIR='..ctx.root..'/work/mise-default-state','XDG_STATE_HOME='..scope.home..'/.local/state','MISE_DISABLE_TOOLS=rust','MISE_HIDE_UPDATE_WARNING=1',
        ctx.mise_bin or'/usr/bin/mise','ls','--global','--json'}
      local code,out=sys.capture(argv,ctx.root..'/work',15)
      local rows=code==0 and sys.json.parse(out)or nil
      if type(rows)~='table'then for tool in pairs(contract.tools)do result.known[tool]=false end
      else
        local function ingest(tool,r)
          if tool=='http:istore-rust'or tool=='http-istore-rust'or tool=='istore-rust'then tool='rust'end
          if contract.tools[tool]then
            result.values[tool]=result.values[tool]or r.version
            result.pins[tool]=result.pins[tool]or{};result.pins[tool][r.version]=true
            if r.install_path then result.paths[r.install_path]=true;local real=sys.fs.realpath(r.install_path);if real then result.paths[real]=true end end
          end
        end
        for tool,group in pairs(rows)do
          if type(tool)=='string' and type(group)=='table'then
            for _,r in ipairs(group)do ingest(tool,r)end
          elseif type(tool)=='number' and type(group)=='table'then ingest(group.name or group.tool,group)
          end
        end
      end
      -- core:rust has side effects in this pinned mise. Keep its discovery
      -- conservative rather than bootstrapping rustup during a read request.
      if config:match('[\n%s]rust%s*=')or config:match('^rust%s*=')then result.known.rust=false end
    end
  end
  return result
end
function M.protect(ctx,receipt)
  local d=M.read(ctx);sys.need(d.known[receipt.entry.tool],'BUSY','Default could not be determined safely; deletion is blocked')
  local pins=d.pins[receipt.entry.tool]or{}
  sys.need(not pins[receipt.mise_key] and not pins[receipt.instance] and not d.paths[ctx.root..'/environments/'..receipt.instance],'BUSY','mise global default cannot be removed')
  return false
end
return M
