-- Standard native Go/Zig distributions. No private libc or implicit tool switch.
local s=require('system');local fs=s.fs
local M={}
local function need(ok,message)return s.need(ok,'PROBE_FAILED',message)end
function M.command(root,id,command,args,home,sdk,r,env,acceleration,share)
 local program
 if r.entry.tool=='go'then
  env.GOROOT=sdk;env.GOTOOLCHAIN='local';env.GOENV='off'
  env.GOPATH=home..'/.local/go/'..id;env.GOBIN=env.GOPATH..'/bin'
  env.GOCACHE=home..'/.cache/go/'..id..'/build';env.GOMODCACHE=home..'/.cache/go/mod'
  env.GOTMPDIR=home..'/.cache/go/'..id..'/tmp';env.CGO_ENABLED=os.getenv('CGO_ENABLED')or'0'
  for _,key in ipairs({'GOPATH','GOBIN','GOCACHE','GOMODCACHE','GOTMPDIR'})do s.mkdir(env[key],448)end
  env.PATH=sdk..'/bin:'..env.GOBIN..':/usr/sbin:/usr/bin:/sbin:/bin'
  if command=='go'or command=='gofmt'then
   program={sdk..'/bin/'..command..'.real'}
   local at=1
   if command=='go'and(args[1]=='-C'or args[1]=='--C')then at=3
   elseif command=='go'and args[1]and args[1]:match('^%-%-?C=')then at=2 end
   if command=='go'and args[at]=='env'then
    for i=at+1,#args do
     local value=args[i]
     s.need(not(value:match('^%-%-?[wu]$')or value:match('^%-%-?[wu]=')),'UNSUPPORTED','Fixed runtime uses GOENV=off; set process environment instead of writing user-wide Go configuration')
    end
   end
   local download=command=='go'and(args[at]=='get'or(args[at]=='mod'and args[at+1]=='download'))
   if download and acceleration=='ks-cli'then
    env.PATH=share..'/native/bin:'..sdk..'/native/bin:'..env.PATH
    program={'/usr/bin/ks-cli','go'}
   end
  end
 elseif r.entry.tool=='zig'then
  local cwd=fs.realpath('.');need(cwd and cwd:sub(1,1)=='/','Working directory unavailable')
  env.ZIG_LIB_DIR=sdk..'/lib';env.ZIG_GLOBAL_CACHE_DIR=home..'/.cache/zig/'..id..'/global'
  env.ZIG_LOCAL_CACHE_DIR=home..'/.cache/zig/'..id..'/local'..cwd
  env.TMPDIR=home..'/.cache/zig/'..id..'/tmp'
  for _,key in ipairs({'ZIG_GLOBAL_CACHE_DIR','ZIG_LOCAL_CACHE_DIR','TMPDIR'})do s.mkdir(env[key],448)end
  if command=='zig'then program={sdk..'/zig.real'}end
 end
 if command=='--shell'then program={'/bin/sh'}end
 need(program,'Unsupported fixed '..r.entry.tool..' command')
 return program,args
