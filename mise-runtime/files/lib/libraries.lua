local sys=require('system')
local store=require('store')
local artifacts=require('artifacts')
local contract=require('contract')
local M={}
local license_hashes={
  ['LGPL-2.1.txt']='20e50fe7aae3e56378ebf0417d9de904f55a0e61e4df315333e632a4d3555d95',
  ['GPL-3.0.txt']='3972dc9744f6499f0f9b2dbf76696f2ae7ad8af9b23dde66d6af86c9dfb36986',
  ['GCC-exception-3.1.txt']='9d6b43ce4d8de0c878bf16b54d8e7a10d9bd42b75178153e3af6a815bdc90f74'
}
local inputs={
  x86_64={url='https://archive.ubuntu.com/ubuntu/pool/main/g/glibc/libc6_2.39-0ubuntu8_amd64.deb',sha256='af36c7ac770770fe3d3c10e85d6bc538e76e57570ba7db7d397fb9f654783ef3'},
  aarch64={url='https://ports.ubuntu.com/ubuntu-ports/pool/main/g/glibc/libc6_2.39-0ubuntu8_arm64.deb',sha256='04d7cb73e608b41713b63ef915577f7f5d75e95b1b33174e82e05687fdb6cfaf'}
}
local gcc={url='https://github.com/istoreos/istoreos-app-hub/releases/download/baidudrive-runtime-v1.0.6/baidudrive-binary-1.0.6.tar.gz',sha256='2cc12327dbe08f0b9906c6213e7f14c0cdc09cae5a5c64e353639e7bd3d34a01',format='tar.gz',strip=1}
function M.definition(arch,revision)
  sys.need(inputs[arch],'UNSUPPORTED','Unsupported GNU library architecture')
  sys.need(revision==nil or revision=='r1' or revision=='r2','UNSUPPORTED','Unsupported library recipe')
  local a=inputs[arch]
  return {id='glibc-2.39-ubuntu8-gcc12-legal1-'..(revision or'r1')..'-'..arch,arch=arch,version='2.39',revision=revision or'r1',
    libc={url=a.url,sha256=a.sha256,format='deb',strip=0},gcc=gcc,
    licenses=license_hashes,
    maintenance='Compatibility candidate pinned to original tested inputs; not a latest-security-version claim.'}
