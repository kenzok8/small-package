#!/usr/bin/lua

local DEV_USERINFO = "/dev/userinfo_ctl"
local DEV_EVENT = "/dev/natflow_userinfo_queue"
local EVENT_FIFO = "/tmp/userinfo_event_fifo"
local EVENT_CACHE_LIMIT = 256
local USERINFO_EVENT_SIZE = 86
local USERINFO_EVENT_READ_SIZE = USERINFO_EVENT_SIZE * 32
local AF_INET = 2
local AF_INET6 = 10

local uci = require "luci.model.uci"
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

local function sleep_msec(msec)
	if nixio.nanosleep then
		nixio.nanosleep(math.floor(msec / 1000), (msec % 1000) * 1000000)
	else
		os.execute("sleep " .. tostring(math.max(1, math.floor((msec + 999) / 1000))))
	end
end

local function read_u16(data, pos, le)
	local a, b = data:byte(pos, pos + 1)
	if not b then
		return nil
	end
	if le then
		return a + b * 256
	end
	return a * 256 + b
end

local function read_u32(data, pos, le)
	local a, b, c, d = data:byte(pos, pos + 3)
	if not d then
		return nil
	end
	if le then
		return a + b * 256 + c * 65536 + d * 16777216
	end
	return a * 16777216 + b * 65536 + c * 256 + d
end

