#!/usr/bin/lua
local share=arg[0]:match('^(.*)/execute.lua$')or'/usr/share/mise-runtime'
package.path=share..'/lib/?.lua;'..package.path
local sys=require('system')
local root,id,command=arg[1],arg[2],arg[3]or'--shell'
local argv={};for i=4,#arg do argv[#argv+1]=arg[i]end
local ok,err=pcall(function()require('execution').exec(root,id,command,argv)end)
io.stderr:write(type(err)=='table'and(err.code..': '..err.message)or tostring(err));io.stderr:write('\n');os.exit(1)
