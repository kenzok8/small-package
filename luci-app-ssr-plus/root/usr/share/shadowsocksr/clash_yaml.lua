#!/usr/bin/lua

require "nixio.fs"
require "luci.model.uci"

local ok_lyaml, lyaml = pcall(require, "lyaml")
if not ok_lyaml then
	io.stderr:write("lyaml_not_found\n")
	os.exit(2)
end

local uci = require "luci.model.uci".cursor()
local ok_jsonc, jsonc = pcall(require, "luci.jsonc")

local function read_file(path)
	local data = nixio.fs.readfile(path)
	if not data or data == "" then
		return nil
	end
	return data
end

local function write_file(path, data)
	return nixio.fs.writefile(path, data)
end

local function load_yaml(path)
	local raw = read_file(path)
	if not raw then
		return nil, "read_failed"
	end

	local ok, parsed = pcall(lyaml.load, raw)
	if not ok or type(parsed) ~= "table" then
		return nil, "parse_failed"
	end

	return parsed
end

local function dump_yaml(path, data)
	local ok, rendered = pcall(lyaml.dump, { data })
	if not ok or not rendered then
		return nil, "dump_failed"
	end

	write_file(path, rendered)
	return true
end

local function split_filter_words(text)
	local items = {}
	for part in tostring(text or ""):gmatch("[^/]+") do
		if part ~= "" then
			items[#items + 1] = part
		end
	end
	return items
end

local function trim(value)
	return tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function parse_csv_line(line)
	local cols = {}
	local cur = ""
	local in_quote = false
	local i = 1

	while i <= #line do
		local ch = line:sub(i, i)
		if ch == '"' then
			if in_quote and line:sub(i + 1, i + 1) == '"' then
				cur = cur .. '"'
				i = i + 1
			else
				in_quote = not in_quote
			end
		elseif ch == "," and not in_quote then
			cols[#cols + 1] = cur
			cur = ""
		else
			cur = cur .. ch
		end
		i = i + 1
	end

	cols[#cols + 1] = cur
	return cols
end

local function read_clash_client_rules_csv(sid)
	local rows = {}
	sid = trim(sid)
	if sid == "" then
		return rows
	end

	local csv_path = string.format("/etc/ssrplus/clash/%s.csv", sid)
	local raw = read_file(csv_path)
	if not raw or raw == "" then
		return rows
	end

	local first = true
	for line in tostring(raw):gsub("\r", ""):gmatch("[^\n]+") do
		local text = trim(line)
		if text ~= "" then
			if first and text:lower() == "enabled,client,policy,remarks,client_mac" then
				first = false
			else
				local cols = parse_csv_line(line)
				if #cols >= 4 then
					rows[#rows + 1] = {
						enabled = cols[1],
						ip_addr = trim(cols[2] or ""),
						policy_group = trim(cols[3] or ""),
						remarks = trim(cols[4] or ""),
						client_mac = trim(cols[5] or "")
					}
				end
			end
		end
	end

	return rows
end

local function has_proxy_sections(doc)
	return type(doc.proxies) == "table" or type(doc["proxy-providers"]) == "table"
end

local function validate(path)
	local doc = load_yaml(path)
	if not doc then
		return false
	end
	return has_proxy_sections(doc)
end

local function filter(path, filter_words)
	local doc, err = load_yaml(path)
	if not doc then
		io.stderr:write(err or "parse_failed", "\n")
		return false
	end

	local words = split_filter_words(filter_words)
	if #words == 0 then
		return true
	end

	local removed = {}
	local proxies = {}
	for _, proxy in ipairs(doc.proxies or {}) do
		local name = tostring(proxy.name or "")
		local matched = false
		for _, word in ipairs(words) do
			if name:find(word, 1, true) then
				matched = true
				removed[name] = true
				break
			end
		end
		if not matched then
			proxies[#proxies + 1] = proxy
		end
	end
	doc.proxies = proxies

	for _, group in ipairs(doc["proxy-groups"] or {}) do
		if type(group.proxies) == "table" then
			local kept = {}
			for _, name in ipairs(group.proxies) do
				if not removed[tostring(name)] then
					kept[#kept + 1] = name
				end
			end
			group.proxies = kept
		end
	end

	local count = 0
	for _ in pairs(removed) do
		count = count + 1
	end

	dump_yaml(path, doc)
	io.stdout:write(tostring(count), "\n")
	return true
end

local function deep_merge(dst, src)
	if type(dst) ~= "table" or type(src) ~= "table" then
		return src
	end

	for k, v in pairs(src) do
		if type(v) == "table" and type(dst[k]) == "table" then
			dst[k] = deep_merge(dst[k], v)
		else
			dst[k] = v
		end
	end

	return dst
end

local function strip_runtime_conflicts(doc)
	doc.tun = nil
	doc.listeners = nil
	doc["redir-port"] = nil
	doc["tproxy-port"] = nil
	doc["socks-port"] = nil
	doc["mixed-port"] = nil
	doc.port = nil
	doc["external-controller"] = nil
	doc.secret = nil
	doc["allow-lan"] = nil
	if type(doc.dns) == "table" then
		doc.dns["fake-ip-range"] = nil
		doc.dns["fake-ip-filter"] = nil
	end
end

local function group_requires_candidates(group)
	local gtype = tostring(group and group.type or ""):lower()
	return gtype == "select"
		or gtype == "fallback"
		or gtype == "load-balance"
		or gtype == "url-test"
		or gtype == "relay"
end

local function has_nonempty_sequence(value)
	return type(value) == "table" and next(value) ~= nil
end

local function fill_empty_proxy_groups(doc)
	local changed = 0
	for _, group in ipairs(doc["proxy-groups"] or {}) do
		if type(group) == "table"
			and group_requires_candidates(group)
			and not has_nonempty_sequence(group.proxies)
			and not has_nonempty_sequence(group.use)
		then
			group.proxies = { "DIRECT" }
			changed = changed + 1
		end
	end
	return changed
end

local function strip_incompatible_script_rules(doc)
	local kept = {}
	local removed = 0
	local has_script_rule = false

	for _, rule in ipairs(doc.rules or {}) do
		local text = tostring(rule or "")
		if text:match("^SCRIPT,") then
			removed = removed + 1
		else
			kept[#kept + 1] = rule
			if text:match("^SCRIPT,") then
				has_script_rule = true
			end
		end
	end

	if removed > 0 then
		doc.rules = kept
	end

	if not has_script_rule then
		doc.script = nil
	end

	return removed
end

local function prepare(input_path, output_path)
	local doc, err = load_yaml(input_path)
	if not doc then
		io.stderr:write(err or "parse_failed", "\n")
		return false
	end
	if not has_proxy_sections(doc) then
		io.stderr:write("missing_proxy_sections\n")
		return false
	end

	strip_runtime_conflicts(doc)
	local filled_groups = fill_empty_proxy_groups(doc)
	local stripped_rules = strip_incompatible_script_rules(doc)
	local ok, rendered = pcall(lyaml.dump, { doc })
	if not ok or not rendered then
		io.stderr:write("dump_failed\n")
		return false
	end

	write_file(output_path, rendered)
	io.stdout:write(string.format("filled_groups=%d stripped_script_rules=%d\n", filled_groups, stripped_rules))
	return true
end

local function merge(raw_path, overlay_path, output_path)
	local raw_doc, raw_err = load_yaml(raw_path)
	if not raw_doc then
		io.stderr:write(raw_err or "parse_failed", "\n")
		return false
	end

	local overlay_doc, overlay_err = load_yaml(overlay_path)
	if not overlay_doc then
		io.stderr:write(overlay_err or "parse_failed", "\n")
		return false
	end

	strip_runtime_conflicts(raw_doc)
	local filled_groups = fill_empty_proxy_groups(raw_doc)
	local stripped_rules = strip_incompatible_script_rules(raw_doc)
	local merged = deep_merge(raw_doc, overlay_doc)
	local ok, rendered = pcall(lyaml.dump, { merged })
	if not ok or not rendered then
		io.stderr:write("dump_failed\n")
		return false
	end

	write_file(output_path, rendered)
	io.stdout:write(string.format("filled_groups=%d stripped_script_rules=%d\n", filled_groups, stripped_rules))
	return true
end

local function append_client_policy_rules(runtime_path, sid)
	local doc, err = load_yaml(runtime_path)
	if not doc then
		io.stderr:write(err or "parse_failed", "\n")
		return false
	end

	local valid_policies = {}
	for _, proxy in ipairs(doc.proxies or {}) do
		if type(proxy) == "table" and proxy.name and proxy.name ~= "" then
			valid_policies[tostring(proxy.name)] = true
		end
	end
	for _, group in ipairs(doc["proxy-groups"] or {}) do
		if type(group) == "table" and group.name and group.name ~= "" then
			valid_policies[tostring(group.name)] = true
		end
	end

	local custom_rules = {}
	for _, section in ipairs(read_clash_client_rules_csv(sid)) do
		if tostring(section.enabled or "0") == "1" then
			local ip_addr = tostring(section.ip_addr or "")
			local policy_group = tostring(section.policy_group or "")
			if ip_addr ~= "" and policy_group ~= "" and valid_policies[policy_group] then
				if not ip_addr:find("/", 1, true) then
					ip_addr = ip_addr .. "/32"
				end
				custom_rules[#custom_rules + 1] = string.format("SRC-IP-CIDR,%s,%s", ip_addr, policy_group)
			end
		end
	end

	if #custom_rules == 0 then
		io.stdout:write("client_rules=0\n")
		return true
	end

	local existing_rules = {}
	for _, rule in ipairs(doc.rules or {}) do
		local text = tostring(rule or "")
		if not text:match("^SRC%-IP%-CIDR,") then
			existing_rules[#existing_rules + 1] = rule
		end
	end

	doc.rules = {}
	for _, rule in ipairs(custom_rules) do
		doc.rules[#doc.rules + 1] = rule
	end
	for _, rule in ipairs(existing_rules) do
		doc.rules[#doc.rules + 1] = rule
	end

	local ok, rendered = pcall(lyaml.dump, { doc })
	if not ok or not rendered then
		io.stderr:write("dump_failed\n")
		return false
	end

	write_file(runtime_path, rendered)
	io.stdout:write(string.format("client_rules=%d\n", #custom_rules))
	return true
end

local function bool_enabled(value)
	return value == "1" or value == 1 or value == true or value == "true"
end

local function split_csv(value)
	local items = {}
	for part in tostring(value or ""):gmatch("[^,%s]+") do
		items[#items + 1] = part
	end
	return items
end

local function get_server_field(sid, option, default)
	local value = uci:get("shadowsocksr", sid, option)
	if value == nil or value == "" then
		return default
	end
	return value
end

local function get_filter_aaaa()
	local value = uci:get_first("shadowsocksr", "global", "filter_aaaa", "1")
	if value == nil or value == "" then
		value = uci:get_first("shadowsocksr", "global", "mosdns_ipv6", "1")
	end
	return value
end

local function build_tuic_runtime_doc(sid, local_port, socks_port, mode)
	local server = get_server_field(sid, "server", "")
	local server_port = tonumber(get_server_field(sid, "server_port", "0")) or 0
	local tuic_ip = get_server_field(sid, "tuic_ip", "")
	local tls_host = get_server_field(sid, "tls_host", "")
	local ipstack_prefer = get_server_field(sid, "ipstack_prefer", "")
	local dns_mode = uci:get_first("shadowsocksr", "global", "pdnsd_enable", "0")

	local proxy = {
		name = sid,
		type = "tuic",
		server = server,
		port = server_port,
		uuid = get_server_field(sid, "tuic_uuid", ""),
		password = get_server_field(sid, "tuic_passwd", ""),
		["udp-relay-mode"] = get_server_field(sid, "udp_relay_mode", "native"),
		["congestion-controller"] = get_server_field(sid, "congestion_control", "cubic"),
		["skip-cert-verify"] = bool_enabled(get_server_field(sid, "insecure", "0")),
		["disable-sni"] = bool_enabled(get_server_field(sid, "disable_sni", "0")),
		["reduce-rtt"] = bool_enabled(get_server_field(sid, "zero_rtt_handshake", "0"))
	}

	if tuic_ip ~= "" then
		proxy.ip = tuic_ip
	end
	if tls_host ~= "" then
		proxy.sni = tls_host
	end

	local alpn = split_csv(get_server_field(sid, "tuic_alpn", ""))
	if #alpn > 0 then
		proxy.alpn = alpn
	end

	local heartbeat = tonumber(get_server_field(sid, "heartbeat", "0"))
	if heartbeat and heartbeat > 0 then
		proxy["heartbeat-interval"] = heartbeat * 1000
	end

	local timeout = tonumber(get_server_field(sid, "timeout", "0"))
	if timeout and timeout > 0 then
		proxy["request-timeout"] = timeout * 1000
	end

	local max_udp_packet_size = tonumber(get_server_field(sid, "tuic_max_package_size", "0"))
	if max_udp_packet_size and max_udp_packet_size > 0 then
		proxy["max-udp-relay-packet-size"] = max_udp_packet_size
	end

	if ipstack_prefer ~= "" then
		proxy["ip-version"] = ipstack_prefer == "v6first" and "ipv6-prefer" or "ipv4-prefer"
	end

	local listen_port = tonumber(local_port)
	local socks_listen = tonumber(socks_port)

	local doc = {
		["allow-lan"] = true,
		["bind-address"] = "0.0.0.0",
		mode = "rule",
		["log-level"] = "silent",
		["find-process-mode"] = "off",
		["unified-delay"] = true,
		["tcp-concurrent"] = true,
		["routing-mark"] = 255,
		proxies = { proxy },
		["proxy-groups"] = {
			{
				name = "PROXY",
				type = "select",
				proxies = { sid }
			}
		},
		rules = { "MATCH,PROXY" },
		tun = { enable = false },
		profile = { ["store-selected"] = true },
		dns = {
			enable = dns_mode == "7",
			["enhanced-mode"] = "redir-host",
			listen = "127.0.0.1:5335",
			ipv6 = get_filter_aaaa() ~= "1"
		}
	}

	if mode == "socks" then
		doc["socks-port"] = listen_port
	else
		doc["redir-port"] = listen_port
		doc["tproxy-port"] = listen_port
		if socks_listen and socks_listen > 0 then
			doc["socks-port"] = socks_listen
		end
	end

	return doc
end

local function generate_tuic_runtime(sid, output_path, local_port, socks_port, mode)
	local doc = build_tuic_runtime_doc(sid, local_port, socks_port, mode)
	local ok, rendered = pcall(lyaml.dump, { doc })
	if not ok or not rendered then
		io.stderr:write("dump_failed\n")
		return false
	end
	write_file(output_path, rendered)
	return true
end

local function parse_plugin_opts(value)
	local result = {}
	for part in tostring(value or ""):gmatch("[^;]+") do
		local key, val = part:match("^%s*([^=]+)=?(.*)%s*$")
		if key and key ~= "" then
			result[key] = val or ""
		end
	end
	return result
end

local function split_host_port(value)
	local text = tostring(value or "")
	if text == "" then
		return "", ""
	end
	local host, port = text:match("^%[(.-)%]:(%d+)$")
	if host and port then
		return host, port
	end
	host, port = text:match("^(.-):(%d+)$")
	if host and port then
		return host, port
	end
	return text, ""
end

local function bool_default(value, default)
	if value == nil or value == "" then
		return default
	end
	return bool_enabled(value)
end

local function number_or_nil(value)
	if value == nil or value == "" then
		return nil
	end
	return tonumber(value)
end

local function string_or_nil(value)
	if value == nil or value == "" then
		return nil
	end
	return tostring(value)
end

local function pick_plugin_opt(plugin_opts, ...)
	for i = 1, select("#", ...) do
		local key = select(i, ...)
		local value = plugin_opts[key]
		if value ~= nil and value ~= "" then
			return value
		end
	end
	return nil
end

local function parse_plugin_headers(plugin_opts)
	local headers = {}
	local raw_headers = pick_plugin_opt(plugin_opts, "headers", "header")

	if raw_headers and ok_jsonc and jsonc then
		local decoded = jsonc.parse(raw_headers)
		if type(decoded) == "table" then
			for key, value in pairs(decoded) do
				headers[tostring(key)] = tostring(value)
			end
		end
	end

	if raw_headers and next(headers) == nil then
		for part in tostring(raw_headers):gmatch("[^|,]+") do
			local key, value = part:match("^%s*([^=:]+)%s*[:=]%s*(.-)%s*$")
			if key and key ~= "" and value and value ~= "" then
				headers[key] = value
			end
		end
	end

	for key, value in pairs(plugin_opts) do
		local header_name = key:match("^headers[%.:](.+)$")
			or key:match("^header[%.:](.+)$")
			or key:match("^header_(.+)$")
		if header_name and header_name ~= "" and value ~= "" then
			headers[header_name] = value
		end
	end

	return next(headers) and headers or nil
end

local function get_plugin_client_fingerprint(sid, plugin_opts)
	return string_or_nil(
		pick_plugin_opt(
			plugin_opts,
			"client-fingerprint",
			"client_fingerprint",
			"fingerprint"
		) or get_server_field(sid, "fingerprint", "")
	)
end

local function normalize_plugin_name(plugin)
	local value = tostring(plugin or ""):lower()
	if value == "" or value == "none" then
		return ""
	end
	if value == "simple-obfs" then
		return "obfs-local"
	end
	if value == "obfs" then
		return "obfs-local"
	end
	if value == "shadowtls" then
		return "shadow-tls"
	end
	if value == "gost" then
		return "gost-plugin"
	end
	if value == "kcp-tun" then
		return "kcptun"
	end
	return value
end

local function build_shadowsocks_plugin(proxy, sid)
	local plugin = normalize_plugin_name(get_server_field(sid, "plugin", ""))
	local plugin_opts = parse_plugin_opts(get_server_field(sid, "plugin_opts", ""))

	if plugin == "" then
		return
	end

	if plugin == "obfs-local" then
		proxy.plugin = "obfs"
		proxy["plugin-opts"] = {
			mode = pick_plugin_opt(plugin_opts, "obfs", "mode") or "http",
			host = string_or_nil(pick_plugin_opt(plugin_opts, "obfs-host", "obfs_host", "host"))
		}
		return
	end

	if plugin == "v2ray-plugin" or plugin == "xray-plugin" then
		proxy.plugin = "v2ray-plugin"
		proxy["plugin-opts"] = {
			mode = pick_plugin_opt(plugin_opts, "mode") or "websocket",
			tls = bool_default(pick_plugin_opt(plugin_opts, "tls"), false),
			fingerprint = string_or_nil(pick_plugin_opt(plugin_opts, "fingerprint")),
			["skip-cert-verify"] = bool_default(pick_plugin_opt(plugin_opts, "skip-cert-verify", "skip_cert_verify", "insecure"), false),
			host = string_or_nil(pick_plugin_opt(plugin_opts, "host")),
			path = string_or_nil(pick_plugin_opt(plugin_opts, "path")),
			mux = bool_default(pick_plugin_opt(plugin_opts, "mux"), false),
			headers = parse_plugin_headers(plugin_opts),
			["v2ray-http-upgrade"] = bool_default(pick_plugin_opt(plugin_opts, "v2ray-http-upgrade", "v2ray_http_upgrade"), false)
		}
		return
	end

	if plugin == "gost-plugin" then
		proxy.plugin = "gost-plugin"
		proxy["plugin-opts"] = {
			mode = pick_plugin_opt(plugin_opts, "mode") or "websocket",
			tls = bool_default(pick_plugin_opt(plugin_opts, "tls"), false),
			fingerprint = string_or_nil(pick_plugin_opt(plugin_opts, "fingerprint")),
			["skip-cert-verify"] = bool_default(pick_plugin_opt(plugin_opts, "skip-cert-verify", "skip_cert_verify", "insecure"), false),
			host = string_or_nil(pick_plugin_opt(plugin_opts, "host")),
			path = string_or_nil(pick_plugin_opt(plugin_opts, "path")),
			mux = bool_default(pick_plugin_opt(plugin_opts, "mux"), false),
			headers = parse_plugin_headers(plugin_opts)
		}
		return
	end

	if plugin == "shadow-tls" then
		local host, port = split_host_port(pick_plugin_opt(plugin_opts, "host") or "")
		local version
		if plugin_opts.v3 == "1" or plugin_opts.version == "3" then
			version = 3
		elseif plugin_opts.v2 == "1" or plugin_opts.version == "2" then
			version = 2
		elseif plugin_opts.v1 == "1" or plugin_opts.version == "1" then
			version = 1
		end
		proxy.plugin = "shadow-tls"
		proxy["client-fingerprint"] = get_plugin_client_fingerprint(sid, plugin_opts)
		proxy["plugin-opts"] = {
			host = host ~= "" and host or nil,
			port = number_or_nil(port),
			password = string_or_nil(pick_plugin_opt(plugin_opts, "passwd", "password")),
			version = version
		}
		return
	end

	if plugin == "restls" then
		proxy.plugin = "restls"
		proxy["client-fingerprint"] = get_plugin_client_fingerprint(sid, plugin_opts)
		proxy["plugin-opts"] = {
			host = string_or_nil(pick_plugin_opt(plugin_opts, "host")),
			password = string_or_nil(pick_plugin_opt(plugin_opts, "passwd", "password")),
			["version-hint"] = string_or_nil(pick_plugin_opt(plugin_opts, "version-hint", "version_hint")),
			["restls-script"] = string_or_nil(pick_plugin_opt(plugin_opts, "restls-script", "restls_script"))
		}
		return
	end

	if plugin == "kcptun" then
		proxy.plugin = "kcptun"
		proxy["plugin-opts"] = {
			key = string_or_nil(pick_plugin_opt(plugin_opts, "key", "passwd", "password")),
			crypt = string_or_nil(pick_plugin_opt(plugin_opts, "crypt")),
			mode = string_or_nil(pick_plugin_opt(plugin_opts, "mode")),
			conn = number_or_nil(pick_plugin_opt(plugin_opts, "conn")),
			autoexpire = number_or_nil(pick_plugin_opt(plugin_opts, "autoexpire")),
			scavengettl = number_or_nil(pick_plugin_opt(plugin_opts, "scavengettl")),
			mtu = number_or_nil(pick_plugin_opt(plugin_opts, "mtu")),
			ratelimit = number_or_nil(pick_plugin_opt(plugin_opts, "ratelimit")),
			sndwnd = number_or_nil(pick_plugin_opt(plugin_opts, "sndwnd")),
			rcvwnd = number_or_nil(pick_plugin_opt(plugin_opts, "rcvwnd")),
			datashard = number_or_nil(pick_plugin_opt(plugin_opts, "datashard")),
			parityshard = number_or_nil(pick_plugin_opt(plugin_opts, "parityshard")),
			dscp = number_or_nil(pick_plugin_opt(plugin_opts, "dscp")),
			nocomp = bool_default(pick_plugin_opt(plugin_opts, "nocomp"), false),
			acknodelay = bool_default(pick_plugin_opt(plugin_opts, "acknodelay"), false),
			nodelay = number_or_nil(pick_plugin_opt(plugin_opts, "nodelay")),
			interval = number_or_nil(pick_plugin_opt(plugin_opts, "interval")),
			resend = number_or_nil(pick_plugin_opt(plugin_opts, "resend")),
			sockbuf = number_or_nil(pick_plugin_opt(plugin_opts, "sockbuf")),
			smuxver = number_or_nil(pick_plugin_opt(plugin_opts, "smuxver")),
			smuxbuf = number_or_nil(pick_plugin_opt(plugin_opts, "smuxbuf")),
			framesize = number_or_nil(pick_plugin_opt(plugin_opts, "framesize")),
			streambuf = number_or_nil(pick_plugin_opt(plugin_opts, "streambuf")),
			keepalive = number_or_nil(pick_plugin_opt(plugin_opts, "keepalive"))
		}
		return
	end

	proxy.plugin = plugin
	if next(plugin_opts) then
		proxy["plugin-opts"] = plugin_opts
	end
end

local function build_kcptun_plugin(proxy, sid)
	if not bool_enabled(get_server_field(sid, "kcp_enable", "0")) then
		return
	end

	proxy.plugin = "kcptun"
	proxy.port = tonumber(get_server_field(sid, "kcp_port", "0")) or proxy.port
	proxy["plugin-opts"] = {
		key = get_server_field(sid, "kcp_password", ""),
		mode = "fast",
		mtu = 1350
	}
end

local function build_shadowsocks_runtime_doc(sid, local_port, socks_port, mode)
	local dns_mode = uci:get_first("shadowsocksr", "global", "pdnsd_enable", "0")
	local server = get_server_field(sid, "server", "")
	local server_port = tonumber(get_server_field(sid, "server_port", "0")) or 0
	local method = get_server_field(sid, "encrypt_method_ss", "none")
	local password = get_server_field(sid, "password", "")
	local proxy = {
		name = sid,
		type = "ss",
		server = server,
		port = server_port,
		cipher = method,
		password = password,
		udp = true,
		tfo = bool_enabled(get_server_field(sid, "fast_open", "0"))
	}

	if get_server_field(sid, "type", "") == "ss" then
		build_kcptun_plugin(proxy, sid)
	end
	if proxy.plugin == nil then
		build_shadowsocks_plugin(proxy, sid)
	end

	local doc = {
		["allow-lan"] = true,
		["bind-address"] = "0.0.0.0",
		mode = "rule",
		["log-level"] = "silent",
		["find-process-mode"] = "off",
		["unified-delay"] = true,
		["tcp-concurrent"] = true,
		["routing-mark"] = 255,
		proxies = { proxy },
		["proxy-groups"] = {
			{
				name = "PROXY",
				type = "select",
				proxies = { sid }
			}
		},
		rules = { "MATCH,PROXY" },
		tun = { enable = false },
		profile = { ["store-selected"] = true },
		dns = {
			enable = dns_mode == "7",
			["enhanced-mode"] = "redir-host",
			listen = "127.0.0.1:5335",
			ipv6 = get_filter_aaaa() ~= "1"
		}
	}

	local listen_port = tonumber(local_port)
	local socks_listen = tonumber(socks_port)
	if mode == "socks" then
		doc["socks-port"] = listen_port
	else
		doc["redir-port"] = listen_port
		doc["tproxy-port"] = listen_port
		if socks_listen and socks_listen > 0 then
			doc["socks-port"] = socks_listen
		end
	end

	return doc
end

local function generate_shadowsocks_runtime(sid, output_path, local_port, socks_port, mode)
	local doc = build_shadowsocks_runtime_doc(sid, local_port, socks_port, mode)
	local ok, rendered = pcall(lyaml.dump, { doc })
	if not ok or not rendered then
		io.stderr:write("dump_failed\n")
		return false
	end
	write_file(output_path, rendered)
	return true
end

local function build_shadowsocks_server_doc(sid)
	local server_port = tonumber(get_server_field(sid, "server_port", "0")) or 0
	local method = get_server_field(sid, "encrypt_method_ss", "aes-128-gcm")
	local password = get_server_field(sid, "password", "")
	local listener = {
		name = sid,
		type = "shadowsocks",
		listen = "::",
		port = server_port,
		cipher = method,
		password = password,
		udp = true,
		tfo = bool_enabled(get_server_field(sid, "fast_open", "0"))
	}

	local plugin = normalize_plugin_name(get_server_field(sid, "plugin", ""))
	if plugin == "obfs-local" then
		local plugin_opts = parse_plugin_opts(get_server_field(sid, "plugin_opts", ""))
		listener.obfs = plugin_opts.obfs or plugin_opts.mode or "http"
		listener.obfs_opts = {
			mode = plugin_opts.obfs or plugin_opts.mode or "http",
			host = plugin_opts["obfs-host"] or plugin_opts.obfs_host or plugin_opts.host or nil
		}
	end

	return {
		["allow-lan"] = true,
		["bind-address"] = "*",
		["log-level"] = "silent",
		["find-process-mode"] = "off",
		listeners = { listener }
	}
end

local function generate_shadowsocks_server(sid, output_path)
	local doc = build_shadowsocks_server_doc(sid)
	local ok, rendered = pcall(lyaml.dump, { doc })
	if not ok or not rendered then
		io.stderr:write("dump_failed\n")
		return false
	end
	write_file(output_path, rendered)
	return true
end

local action = arg[1]
if action == "validate" then
	os.exit(validate(arg[2]) and 0 or 1)
elseif action == "filter" then
	os.exit(filter(arg[2], arg[3]) and 0 or 1)
elseif action == "prepare" then
	os.exit(prepare(arg[2], arg[3]) and 0 or 1)
elseif action == "merge" then
	os.exit(merge(arg[2], arg[3], arg[4]) and 0 or 1)
elseif action == "append_client_policy_rules" then
	os.exit(append_client_policy_rules(arg[2], arg[3]) and 0 or 1)
elseif action == "tuic" then
	os.exit(generate_tuic_runtime(arg[2], arg[3], arg[4], arg[5], arg[6]) and 0 or 1)
elseif action == "ss" then
	os.exit(generate_shadowsocks_runtime(arg[2], arg[3], arg[4], arg[5], arg[6]) and 0 or 1)
elseif action == "ss_server" then
	os.exit(generate_shadowsocks_server(arg[2], arg[3]) and 0 or 1)
else
	io.stderr:write("usage: clash_yaml.lua validate <yaml> | filter <yaml> <words> | prepare <input> <output> | merge <raw> <overlay> <output> | append_client_policy_rules <runtime_yaml> <sid> | tuic <sid> <output> <local_port> [socks_port] [mode] | ss <sid> <output> <local_port> [socks_port] [mode] | ss_server <sid> <output>\n")
	os.exit(1)
end
