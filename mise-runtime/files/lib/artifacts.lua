local sys=require('system')
local contract=require('contract')
local M={}
function M.download(ctx,artifact,source,work,log,options)
  contract.artifact(artifact);options=options or {}
  local cache=ctx.root..'/cache/'..artifact.sha256
  if sys.fs.lstat(cache)then
    sys.need(sys.fs.lstat(cache).type=='reg','INTEGRITY','Unsafe cache entry')
    if sys.sha(cache,work)==artifact.sha256 then return cache end
    sys.need(sys.fs.unlink(cache),'OFFLINE','Cannot remove corrupt cache')
  end
  local part=work..'/download.part'
  local home=work..'/download-home';sys.mkdir(home,448);sys.mkdir(work..'/download-tmp',448)
  local environment={HOME=home,XDG_CONFIG_HOME=home..'/.config',XDG_CACHE_HOME=home..'/.cache',XDG_DATA_HOME=home..'/.local/share',TMPDIR=work..'/download-tmp',LD_LIBRARY_PATH='',LD_PRELOAD=''}
  local argv
  if source=='ks-cli'then
    argv={options.ks_cli or '/usr/bin/ks-cli','download','--mode',options.download_mode or 'auto','--timeout','600s','--progress','plain','-O',part}
    if options.admin_url then argv[#argv+1]='--admin-url';argv[#argv+1]=options.admin_url end
    argv[#argv+1]=artifact.url
  else argv={'curl','-fSL','--proto','=https','--proto-redir','=https','--connect-timeout','15','--max-time','600','--retry','1','-o',part,artifact.url}end
  sys.need(sys.run(argv,{output=log,append=true,timeout=620,env=environment})==0,'INTEGRITY','Artifact download failed')
  sys.need(sys.sha(part,work)==artifact.sha256,'INTEGRITY','Artifact SHA256 mismatch')
  sys.need(sys.fs.rename(part,cache),'OFFLINE','Cannot commit cache artifact')
  return cache
end
local function normalize(parts,value)
  for part in value:gmatch('[^/]+')do
    if part=='..'then if #parts==0 then return nil end;table.remove(parts)
    elseif part~='.' and part~=''then parts[#parts+1]=part end
  end
  return parts
end
function M.check_listing(list,strip)
  local count=0
  local links,paths={},{}
  for line in list:gmatch('[^\n]+')do
    -- SDK payload names must not contain whitespace/control characters. Parse
    -- GNU tar's numeric-owner/full-time listing before extracting anything.
    local kind,rest=line:match('^([%-%a])[^%s]*%s+(.+)$')
    sys.need(kind=='-' or kind=='d' or kind=='l','INTEGRITY','Unsupported archive entry type')
    local _,_,_,path=rest:match('^(%S+)%s+(%d+)%s+(%S+)%s+%S+%s+(.+)$')
    sys.need(path,'INTEGRITY','Invalid archive listing')
    local target
    if kind=='l'then path,target=path:match('^(.-) %-> (.+)$');sys.need(path and target,'INTEGRITY','Invalid symlink entry')end
    -- Go distributions include ! module escapes and UTF-8 source fixtures.
    -- High bytes cannot introduce ASCII separators/traversal. Keep whitespace,
    -- controls, quotes and backslashes (including tar escapes) forbidden.
    sys.need(path:match('^[A-Za-z0-9_./@+%%:=,!%-\128-\255]+$') and path:sub(1,1)~='/','INTEGRITY','Unsafe archive path')
    local parts={};for p in path:gmatch('[^/]+')do sys.need(p~='.' and p~='..','INTEGRITY','Archive traversal');parts[#parts+1]=p end
    local relative={};for i=strip+1,#parts do relative[#relative+1]=parts[i]end
    if #relative>0 then
      count=count+1
      local name=table.concat(relative,'/')
      sys.need(not paths[name],'INTEGRITY','Duplicate archive path')
      paths[name]=true
      if target then
        links[name]=target
        sys.need(target:match('^[A-Za-z0-9_./@+%%:=,!%-\128-\255]+$') and target:sub(1,1)~='/','INTEGRITY','Unsafe symlink target')
        table.remove(relative);sys.need(normalize(relative,target),'INTEGRITY','Symlink escapes extraction root')
      end
    end
  end
  -- A lexically internal symlink can still escape via another symlink.
  -- Payload may not write through a symlink parent; resolve link targets with
  -- the complete archive map before allowing any extraction.
  local function resolve(path,seen)
    local out={}
    for part in path:gmatch('[^/]+')do
      if part=='..'then sys.need(#out>0,'INTEGRITY','Symlink chain escapes root');table.remove(out)
      elseif part~='.'then
        out[#out+1]=part;local key=table.concat(out,'/')
        if links[key]then
          sys.need(not seen[key],'INTEGRITY','Cyclic archive symlink');seen[key]=true
          table.remove(out);local prefix=table.concat(out,'/')
          out=resolve((prefix~=''and prefix..'/'or'')..links[key],seen);seen[key]=nil
        end
      end
    end
    return out
  end
  for path in pairs(paths)do
    local parent=''
    local parts={};for part in path:gmatch('[^/]+')do parts[#parts+1]=part end
    for i=1,#parts-1 do parent=parent==''and parts[i]or parent..'/'..parts[i];sys.need(not links[parent],'INTEGRITY','Archive writes through symlink')end
    if links[path]then resolve(path,{})end
  end
  sys.need(count>0,'INTEGRITY','Archive has no payload')
  return count
end
function M.extract(archive,artifact,destination,work,log)
  contract.artifact(artifact)
  local rc,list=sys.capture({'tar','--numeric-owner','--full-time','--quoting-style=escape','-tvf',archive},work,120)
  sys.need(rc==0,'INTEGRITY','Cannot inspect archive')
  M.check_listing(list,artifact.strip)
  sys.need(not sys.fs.lstat(destination),'INTEGRITY','Candidate already exists')
  sys.mkdir(destination,448)
  sys.need(sys.run({'tar','--no-same-owner','--no-same-permissions','--delay-directory-restore','-xf',archive,'-C',destination,'--strip-components='..artifact.strip},{output=log,append=true,timeout=180})==0,'INTEGRITY','Archive extraction failed')
end
return M
