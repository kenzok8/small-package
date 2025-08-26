module("luci.passwall2.util_shadowsocks", package.seeall)
local api = require "luci.passwall2.api"
local uci = api.uci
local jsonc = api.jsonc

function gen_config_server(node)
	local config = {}
	config.server_port = tonumber(node.port)
	config.password = node.password
	config.timeout = tonumber(node.timeout)
	config.fast_open = (node.tcp_fast_open and node.tcp_fast_open == "1") and true or false
	config.method = node.method

	if node.type == "SS-Rust" then
		config.server = "::"
		config.mode = "tcp_and_udp"
	else
		config.server = {"[::0]", "0.0.0.0"}
	end

	if node.type == "SSR" then
		config.protocol = node.protocol
		config.protocol_param = node.protocol_param
		config.obfs = node.obfs
		config.obfs_param = node.obfs_param
	end

	return config
end

local plugin_sh, plugin_bin

function gen_config(var)
	local node_id = var["-node"]
	if not node_id then
		print("-node 不能为空")
		return
	end
	local node = uci:get_all("passwall2", node_id)
	local server_host = var["-server_host"] or node.address
	local server_port = var["-server_port"] or node.port
	local local_addr = var["-local_addr"]
	local local_port = var["-local_port"]
	local mode = var["-mode"]
	local local_socks_address = var["-local_socks_address"] or "0.0.0.0"
	local local_socks_port = var["-local_socks_port"]
	local local_socks_username = var["-local_socks_username"]
	local local_socks_password = var["-local_socks_password"]
	local local_http_address = var["-local_http_address"] or "0.0.0.0"
	local local_http_port = var["-local_http_port"]
	local local_http_username = var["-local_http_username"]
	local local_http_password = var["-local_http_password"]

	if api.is_ipv6(server_host) then
		server_host = api.get_ipv6_only(server_host)
	end
	local server = server_host

	local plugin_file
	if node.plugin and node.plugin ~= "" and node.plugin ~= "none" then
		plugin_sh = var["-plugin_sh"] or ""
		plugin_file = (plugin_sh ~="") and plugin_sh or node.plugin
		plugin_bin = node.plugin
	end

	local config = {
		server = server,
		server_port = tonumber(server_port),
		local_address = local_addr,
		local_port = tonumber(local_port),
		password = node.password,
		method = node.method,
		timeout = tonumber(node.timeout),
		fast_open = (node.tcp_fast_open and node.tcp_fast_open == "true") and true or false,
		reuse_port = true
	}
	
	if node.type == "SS" then
		config.plugin = plugin_file or nil
		config.plugin_opts = (plugin_file) and node.plugin_opts or nil
		config.mode = mode
	elseif node.type == "SSR" then
		config.protocol = node.protocol
		config.protocol_param = node.protocol_param
		config.obfs = node.obfs
		config.obfs_param = node.obfs_param
	elseif node.type == "SS-Rust" then
		config = {
			servers = {
				{
					address = server,
					port = tonumber(server_port),
					method = node.method,
					password = node.password,
					timeout = tonumber(node.timeout),
					plugin = plugin_file or nil,
					plugin_opts = (plugin_file) and node.plugin_opts or nil
				}
			},
			locals = {},
			fast_open = (node.tcp_fast_open and node.tcp_fast_open == "true") and true or false
		}
		if local_socks_address and local_socks_port then
			table.insert(config.locals, {
				local_address = local_socks_address,
				local_port = tonumber(local_socks_port),
				mode = "tcp_and_udp"
			})
		end
		if local_http_address and local_http_port then
			table.insert(config.locals, {
				protocol = "http",
				local_address = local_http_address,
				local_port = tonumber(local_http_port)
			})
		end
	end
	
	return jsonc.stringify(config, 1)
end

_G.gen_config = gen_config

if arg[1] then
	local func =_G[arg[1]]
	if func then
		print(func(api.get_function_args(arg)))
		if plugin_sh and plugin_sh ~="" and plugin_bin then
			local f = io.open(plugin_sh, "w")
			f:write("#!/bin/sh\n")
			f:write("export PATH=/usr/sbin:/usr/bin:/sbin:/bin:/root/bin:$PATH\n")
			f:write(plugin_bin .. " $@ &\n")
			f:write("echo $! > " .. plugin_sh:gsub("%.sh$", ".pid") .. "\n")
			f:write("wait\n")
			f:close()
			luci.sys.call("chmod +x " .. plugin_sh)
		end
	end
end