local function read_u64_decimal(data, pos, le)
	local chunks = { 0 }
	local base = 1000000

	for i = 1, 8 do
		local idx = le and (pos + 8 - i) or (pos + i - 1)
		local byte = data:byte(idx)
		local carry = byte or 0

		for j = 1, #chunks do
			local value = chunks[j] * 256 + carry
			chunks[j] = value % base
			carry = math.floor(value / base)
		end
		while carry > 0 do
			chunks[#chunks + 1] = carry % base
			carry = math.floor(carry / base)
		end
	end

	local out = tostring(chunks[#chunks])
	for i = #chunks - 1, 1, -1 do
		out = out .. string.format("%06d", chunks[i])
	end
	return out
end

local function format_ipv4(data, pos)
	local a, b, c, d = data:byte(pos, pos + 3)
	if not d then
		return nil
	end
	return string.format("%u.%u.%u.%u", a, b, c, d)
end

local function format_ipv6(data, pos)
	local groups = {}
	for i = 0, 7 do
		local hi, lo = data:byte(pos + i * 2, pos + i * 2 + 1)
		if not lo then
			return nil
		end
		groups[#groups + 1] = string.format("%x", hi * 256 + lo)
	end
	return table.concat(groups, ":")
end

local function format_mac(data, pos)
	local a, b, c, d, e, f = data:byte(pos, pos + 5)
	if not f then
		return nil
	end
	return string.format("%02x:%02x:%02x:%02x:%02x:%02x", a, b, c, d, e, f)
end

local function parse_userinfo_event(record)
	local b1, b2 = record:byte(1, 2)
	local le
	if b1 == 2 and b2 == 0 then
		le = true
	elseif b1 == 0 and b2 == 2 then
		le = false
	else
		return nil
	end

	local version = read_u16(record, 1, le)
	local header_len = read_u16(record, 3, le)
	local record_len = read_u16(record, 5, le)
	if version ~= 2 or header_len ~= USERINFO_EVENT_SIZE or record_len ~= USERINFO_EVENT_SIZE then
		return nil
	end

	local family = read_u16(record, 7, le)
	local idle_time = read_u32(record, 9, le) or 0
	local ip
	if family == AF_INET then
		ip = format_ipv4(record, 13)
	elseif family == AF_INET6 then
		ip = format_ipv6(record, 13)
	end
	if not ip then
		return nil
	end

	local mac = format_mac(record, 29)
	if not mac then
		return nil
	end

	local auth_type = record:byte(35) or 0
	local auth_status = record:byte(36) or 0
	local auth_rule_id = read_u16(record, 37, le) or 0
	local rx_packets = read_u64_decimal(record, 39, le)
	local rx_bytes = read_u64_decimal(record, 47, le)
	local tx_packets = read_u64_decimal(record, 55, le)
	local tx_bytes = read_u64_decimal(record, 63, le)
	local rx_speed_packets = read_u32(record, 71, le) or 0
	local rx_speed_bytes = read_u32(record, 75, le) or 0
	local tx_speed_packets = read_u32(record, 79, le) or 0
	local tx_speed_bytes = read_u32(record, 83, le) or 0

	local line = string.format("%s,%s,0x%x,0x%x,%u,%u,%s:%s,%s:%s,%u:%u,%u:%u",
		ip, mac, auth_type, auth_status, auth_rule_id, idle_time,
		rx_packets, rx_bytes, tx_packets, tx_bytes,
		rx_speed_packets, rx_speed_bytes, tx_speed_packets, tx_speed_bytes)
	return line, ip
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
		return nfs.mkfifo(path, 666)
	end
	if nixio.mkfifo then
		return nixio.mkfifo(path, 666)
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
local ipops_netstring_set_to_ranges = type(IPOPS) == "table" and IPOPS.netStringSet2rangeSet or nil
local ipops_range_set_in_range_set = type(IPOPS) == "table" and IPOPS.rangeSet_in_rangeSet or nil

local function ipops_test_netstrings(user, ip)
	if user == "" then
		return true
	end
	if not ipops_netstring_set_to_ranges or not ipops_range_set_in_range_set then
		return false
	end

	local ok_user, user_ranges = pcall(ipops_netstring_set_to_ranges, split_list(user))
	if not ok_user then
		return false
	end

	local ok_ip, ip_ranges = pcall(ipops_netstring_set_to_ranges, { ip })
	if not ok_ip then
		return false
	end

	local ok, result = pcall(ipops_range_set_in_range_set, ip_ranges, user_ranges)
	if not ok then
		return false
	end
	return result == true
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
		if rule.disabled == "0" and user_matches(rule, ip) then
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

local function fd_write_all(fd, data)
	if type(fd.writeall) == "function" then
		local ok = fd:writeall(data)
		return ok ~= nil and ok ~= false
	end

	if type(fd.write) ~= "function" then
		return false
	end

	local offset = 1

	while offset <= #data do
		local len = fd:write(data:sub(offset))

		if len == nil or len == false then
			return false
		end

		if len == true then
			return true
		end

		if type(len) ~= "number" or len <= 0 then
			return false
		end

		offset = offset + len
	end

	return true
end

local function open_event_queue()
	local fd = nixio.open(DEV_EVENT, nixio.open_flags("rdwr"))
	if not fd then
		return nil
	end

	if not fd_write_all(fd, string.format("cache=%u\n", EVENT_CACHE_LIMIT)) then
		fd:close()
		return nil
	end
	return fd
end

local function wait_event_queue(fd)
	if type(nixio.poll) ~= "function" or type(nixio.poll_flags) ~= "function" then
		sleep_msec(1000)
		return true
	end

	local ok, ready = pcall(function()
		local fds = {
			{
				fd = fd,
				events = nixio.poll_flags("in"),
			}
		}
		return nixio.poll(fds, -1)
	end)
	if not ok or ready == nil then
		sleep_msec(1000)
		return true
	end
	if type(ready) == "number" then
		return ready >= 0
	end
	return ready ~= false
end

local function read_event_batch(fd, pending, callback)
	local data = fd:read(USERINFO_EVENT_READ_SIZE)
	if not data then
		return false, pending, false
	end
	if #data == 0 then
		return true, pending, false
	end

	data = pending .. data
	local offset = 1
	while #data - offset + 1 >= USERINFO_EVENT_SIZE do
		local record = data:sub(offset, offset + USERINFO_EVENT_SIZE - 1)
		local line, ip = parse_userinfo_event(record)
		if line and ip then
			callback(line, ip)
		end
		offset = offset + USERINFO_EVENT_SIZE
	end

	return true, data:sub(offset), true
end

-- Non-blocking FIFO write avoids spawning a helper process per event.
local function dispatch_event(line)
	local fd = nixio.open(EVENT_FIFO, nixio.open_flags("wronly", "nonblock"))
	if not fd then
		return
	end

	fd_write_all(fd, tostring(line or "") .. "\n")
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

	local fd = open_event_queue()
	if not fd then
		return 1
	end

	local pending = ""
	while wait_event_queue(fd) do
		for _ = 1, 32 do
			local ok, new_pending, had_events = read_event_batch(fd, pending, function(line, ip)
				dispatch_event(line)
				apply_ip(rules, ip, false)
				refresh_ipv6_neighbor(line, ip)
			end)
			pending = new_pending
			if not ok then
				fd:close()
				return 1
			end
			if not had_events then
				break
			end
		end
	end
	fd:close()
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
