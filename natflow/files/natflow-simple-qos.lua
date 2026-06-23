#!/usr/bin/lua

local DEV_USERINFO = "/dev/userinfo_ctl"
local DEV_EVENT = "/dev/userinfo_event_ctl"
local EVENT_FIFO = "/tmp/userinfo_event_fifo"

local uci = require "uci"
local nixio = require "nixio"
local nfs = require "nixio.fs"

-- Keep shell execution only for system state that has no stable Lua API here.
local function shell_quote(value)
	value = tostring(value or "")
	return "'" .. value:gsub("'", "'\\''") .. "'"
end

local function run(command)
	local ok, _, code = os.execute(command .. " >/dev/null 2>&1")
	if ok == true then
		return true
	end
	if ok == 0 then
		return true
	end
	return code == 0
end

local function command_output(command)
	local fp = io.popen(command .. " 2>/dev/null")
	if not fp then
		return ""
	end
	local data = fp:read("*a") or ""
	fp:close()
	return data
end

local function first_field(line)
	return tostring(line or ""):match("^([^,]*)") or ""
end

local function is_ipv6(value)
	return tostring(value or ""):find(":", 1, true) ~= nil
end

local function split_list(value)
	local out = {}
	for item in tostring(value or ""):gsub(",", " "):gmatch("%S+") do
		out[#out + 1] = item
	end
	return out
end

-- IPv4 parsing is only needed for IPv4-embedded IPv6 literals.
local function parse_ipv4_bytes(addr)
	local bytes = {}
	for part in tostring(addr or ""):gmatch("[^.]+") do
		if #bytes == 4 or not part:match("^%d+$") then
			return nil
		end
		local byte = tonumber(part, 10)
		if not byte or byte > 255 then
			return nil
		end
		bytes[#bytes + 1] = byte
	end
	if #bytes ~= 4 then
		return nil
	end
	return bytes
end

-- Parse one side of an IPv6 literal split by "::" into 16-bit groups.
local function append_ipv6_part(groups, part)
	if part == "" then
		return true
	end

	for group in part:gmatch("[^:]+") do
		if group:find(".", 1, true) then
			local bytes = parse_ipv4_bytes(group)
			if not bytes then
				return false
			end
			groups[#groups + 1] = bytes[1] * 256 + bytes[2]
			groups[#groups + 1] = bytes[3] * 256 + bytes[4]
		else
			if not group:match("^[0-9A-Fa-f]+$") or #group > 4 then
				return false
			end
			groups[#groups + 1] = tonumber(group, 16)
		end
	end

	return true
end

-- Convert IPv6 text to 16 bytes, supporting compressed and IPv4-embedded forms.
local function parse_ipv6_bytes(addr)
	addr = tostring(addr or "")
	local first, last = addr:find("::", 1, true)
	if first and addr:find("::", last + 1, true) then
		return nil
	end

	local groups = {}
	if first then
		local left, right = addr:sub(1, first - 1), addr:sub(last + 1)
		if (left ~= "" and left:sub(-1) == ":") or (right ~= "" and right:sub(1, 1) == ":") then
			return nil
		end
		local left_groups, right_groups = {}, {}
		if not append_ipv6_part(left_groups, left) or not append_ipv6_part(right_groups, right) then
			return nil
		end
		local fill = 8 - #left_groups - #right_groups
		if fill < 1 then
			return nil
		end
		for _, group in ipairs(left_groups) do
			groups[#groups + 1] = group
		end
		for _ = 1, fill do
			groups[#groups + 1] = 0
		end
		for _, group in ipairs(right_groups) do
			groups[#groups + 1] = group
		end
	else
		if not append_ipv6_part(groups, addr) or #groups ~= 8 then
			return nil
		end
	end

	local bytes = {}
	for _, group in ipairs(groups) do
		if group < 0 or group > 0xffff then
			return nil
		end
		bytes[#bytes + 1] = math.floor(group / 256)
		bytes[#bytes + 1] = group % 256
	end
	return bytes
end

-- Precompile one IPv6 literal or CIDR into bytes plus prefix length.
local function parse_ipv6_cidr(net)
	local addr, prefix = tostring(net or ""):match("^([^/]+)/(%d+)$")
	if not addr then
		addr = tostring(net or "")
		prefix = 128
	else
		prefix = tonumber(prefix, 10)
	end
	if not prefix or prefix < 0 or prefix > 128 then
		return nil
	end

	local bytes = parse_ipv6_bytes(addr)
	if not bytes then
		return nil
	end
	return {
		bytes = bytes,
		prefix = prefix,
	}
end

-- Compare the first N bits locally, without external match helpers.
local function ipv6_prefix_match(addr, net)
	local full_bytes = math.floor(net.prefix / 8)
	local rest_bits = net.prefix % 8

	for i = 1, full_bytes do
		if addr[i] ~= net.bytes[i] then
			return false
		end
	end

	if rest_bits == 0 then
		return true
	end

	local idx = full_bytes + 1
	local divisor = 2 ^ (8 - rest_bits)
	return math.floor(addr[idx] / divisor) == math.floor(net.bytes[idx] / divisor)
end

-- Split mixed user lists so IPv4 can use ipops while IPv6 stays native Lua.
local function compile_user(user)
	local v4_items = {}
	local v6_nets = {}

	for _, item in ipairs(split_list(user)) do
		if is_ipv6(item) then
			local net = parse_ipv6_cidr(item)
			if net then
				v6_nets[#v6_nets + 1] = net
			end
		else
			v4_items[#v4_items + 1] = item
		end
	end

	return table.concat(v4_items, ","), v6_nets
end

local function file_exists(path)
	local fp = io.open(path, "r")
	if not fp then
		return false
	end
	fp:close()
	return true
end

local function fs_type(path)
	local stat = nfs.stat(path)
	return type(stat) == "table" and stat.type or nfs.stat(path, "type")
end

local function fs_remove(path)
	if nfs.remove then
		return nfs.remove(path)
	end
	if nfs.unlink then
		return nfs.unlink(path)
	end
	if nixio.unlink then
		return nixio.unlink(path)
	end
	return false
end

local function fs_mkfifo(path)
	if nfs.mkfifo then
		return nfs.mkfifo(path, 384)
	end
	if nixio.mkfifo then
		return nixio.mkfifo(path, 384)
	end
	return false
end

-- lua-ipops is shipped as a Lua script on some targets and as a require-able
-- module on others. Accept both module tables and legacy global functions.
local function load_ipops()
	package.path = "/usr/share/natflow/?.lua;" .. package.path

	local ok, mod = pcall(require, "ipops")
	if ok then
		return type(mod) == "table" and mod or _G
	end

	for _, path in ipairs({ "/usr/share/natflow/ipops.lua", "/usr/lib/lua/ipops.lua" }) do
		if file_exists(path) then
			local old_arg = arg
			arg = {}
			ok, mod = pcall(dofile, path)
			arg = old_arg
			if ok then
				return type(mod) == "table" and mod or _G
			end
		end
	end

	return _G
end

local IPOPS = load_ipops()
local ipops_netstrings_test = type(IPOPS) == "table" and IPOPS.netStrings_test_netStrings or nil
ipops_netstrings_test = ipops_netstrings_test or _G.netStrings_test_netStrings

local function ipops_test_netstrings(user, ip)
	if user == "" then
		return true
	end
	if not ipops_netstrings_test then
		return false
	end

	local ok, result = pcall(ipops_netstrings_test, user, ip)
	if not ok then
		return false
	end
	return result == true or result == 0
end

local function rate_to_bytes(rate)
	local value = tostring(rate or ""):match("^%s*(.-)%s*$")
	local number, unit = value:match("^([0-9]*%.?[0-9]+)%s*([A-Za-z]*)$")
	number = tonumber(number)
	if not number then
		return 0
	end

	unit = unit:lower()
	local mul, div = 1, 1
	if unit == "gbps" then
		mul = 128 * 1024 * 1024
	elseif unit == "mbps" then
		mul = 128 * 1024
	elseif unit == "kbps" then
		mul = 128
	elseif unit == "bps" then
		div = 8
	elseif unit ~= "" then
		return 0
	end

	return math.floor(number * mul / div)
end

-- Read all qos_simple sections once; the worker reloads through procd triggers.
local function uci_qos_simple_rules()
	local rules = {}
	local cursor = uci.cursor()

	cursor:foreach("natflow", "qos_simple", function(section)
		rules[#rules + 1] = {
			name = section[".name"],
			disabled = section.disabled or "0",
			user = section.user or "",
			rx_rate = section.rx_rate or "0",
			tx_rate = section.tx_rate or "0",
		}
	end)

	for idx, rule in ipairs(rules) do
		rule.index = idx - 1
		rule.rx_bytes = rate_to_bytes(rule.rx_rate)
		rule.tx_bytes = rate_to_bytes(rule.tx_rate)
		rule.v4_user, rule.v6_nets = compile_user(rule.user)
	end

	return rules
end

-- Match the first enabled rule that covers this user IP.
local function user_matches(rule, ip)
	if rule.user == "" then
		return true
	end
	if is_ipv6(ip) then
		local addr = parse_ipv6_bytes(ip)
		if not addr then
			return false
		end
		for _, net in ipairs(rule.v6_nets) do
			if ipv6_prefix_match(addr, net) then
				return true
			end
		end
		return false
	end
	if rule.v4_user == "" then
		return false
	end
	return ipops_test_netstrings(rule.v4_user, ip)
end

-- The natflow user device accepts one control command per write.
local function write_userinfo(command)
	local fp = io.open(DEV_USERINFO, "w")
	if not fp then
		return false
	end
	fp:write(command, "\n")
	fp:close()
	return true
end

-- Existing behavior applies the first matching qos_simple section.
local function apply_ip(rules, ip, verbose)
	for _, rule in ipairs(rules) do
		if rule.disabled ~= "1" and user_matches(rule, ip) then
			local command = string.format("set-token-ctrl %s %d %d", ip, rule.rx_bytes, rule.tx_bytes)
			if verbose then
				print(command)
			end
			write_userinfo(command)
			return true
		end
	end
	return false
end

-- Preserve the old IPv6 neighbor refresh used after userinfo events.
local function refresh_ipv6_neighbor(line, ip)
	if not is_ipv6(ip) then
		return
	end

	local mac = tostring(line or ""):match("^[^,]*,([^,]*)")
	if not mac or mac == "" then
		return
	end

	local neigh = command_output("ip -6 neigh show " .. shell_quote(ip))
	for iface in neigh:gmatch(" dev%s+(%S+)") do
		local zone = command_output("fw3 -q device " .. shell_quote(iface)):match("^%s*(%S+)")
		if zone == "lan" then
			run("ip -6 neigh replace " .. shell_quote(ip) ..
				" lladdr " .. shell_quote(mac) ..
				" dev " .. shell_quote(iface) ..
				" nud reachable")
		end
	end
end

-- The FIFO is shared with the existing userinfo event consumers.
local function ensure_fifo()
	if fs_type(EVENT_FIFO) == "fifo" then
		return
	end
	fs_remove(EVENT_FIFO)
	fs_mkfifo(EVENT_FIFO)
end

-- Non-blocking FIFO write avoids spawning a helper process per event.
local function dispatch_event(line)
	local fd = nixio.open(EVENT_FIFO, "wronly,nonblock")
	if not fd then
		return
	end

	fd:writeall(tostring(line or "") .. "\n")
	fd:close()
end

-- Reading /dev/userinfo_ctl lists current users; writing to it sends commands.
local function foreach_userinfo(callback)
	local fp = io.open(DEV_USERINFO, "r")
	if not fp then
		return
	end
	for line in fp:lines() do
		callback(line, first_field(line))
	end
	fp:close()
end

-- Foreground worker for procd: seed current users, then follow kernel events.
local function run_worker()
	local rules = uci_qos_simple_rules()

	foreach_userinfo(function(line, ip)
		apply_ip(rules, ip, true)
		refresh_ipv6_neighbor(line, ip)
	end)

	ensure_fifo()
	dispatch_event("")

	local fp = io.open(DEV_EVENT, "r")
	if not fp then
		return 1
	end

	for line in fp:lines() do
		local ip = first_field(line)
		dispatch_event(line)
		apply_ip(rules, ip, false)
		refresh_ipv6_neighbor(line, ip)
	end
	fp:close()
	return 0
end

-- stop_service calls this after procd has stopped the worker.
local function cleanup()
	foreach_userinfo(function(_, ip)
		write_userinfo(string.format("set-token-ctrl %s 0 0", ip))
	end)
end

local action = arg[1] or "run"
if action == "run" then
	os.exit(run_worker())
elseif action == "cleanup" then
	cleanup()
else
	io.stderr:write("usage: natflow-simple-qos {run|cleanup}\n")
	os.exit(1)
end
