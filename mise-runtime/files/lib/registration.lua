local sys=require('system')
local contract=require('contract')
local M={}
function M.scope(ctx,entry)
  local arch=sys.nixio.uname().machine
  sys.need(entry.arch==arch,'UNSUPPORTED','Registration architecture differs from host')
  return {home=ctx.root..'/home',data=ctx.root..'/mise/'..arch..'-'..entry.abi,
    config=ctx.root..'/users/0/mise/'..arch..'-'..entry.abi..'/config',cache=ctx.root..'/users/0/cache/mise',state=ctx.root..'/users/0/state/mise'}
end
function M.register(ctx,receipt,work,log)
  local scope=M.scope(ctx,receipt.entry)
  for key,path in pairs(scope)do sys.mkdir(path,key=='data'and 493 or 448)end
  sys.need(sys.fs.chmod(scope.data,'755'),'OFFLINE','Cannot expose read-only managed mise registry')
  local env={HOME=scope.home,XDG_STATE_HOME=ctx.root..'/users/0/state',MISE_STATE_DIR=scope.state,MISE_DATA_DIR=scope.data,MISE_CONFIG_DIR=scope.config,MISE_CACHE_DIR=scope.cache,
    MISE_HIDE_UPDATE_WARNING='1',MISE_NOT_FOUND_AUTO_INSTALL='0',MISE_YES='1',MISE_ENV='production',MISE_PARANOID='1'}
  local tool=contract.registration_tool(receipt.entry.tool)..'@'..receipt.mise_key
  local sdk=ctx.root..'/environments/'..receipt.instance
  sys.need(sys.run({ctx.mise_bin,'link',tool,sdk},{env=env,cwd=work,output=log,append=true,timeout=30})==0,'PROBE_FAILED','mise link failed')
  local output=work..'/mise-where'
  sys.need(sys.run({ctx.mise_bin,'where',tool},{env=env,cwd=work,output=output,timeout=30})==0,'PROBE_FAILED','mise where failed')
  local path=(sys.read(output)or''):gsub('%s+$','')
  sys.need(sys.fs.realpath(path)==sdk,'PROBE_FAILED','mise registered another SDK')
  sys.need(sys.run({'chmod','-R','a+rX,go-w',scope.data},{output=log,append=true})==0,'OFFLINE','Cannot protect mise registry links')
end
function M.unregister(ctx,receipt)
  contract.receipt(receipt)
  local sdk=ctx.root..'/environments/'..receipt.instance
  local scope=M.scope(ctx,receipt.entry)
  local links={}
  local function visit(path,depth)
    local st=sys.fs.lstat(path);if not st then return end
    if st.type=='lnk'then
      -- Never invoke `mise uninstall`: it must not remove the shared SDK.
      if sys.fs.realpath(path)==sdk then links[#links+1]=path end
    elseif st.type=='dir'and depth<3 then
      for name in sys.fs.dir(path)do if name~='.'and name~='..'then visit(path..'/'..name,depth+1)end end
    end
  end
  visit(scope.data..'/installs',0)
  for _,path in ipairs(links)do sys.need(sys.fs.unlink(path),'OFFLINE','Cannot remove managed mise link')end
end
return M