end
function M.install(ctx,t,entry,work,log)
 local tasks=require('tasks');local contract=require('contract');local artifacts=require('artifacts')
 local id=contract.instance_id(entry);need(id==t.plan.instance,'Native SDK plan identity changed')
 local sdk=ctx.root..'/environments/'..id;need(not fs.lstat(sdk),'SDK already exists')
 s.mkdir(sdk,448);t.pending_environment={id=id,inode=fs.stat(sdk).ino};tasks.phase(ctx,t,'download')
 local archive=artifacts.download(ctx,entry.artifacts[1],t.plan.source,work,log,ctx.download_options)
 tasks.phase(ctx,t,'extract');artifacts.extract(archive,entry.artifacts[1],sdk..'/payload',work,log)
 for _,name in ipairs(require('store').list(sdk..'/payload'))do need(fs.rename(sdk..'/payload/'..name,sdk..'/'..name),'Cannot stage native SDK')end
 need(fs.rmdir(sdk..'/payload'),'Cannot remove empty payload')
 local function wrap(command,actual)
  require('libraries').elf(actual,entry.arch)
  local destination=entry.tool=='zig'and sdk..'/zig.real'or actual..'.real'
  need(fs.rename(actual,destination),'Cannot reserve native executable')
  s.write(sdk..'/bin/'..command,require('adapters').launcher(ctx,id,command),493)
 end
 s.mkdir(sdk..'/bin',493)
 if entry.tool=='go'then
  wrap('go',sdk..'/bin/go');wrap('gofmt',sdk..'/bin/gofmt')
  s.mkdir(sdk..'/native/bin',493)
  s.write(sdk..'/native/bin/go','#!/bin/sh\nexec "'..sdk..'/bin/go.real" "$@"\n',493)
 else wrap('zig',sdk..'/zig')end
 local receipt={schema_version=1,instance=id,entry=entry,artifact_set=entry.artifact_set,installed_at=os.time(),verified=false,probes={},mise_key='istore-'..id,root=ctx.root}
 s.write(sdk..'/receipt.json',receipt,420)
 need(s.run({'chmod','-R','a+rX,go-w',sdk},{output=log,append=true})==0,'Cannot protect native SDK')
 tasks.phase(ctx,t,'probe')
 local project=work..'/project';s.mkdir(project,448)
 local function probe(command,args,timeout)
  local argv={sdk..'/bin/'..command};for _,a in ipairs(args)do argv[#argv+1]=a end
  local out=work..'/native-probe'
  local rc=s.run(argv,{cwd=project,env={MISE_RUNTIME_PROBE=t.id,ISTORE_RUNTIME_ACCELERATION='origin'},output=out,timeout=timeout or 60})
  need(rc==0,command..' probe failed: '..(s.read(out)or''));return(s.read(out)or''):gsub('%s+$','')
 end
 local expected_arch=entry.arch=='x86_64'and'amd64'or'arm64'
 if entry.tool=='go'then
  need(probe('go',{'version'})=='go version go'..entry.version..' linux/'..expected_arch,'Go version/host differs')
  local actual=s.json.parse(probe('go',{'env','-json','GOROOT','GOVERSION','GOHOSTARCH','GOHOSTOS','CGO_ENABLED','GOTOOLCHAIN','GOENV'}))
  need(actual and actual.GOROOT==sdk and actual.GOVERSION=='go'..entry.version and actual.GOHOSTARCH==expected_arch and actual.GOHOSTOS=='linux'and actual.CGO_ENABLED=='0'and actual.GOTOOLCHAIN=='local'and(actual.GOENV==''or actual.GOENV=='off'),'Go fixed environment differs: '..s.json.stringify(actual))
  -- GOENV=off is reported as an empty env-file path by current Go. Verify
  -- the behavior too instead of treating that empty path as an unset policy.
  local disabled=work..'/go-env-disabled'
  local rc=s.run({sdk..'/bin/go','env','-w','GOTOOLCHAIN=auto'},{cwd=project,env={MISE_RUNTIME_PROBE=t.id,ISTORE_RUNTIME_ACCELERATION='origin'},output=disabled,timeout=30})
  need(rc~=0 and(s.read(disabled)or''):find('GOENV=off',1,true),'Go global environment writes were not disabled')
  s.write(project..'/go.mod','module istore.local/runtime-probe\n\ngo '..entry.version..'\n')
  s.write(project..'/main.go','package main\nimport "os"\nfunc main(){os.Exit(37)}\n')
  probe('gofmt',{'-w','main.go'});probe('go',{'build','-p=1','-o','hello','.'},300)
  need(s.run({project..'/hello'},{cwd=project,output=log,append=true,timeout=15})==37,'Built Go program did not execute')
  receipt.probes={version='passed',arch='passed',abi='passed',launcher='passed',gofmt='passed',environment='passed',compile='passed',execute='passed',toolchain='fixed-local'}
 else
  need(probe('zig',{'version'})==entry.version,'Zig version differs')
  local info=probe('zig',{'env'},90)
  -- Supported Zig versions return ZON, not JSON. Compare exact escaped path
  -- strings without evaluating arbitrary ZON expressions.
  need(info:find('"'..sdk..'/lib"',1,true)and info:find('"'..entry.version..'"',1,true),'Zig complete library/version differs')
  s.write(project..'/main.zig','pub fn main() u8 { return 37; }\n')
  probe('zig',{'build-exe','main.zig','-O','ReleaseSmall','-femit-bin=hello'},300)
  need(s.run({project..'/hello'},{cwd=project,output=log,append=true,timeout=15})==37,'Built Zig program did not execute')
  receipt.probes={version='passed',arch='passed',abi='passed',launcher='passed',environment='passed',complete_library='passed',compile='passed',execute='passed'}
 end
 receipt.verified=true;s.write(sdk..'/receipt.json',receipt,420)
 tasks.phase(ctx,t,'registration');require('registration').register(ctx,receipt,work,log)
 t.publication={instance=id,wrap=require('adapters').launcher(ctx,id)};tasks.save(ctx,t);require('store').bump(ctx)
 return receipt
end
return M