end
function M.elf(path,arch)
  local f=io.open(path,'rb');sys.need(f,'PROBE_FAILED','Missing ELF '..path);local b=f:read(20);f:close()
  sys.need(b and #b==20 and b:sub(1,4)=='\127ELF' and b:byte(5)==2 and b:byte(6)==1,'PROBE_FAILED','Expected little-endian ELF64')
  local machine=b:byte(19)+b:byte(20)*256
  sys.need(machine==(arch=='x86_64' and 62 or 183),'PROBE_FAILED','ELF architecture mismatch')
end
function M.check(ctx,id,work)
  contract.key(id);local dir=ctx.root..'/libraries/'..id
  local r=sys.decode(dir..'/receipt.json');sys.need(r and r.id==id and r.verified==true,'INTEGRITY','Library receipt missing or unverified')
  sys.need(sys.sha(dir..'/SHA256SUMS',work)==r.manifest_sha256,'INTEGRITY','Library manifest changed')
  sys.need(sys.run({'sha256sum','-c','SHA256SUMS'},{cwd=dir,output=work..'/library-check.log',timeout=30})==0,'INTEGRITY','Library files changed')
  M.elf(dir..'/ld.so',r.arch)
  local rc,out=sys.capture({dir..'/ld.so','--version'},work,15)
  sys.need(rc==0 and out:find('2.39',1,true),'PROBE_FAILED','Private GNU loader failed')
  return r
end
local function deb_data(archive,work)
  local f=assert(io.open(archive,'rb'));sys.need(f:read(8)=='!<arch>\n','INTEGRITY','Invalid Debian ar archive')
  for _=1,16 do
    local hdr=f:read(60);if not hdr then break end
    sys.need(#hdr==60 and hdr:sub(59,60)=='`\n','INTEGRITY','Invalid ar member')
    local name=hdr:sub(1,16):match('^([^ /]+)');local size=tonumber(hdr:sub(49,58))
    sys.need(size and size>=0 and size<64*1024*1024,'INTEGRITY','Invalid ar member size')
    local data=f:read(size);sys.need(data and #data==size,'INTEGRITY','Truncated Debian archive')
    if name=='data.tar.zst' then
      f:close();local path=work..'/libc-data.tar.zst';sys.write(path,data);return path
    end
    if size%2==1 then f:read(1)end
  end
  f:close();sys.fail('INTEGRITY','Debian data.tar.zst missing')
end
local function member(archive,name,target,log)
  sys.need(not sys.fs.lstat(target),'INTEGRITY','Library destination already exists')
  sys.need(sys.run({'tar','-xOf',archive,name},{output=target,timeout=60})==0,'INTEGRITY','Cannot extract library member '..name)
  sys.need(sys.fs.stat(target) and sys.fs.stat(target).size>0,'INTEGRITY','Empty library member')
end
function M.ensure(ctx,definition,source,work,log,options)
  local id=contract.key(definition.id);local final=ctx.root..'/libraries/'..id
  options=options or{}
  if sys.fs.lstat(final)and not options.repair then return M.check(ctx,id,work)end
  store.validate(ctx.root,128*1024*1024,100)
  local libc=artifacts.download(ctx,definition.libc,source,work,log,options)
  local base=artifacts.download(ctx,definition.gcc,source,work,log,options)
  local data=deb_data(libc,work)
  local candidate=work..'/library-'..id;sys.need(not sys.fs.lstat(candidate),'INTEGRITY','Library candidate already exists');sys.mkdir(candidate,448)
  local rc,list=sys.capture({'tar','-tf',data},work,60);sys.need(rc==0,'INTEGRITY','Cannot inspect libc archive')
  local names={};for line in list:gmatch('[^\n]+')do names[line]=true end
  local tuple=definition.arch=='x86_64' and 'x86_64-linux-gnu' or 'aarch64-linux-gnu'
  local loader=definition.arch=='x86_64' and 'ld-linux-x86-64.so.2' or 'ld-linux-aarch64.so.1'
  local libraries={loader,'libc.so.6','libdl.so.2','libpthread.so.0','libm.so.6','librt.so.1','libutil.so.1','libresolv.so.2'}
  local manifest={}
  for _,name in ipairs(libraries)do
    local path
    for _,prefix in ipairs({'./usr/lib/','./lib/','usr/lib/','lib/'})do if names[prefix..tuple..'/'..name]then path=prefix..tuple..'/'..name;break end end
    sys.need(path,'INTEGRITY','Missing pinned libc member '..name)
    local destination=name==loader and 'ld.so' or name
    member(data,path,candidate..'/'..destination,log)
    manifest[#manifest+1]=sys.sha(candidate..'/'..destination,work)..'  '..destination
  end
  local prefix='baidudrive-binary-1.0.6/glibc/'..definition.arch
  for _,p in ipairs({{'lib/'..tuple..'/libgcc_s.so.1','libgcc_s.so.1'},{'usr/lib/'..tuple..'/libstdc++.so.6.0.30','libstdc++.so.6'}})do
    member(base,prefix..'/'..p[1],candidate..'/'..p[2],log)
    manifest[#manifest+1]=sys.sha(candidate..'/'..p[2],work)..'  '..p[2]
  end
  -- Source copyright is shipped with the exact libc input.
  for _,path in ipairs({'./usr/share/doc/libc6/copyright','usr/share/doc/libc6/copyright'})do
    if names[path]then member(data,path,candidate..'/LIBC-COPYRIGHT',log);manifest[#manifest+1]=sys.sha(candidate..'/LIBC-COPYRIGHT',work)..'  LIBC-COPYRIGHT';break end
  end
  sys.write(candidate..'/SOURCE.json',definition,420)
  manifest[#manifest+1]=sys.sha(candidate..'/SOURCE.json',work)..'  SOURCE.json'
  for _,name in ipairs({'LGPL-2.1.txt','GPL-3.0.txt','GCC-exception-3.1.txt'})do
    local license=ctx.share and sys.read(ctx.share..'/licenses/'..name)
    sys.need(license,'INTEGRITY','Runtime license material missing: '..name)
    sys.need(sys.sha(ctx.share..'/licenses/'..name,work)==license_hashes[name],'INTEGRITY','License material changed: '..name)
    sys.write(candidate..'/'..name,license,420);manifest[#manifest+1]=sys.sha(candidate..'/'..name,work)..'  '..name
  end
  table.sort(manifest);sys.write(candidate..'/SHA256SUMS',table.concat(manifest,'\n')..'\n',420)
  sys.need(sys.fs.chmod(candidate..'/ld.so','755'),'OFFLINE','Cannot set loader executable')
  M.elf(candidate..'/ld.so',definition.arch)
  local rc,out=sys.capture({candidate..'/ld.so','--version'},work,15)
  sys.need(rc==0 and out:find('2.39',1,true),'PROBE_FAILED','Candidate loader cannot run')
  local receipt={schema_version=1,id=id,arch=definition.arch,version=definition.version,revision=definition.revision,manifest_sha256=sys.sha(candidate..'/SHA256SUMS',work),source=definition.libc.url,verified=true}
  sys.write(candidate..'/receipt.json',receipt,420)
  sys.need(sys.run({'chmod','-R','a+rX,go-w',candidate},{output=log,append=true})==0,'OFFLINE','Cannot set shared library permissions')
  store.validate(ctx.root)
  if options.repair then
    local t=options.task;sys.need(t,'INVALID_INPUT','Library repair requires an owned task')
    local st=sys.fs.lstat(final)
    sys.need(not st or st.type=='dir','INTEGRITY','Library path is not a real directory')
    t.library_publication={id=id,old_inode=st and st.ino,new_inode=sys.fs.lstat(candidate).ino}
    require('tasks').save(ctx,t)
    if st then sys.need(sys.fs.rename(final,work..'/library-backup'),'OFFLINE','Cannot preserve the previous library')end
  end
  sys.need(sys.fs.rename(candidate,final),'OFFLINE','Cannot commit private library')
  return M.check(ctx,id,work)
end
function M.recover(ctx,t)
  local p=t.library_publication;if not p or t.phase=='committed'then return end
  local final=ctx.root..'/libraries/'..contract.key(p.id)
  local backup=ctx.root..'/work/'..contract.key(t.id)..'/library-backup'
  local old=sys.fs.lstat(backup);local current=sys.fs.lstat(final)
  if current and current.ino==p.old_inode and not old then return end
  sys.need(not current or current.ino==p.new_inode,'INTEGRITY','Library repair ownership changed; preserving files')
  if p.old_inode then
    sys.need(old and old.ino==p.old_inode,'INTEGRITY','Previous library backup changed')
    if current then sys.remove(final)end
    sys.need(sys.fs.rename(backup,final),'OFFLINE','Cannot restore the previous library')
  elseif current then sys.remove(final)end
end
return M
