-- Copyright 2014-2021 Sandor Balazsi <sandor.balazsi@gmail.com>
-- Licensed to the public under the GNU General Public License.

local assert, ipairs, tostring, string, table, unpack = assert, ipairs, tostring, string, table, unpack

local fs = require "nixio.fs"
local socket = require "socket"
local xmlrpc = require "xmlrpc"
local scgi = require "xmlrpc.scgi"

local rtorrent_config_file = "/root/.rtorrent.rc"

module "rtorrent"

local function format(results, commands)
	local formatted_results = {}
	for _, result in ipairs(results) do
		local formatted = {}
		for i, value in ipairs(result) do
			formatted[commands[i]:gsub("[%.=,]", "_")] = value
		end
		table.insert(formatted_results, formatted)
	end
	return formatted_results
end

function call(method, ...)
	local address, port = ("\n" .. tostring(fs.readfile(rtorrent_config_file)))
		:match("\n%s*scgi_port%s*=%s*([^:]+):(%d+)")
	assert(address, "\n\nError: scgi port not defined in your " .. rtorrent_config_file .. " config file!\n"
		.. 'Please add to it, e.g.: "scgi_port = 127.0.0.1:6000".\n')
	local ok, res = scgi.call(address, port, method, ...)
	if not ok and res == "socket connect failed" then
		assert(ok, "\n\nFailed to connect to rtorrent: rpc port not reachable"
			.. " on " .. address .. ":" .. port .. "!\nPossible reasons:\n"
			.. "- rtorrent is not running (ps w | grep [r]torrent)\n"
			.. "- not the rpc version of rtorrent is installed\n")
	end
	assert(ok, string.format("\n\nXML-RPC call failed: %s!\n", tostring(res)))
	return res
end

function multicall(method_type, hash, filter, ...)
	local commands = {}
	for i, command in ipairs({...}) do
		if not command:match("=") then command = command .. "=" end
		commands[i] = method_type .. command
	end
	local method = (method_type == "d.") and "multicall2" or "multicall"
	return format(call(method_type .. method, hash, filter, unpack(commands)), {...})
end

function batchcall(method_type, hash, ...)
	local methods = {}
	for i, command in ipairs({...}) do
		local params = { hash }
		if command:match("=") then
			for arg in command:gsub(".*=", ""):gmatch("[^,]+") do
				table.insert(params, arg)
			end
		end
		table.insert(methods, {
			methodName = method_type .. command:gsub("=.*", ""),
			params = xmlrpc.newTypedValue(params, "array")
		})
	end
	local results = {}
	for i, result in ipairs(call("system.multicall", xmlrpc.newTypedValue(methods, "array"))) do
		results[({...})[i]:gsub("[%.=,]", "_")] = (#result == 1) and result[1] or result
	end
	return results
end
