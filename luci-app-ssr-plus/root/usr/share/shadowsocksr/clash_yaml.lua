#!/usr/bin/lua

require "nixio.fs"
require "luci.model.uci"

local ok_lyaml, lyaml = pcall(require, "lyaml")
if not ok_lyaml then
	io.stderr:write("lyaml_not_found\n")
	os.exit(2)
end

local uci = require "luci.model.uci".cursor()

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

local function append_client_policy_rules(runtime_path)
	local doc, err = load_yaml(runtime_path)
	if not doc then
		io.stderr:write(err or "parse_failed", "\n")
		return false
	end

	local custom_rules = {}
	uci:foreach("shadowsocksr", "clash_client_group", function(section)
		if tostring(section.enabled or "0") == "1" then
			local ip_addr = tostring(section.ip_addr or "")
			local policy_group = tostring(section.policy_group or "")
			if ip_addr ~= "" and policy_group ~= "" then
				if not ip_addr:find("/", 1, true) then
					ip_addr = ip_addr .. "/32"
				end
				custom_rules[#custom_rules + 1] = string.format("SRC-IP-CIDR,%s,%s", ip_addr, policy_group)
			end
		end
	end)

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

local function normalize_plugin_name(plugin)
	local value = tostring(plugin or ""):lower()
	if value == "" or value == "none" then
		return ""
	end
	if value == "simple-obfs" then
		return "obfs-local"
	end
	return value
end

local function apply_shadowsocks_plugin(proxy, sid)
	local plugin = normalize_plugin_name(get_server_field(sid, "plugin", ""))
	local plugin_opts = parse_plugin_opts(get_server_field(sid, "plugin_opts", ""))

	if plugin == "" then
		return
	end

	if plugin == "obfs-local" then
		proxy.plugin = "obfs"
		proxy["plugin-opts"] = {
			mode = plugin_opts.obfs or plugin_opts.mode or "http",
			host = plugin_opts.obfs_host or plugin_opts.host or nil
		}
		return
	end

	if plugin == "v2ray-plugin" then
		proxy.plugin = "v2ray-plugin"
		proxy["plugin-opts"] = {
			mode = plugin_opts.mode or "websocket",
			host = plugin_opts.host or nil,
			path = plugin_opts.path or nil,
			tls = bool_default(plugin_opts.tls, false),
			mux = bool_default(plugin_opts.mux, false),
			["skip-cert-verify"] = bool_default(plugin_opts.insecure or plugin_opts.skip_cert_verify, false)
		}
		return
	end

	if plugin == "shadow-tls" then
		local host, port = split_host_port(plugin_opts.host or "")
		local version
		if plugin_opts.v3 == "1" or plugin_opts.version == "3" then
			version = 3
		elseif plugin_opts.v2 == "1" or plugin_opts.version == "2" then
			version = 2
		end
		proxy.plugin = "shadow-tls"
		proxy["plugin-opts"] = {
			host = host ~= "" and host or nil,
			port = tonumber(port) or nil,
			password = plugin_opts.password or plugin_opts.passwd or nil,
			version = version
		}
		if get_server_field(sid, "client_fingerprint", "") ~= "" then
			proxy["client-fingerprint"] = get_server_field(sid, "client_fingerprint", "")
		end
		return
	end

	if plugin == "kcptun" then
		proxy.plugin = "kcptun"
		proxy["plugin-opts"] = {
			mode = plugin_opts.mode or "fast",
			host = plugin_opts.host or nil,
			port = tonumber(plugin_opts.port) or nil,
			key = plugin_opts.key or plugin_opts.password or plugin_opts.passwd or nil,
			mtu = tonumber(plugin_opts.mtu) or nil,
			sndwnd = tonumber(plugin_opts.sndwnd) or nil,
			rcvwnd = tonumber(plugin_opts.rcvwnd) or nil
		}
		return
	end

	proxy.plugin = plugin
	if next(plugin_opts) then
		proxy["plugin-opts"] = plugin_opts
	end
end

local function apply_kcptun_legacy(proxy, sid)
	if not bool_enabled(get_server_field(sid, "kcp_enable", "0")) then
		return
	end
	proxy.plugin = "kcptun"
	proxy["plugin-opts"] = {
		mode = "fast",
		host = get_server_field(sid, "server", ""),
		port = tonumber(get_server_field(sid, "kcp_port", "0")) or nil,
		key = get_server_field(sid, "kcp_password", ""),
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
	apply_kcptun_legacy(proxy, sid)
	if proxy.plugin == nil then
		apply_shadowsocks_plugin(proxy, sid)
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
	os.exit(append_client_policy_rules(arg[2]) and 0 or 1)
elseif action == "tuic" then
	os.exit(generate_tuic_runtime(arg[2], arg[3], arg[4], arg[5], arg[6]) and 0 or 1)
elseif action == "ss" then
	os.exit(generate_shadowsocks_runtime(arg[2], arg[3], arg[4], arg[5], arg[6]) and 0 or 1)
elseif action == "ss_server" then
	os.exit(generate_shadowsocks_server(arg[2], arg[3]) and 0 or 1)
else
	io.stderr:write("usage: clash_yaml.lua validate <yaml> | filter <yaml> <words> | prepare <input> <output> | merge <raw> <overlay> <output> | append_client_policy_rules <runtime_yaml> | tuic <sid> <output> <local_port> [socks_port] [mode] | ss <sid> <output> <local_port> [socks_port] [mode] | ss_server <sid> <output>\n")
	os.exit(1)
end
