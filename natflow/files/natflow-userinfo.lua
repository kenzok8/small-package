local M = {}

M.EVENT_VERSION = 3
M.EVENT_SIZE = 102
M.AF_INET = 2
M.AF_INET6 = 10

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
		if not byte then
			return nil
		end

		local carry = byte
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

local function normalize_mac(mac)
	mac = tostring(mac or ""):upper()
	if not mac:match("^%x%x:%x%x:%x%x:%x%x:%x%x:%x%x$") then
		return nil
	end
	return mac
end

local function format_mac(data, pos)
	local a, b, c, d, e, f = data:byte(pos, pos + 5)
	if not f then
		return nil
	end
	return string.format("%02X:%02X:%02X:%02X:%02X:%02X", a, b, c, d, e, f)
end

local function event_family(ip, family)
	if family == M.AF_INET or family == "ipv4" then
		return "ipv4"
	end
	if family == M.AF_INET6 or family == "ipv6" then
		return "ipv6"
	end
	if tostring(ip or ""):find(":", 1, true) then
		return "ipv6"
	end
	return "ipv4"
end

function M.parse_binary(record)
	if type(record) ~= "string" or #record ~= M.EVENT_SIZE then
		return nil, "invalid record length"
	end

	local b1, b2 = record:byte(1, 2)
	local le
	if b1 == M.EVENT_VERSION and b2 == 0 then
		le = true
	elseif b1 == 0 and b2 == M.EVENT_VERSION then
		le = false
	else
		return nil, "unsupported event version"
	end

	local version = read_u16(record, 1, le)
	local header_len = read_u16(record, 3, le)
	local record_len = read_u16(record, 5, le)
	if version ~= M.EVENT_VERSION or header_len ~= M.EVENT_SIZE or record_len ~= M.EVENT_SIZE then
		return nil, "unsupported event layout"
	end

	local family = read_u16(record, 7, le)
	local ipaddr
	if family == M.AF_INET then
		ipaddr = format_ipv4(record, 13)
	elseif family == M.AF_INET6 then
		ipaddr = format_ipv6(record, 13)
	else
		return nil, "unsupported address family"
	end

	local macaddr = format_mac(record, 29)
	if not ipaddr or not macaddr then
		return nil, "invalid address fields"
	end

	return {
		version = version,
		family = event_family(ipaddr, family),
		ipaddr = ipaddr,
		macaddr = macaddr,
		idle_time = read_u32(record, 9, le) or 0,
		auth_type = record:byte(35) or 0,
		auth_status = record:byte(36) or 0,
		auth_rule_id = read_u16(record, 37, le) or 0,
		rx_packets = read_u64_decimal(record, 39, le) or "0",
		rx_bytes = read_u64_decimal(record, 47, le) or "0",
		tx_packets = read_u64_decimal(record, 55, le) or "0",
		tx_bytes = read_u64_decimal(record, 63, le) or "0",
		rx_speed_packets = read_u32(record, 71, le) or 0,
		rx_speed_bytes = read_u32(record, 75, le) or 0,
		tx_speed_packets = read_u32(record, 79, le) or 0,
		tx_speed_bytes = read_u32(record, 83, le) or 0,
		ifname = record:sub(87, 102):match("^[^%z]*") or "",
	}
end

function M.parse_text(line)
	if type(line) ~= "string" then
		return nil, "invalid text record"
	end

	local ipaddr, macaddr, auth_type, auth_status, auth_rule_id, idle_time,
		rx_packets, rx_bytes, tx_packets, tx_bytes,
		rx_speed_packets, rx_speed_bytes, tx_speed_packets, tx_speed_bytes, ifname =
		line:match("^([^,]+),([^,]+),([^,]+),([^,]+),(%d+),(%d+),(%d+):(%d+),(%d+):(%d+),(%d+):(%d+),(%d+):(%d+),?(.*)$")

	macaddr = normalize_mac(macaddr)
	auth_type = tonumber(auth_type)
	auth_status = tonumber(auth_status)
	if not ipaddr or not macaddr or not auth_type or not auth_status then
		return nil, "invalid text fields"
	end

	return {
		version = M.EVENT_VERSION,
		family = event_family(ipaddr),
		ipaddr = ipaddr,
		macaddr = macaddr,
		auth_type = auth_type,
		auth_status = auth_status,
		auth_rule_id = tonumber(auth_rule_id) or 0,
		idle_time = tonumber(idle_time) or 0,
		rx_packets = rx_packets or "0",
		rx_bytes = rx_bytes or "0",
		tx_packets = tx_packets or "0",
		tx_bytes = tx_bytes or "0",
		rx_speed_packets = tonumber(rx_speed_packets) or 0,
		rx_speed_bytes = tonumber(rx_speed_bytes) or 0,
		tx_speed_packets = tonumber(tx_speed_packets) or 0,
		tx_speed_bytes = tonumber(tx_speed_bytes) or 0,
		ifname = ifname or "",
	}
end

function M.environment(event, action)
	local env = {
		ACTION = tostring(action or "update"),
		USERINFO_VERSION = tostring(M.EVENT_VERSION),
	}
	if not event then
		return env
	end

	env.FAMILY = tostring(event.family or "")
	env.IPADDR = tostring(event.ipaddr or "")
	env.MACADDR = tostring(event.macaddr or "")
	env.IFNAME = tostring(event.ifname or "")
	env.DEVICE = env.IFNAME
	env.AUTH_TYPE = tostring(event.auth_type or 0)
	env.AUTH_STATUS = tostring(event.auth_status or 0)
	env.AUTH_RULE_ID = tostring(event.auth_rule_id or 0)
	env.IDLE_TIME = tostring(event.idle_time or 0)
	env.RX_PACKETS = tostring(event.rx_packets or 0)
	env.RX_BYTES = tostring(event.rx_bytes or 0)
	env.TX_PACKETS = tostring(event.tx_packets or 0)
	env.TX_BYTES = tostring(event.tx_bytes or 0)
	env.RX_SPEED_PACKETS = tostring(event.rx_speed_packets or 0)
	env.RX_SPEED_BYTES = tostring(event.rx_speed_bytes or 0)
	env.TX_SPEED_PACKETS = tostring(event.tx_speed_packets or 0)
	env.TX_SPEED_BYTES = tostring(event.tx_speed_bytes or 0)
	return env
end

return M
