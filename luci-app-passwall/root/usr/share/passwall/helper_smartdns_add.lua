local api = require "luci.passwall.api"

local var = api.get_args(arg)
local FLAG = var["-FLAG"]
local DIRECT_DNS = var["-DIRECT_DNS"]
local LOCAL_PORT = tonumber(var["-LOCAL_PORT"]) or 0
local REMOTE_PROXY_SERVER = var["-REMOTE_PROXY_SERVER"]
local USE_DEFAULT_DNS = var["-USE_DEFAULT_DNS"]
local REMOTE_DNS = var["-REMOTE_DNS"]
local TUN_DNS = var["-TUN_DNS"]
local DNS_MODE = var["-DNS_MODE"]
local NODE = var["-NODE"]
local USE_DIRECT_LIST = var["-USE_DIRECT_LIST"]
local USE_PROXY_LIST = var["-USE_PROXY_LIST"]
local USE_BLOCK_LIST = var["-USE_BLOCK_LIST"]
local USE_GFW_LIST = var["-USE_GFW_LIST"]
local CHN_LIST = var["-CHN_LIST"]
local DEFAULT_PROXY_MODE = var["-DEFAULT_PROXY_MODE"]
local NO_PROXY_IPV6 = var["-NO_PROXY_IPV6"]
local NO_LOGIC_LOG = var["-NO_LOGIC_LOG"]
local NFTFLAG = var["-NFTFLAG"]
local SUBNET = var["-SUBNET"]
local LISTEN_PORT = var["-LISTEN_PORT"]
local DNS_REDIRECT = var["-DNS_REDIRECT"] == "1"
local LOG = var["-LOG"] == "1"
local LOG_LEVEL = var["-LOG_LEVEL"] or "error"
local LOG_SIZE = tonumber(var["-LOG_SIZE"]) or 1
local UI = var["-UI"] == "1"
local UI_PORT = tonumber(var["-UI_PORT"]) or 9880
local UI_DATA_DIR = var["-UI_DATA_DIR"]
local UI_LOG_MAX_AGE = tonumber(var["-UI_LOG_MAX_AGE"]) or 7

local sys = api.sys
local fs = api.fs
local datatypes = api.datatypes

local TMP_PATH = api.TMP_PATH
local RULES_PATH = "/usr/share/passwall/rules"
local USER_RULES_PATH = "/etc/passwall/rules"
local CACHE_RULES_PATH = api.CACHE_PATH .. "/user_rules"
local FLAG_PATH = TMP_PATH .. "/acl/" .. FLAG
local TMP_CONF_FILE = FLAG_PATH .. "/smartdns.conf"
local SMARTDNS_DATA_PATH = api.CACHE_PATH .. "/smartdns"
local config_lines = {}
local tmp_lines = {}
local USE_GEOVIEW = api.uci_get_c("@global_rules[0]", "enable_geoview")
local IS_SHUNT_NODE = api.uci_get_c(NODE, "protocol") == "_shunt"

if not api.is_finded("geoview") then
	USE_GEOVIEW = "0"
end

local function log(...)
	if NO_LOGIC_LOG == "1" then
		return
	end
	api.log(...)
end

local function is_file_nonzero(path)
	if path and #path > 1 then
		if sys.exec('[ -s "%s" ] && echo -n 1' % path) == "1" then
			return true
		end
	end
	return nil
end

local function insert_unique(dest_table, value, lookup_table)
	if not lookup_table[value] then
		table.insert(dest_table, value)
		lookup_table[value] = true
	end
end

local function merge_array(array1, array2)
	for i, line in ipairs(array2) do
		table.insert(array1, #array1 + 1, line)
	end
end

local function insert_array_before(array1, array2, target) --将array2插入到array1的target前面，target不存在则追加
	for i, line in ipairs(array1) do
		if line == target then
			for j = #array2, 1, -1 do
				table.insert(array1, i, array2[j])
			end
			return
		end
	end
	merge_array(array1, array2)
end

local function insert_array_after(array1, array2, target) --将array2插入到array1的target后面，target不存在则追加
	for i, line in ipairs(array1) do
		if line == target then
			for j = 1, #array2 do
				table.insert(array1, i + j, array2[j])
			end
			return
		end
	end
	merge_array(array1, array2)
end

local function get_geosite(list_arg, out_path)
	local geosite_path = api.uci_get_c("@global_rules[0]", "v2ray_location_asset") or "/usr/share/v2ray/"
	geosite_path = geosite_path:match("^(.*)/") .. "/geosite.dat"
	if not is_file_nonzero(geosite_path) then return 1, "File geosite.dat not found" end
	if not list_arg or list_arg == "" then return 1, "Site list cannot be empty" end
	if not out_path or out_path == "" then return 1, "Output path cannot be empty" end
	local bin = api.finded_com("geoview")
	local cmd = string.format("%q -type geosite -append=true -input %q -list %q -output %q -lowmem=true",
		bin, geosite_path, list_arg, out_path)
	return api.exec_call(cmd)
end

sys.call("mkdir -p %s" % FLAG_PATH)
sys.call("mkdir -p %s" % CACHE_RULES_PATH)
sys.call("mkdir -p " .. api.util.shellquote(SMARTDNS_DATA_PATH))

local LOG_LEVELS = {off = true, fatal = true, error = true, warn = true, notice = true, info = true, debug = true}
if not LOG_LEVELS[LOG_LEVEL] then LOG_LEVEL = "error" end
if LOG_SIZE < 1 or LOG_SIZE % 1 ~= 0 then LOG_SIZE = 1 end
if UI_PORT < 1 or UI_PORT > 65535 or UI_PORT % 1 ~= 0 then UI_PORT = 9880 end
if UI_LOG_MAX_AGE < 1 or UI_LOG_MAX_AGE % 1 ~= 0 then UI_LOG_MAX_AGE = 7 end
if not UI_DATA_DIR or UI_DATA_DIR == "" then UI_DATA_DIR = SMARTDNS_DATA_PATH end
local UI_PLUGIN = "/usr/lib/smartdns_ui.so"
if not fs.access(UI_PLUGIN) then UI_PLUGIN = "/usr/lib/smartdns/smartdns_ui.so" end
local ENABLE_UI = UI and fs.access(UI_PLUGIN)
local data_dir = ENABLE_UI and UI_DATA_DIR or SMARTDNS_DATA_PATH
if data_dir ~= SMARTDNS_DATA_PATH then
	sys.call("mkdir -p " .. api.util.shellquote(data_dir))
end

-- 统一生成直连、远程上游，协议和默认端口由 SmartDNS 根据 URL 识别。
local function make_server_param(endpoint)
	local dns = api.split(api.trim(endpoint), ",")
	local address = api.trim(dns[1] or "")
	if address == "" then return nil end
	local protocol, host_address = address:match("^(%w+)://(.+)$")
	protocol = protocol and protocol:lower()
	address = host_address or address
	local host, port = address:match("^(.-)#(%d+)$")
	if host then
		if host:find(":", 1, true) and not host:find("[", 1, true) then host = "[" .. host .. "]" end
		address = host .. ":" .. port
	elseif datatypes.ip6addr(address) and not address:find("[", 1, true) then
		address = "[" .. address .. "]"
	end
	local server_param = "server " .. (protocol and (protocol .. "://") or "") .. address
	if dns[2] and dns[2] ~= "" then
		-- 保留 URL 中的域名，固定连接 IP 交给 SmartDNS 处理，避免手动替换影响 SNI 和 HTTP Host。
		server_param = server_param .. " -host-ip " .. api.trim(dns[2]):gsub("^%[(.*)%]$", "%1")
	end
	return server_param
end

local DIRECT_SERVERS = {}
for endpoint in string.gmatch(DIRECT_DNS or "", "[^|]+") do
	local server_param = make_server_param(endpoint)
	if server_param then
		-- 复用 PassWall 的直连标记，使所有协议及动态域名上游绕过本机透明代理。
		table.insert(DIRECT_SERVERS, server_param .. " -set-mark 255")
	end
end
if #DIRECT_SERVERS == 0 then
	log("  * 注意：SmartDNS 没有可用的直连 DNS 服务器，DNS 将无法正常工作！！！")
	os.exit(1)
end

local AUTO_GROUP = "auto"
local auto_config_lines = {}
-- 直连规则显式覆盖远程兜底的缓存、IPv6、测速和双栈优选设置。
local DIRECT_RULE_OPTIONS = " -enable-cache -address -6 -speed-check-mode ping,tcp:80,tcp:443 -response-mode first-ping -d yes"
--设置默认 DNS 分组(兜底组)，全局代理模式仍使用远程组。
local DEFAULT_DNS_GROUP = (USE_DEFAULT_DNS == "direct" and "direct") or
                          (USE_DEFAULT_DNS == "remote" and "proxy") or
                          (USE_DEFAULT_DNS == "auto" and AUTO_GROUP)
local only_global = (DEFAULT_PROXY_MODE == "proxy" and CHN_LIST == "0" and USE_GFW_LIST == "0") and 1
if only_global == 1 then
	DEFAULT_DNS_GROUP = "proxy"
end
local AUTO_DIRECT_PORT = 0
if DEFAULT_DNS_GROUP == AUTO_GROUP then
	AUTO_DIRECT_PORT = api.get_new_port(15350)
	-- 避开同一进程尚未启动的主监听和直连监听端口。
	for _ = 1, 2 do
		if not AUTO_DIRECT_PORT or (AUTO_DIRECT_PORT ~= tonumber(LISTEN_PORT) and AUTO_DIRECT_PORT ~= LOCAL_PORT) then break end
		AUTO_DIRECT_PORT = api.get_new_port(AUTO_DIRECT_PORT + 1)
	end
end
local force_https_soa = api.uci_get_c("@global[0]", "force_https_soa") or 0
local force_qtype_soa = tonumber(force_https_soa) == 1 and "force-qtype-SOA 65" or "force-qtype-SOA -,65"
local proxy_server_name = "psw-proxy-server"
local listen_address = "[::]:" .. LISTEN_PORT .. (DNS_REDIRECT and "" or "@lo")
local local_domain = DNS_REDIRECT and api.uci_get("dhcp", "@dnsmasq[0]", "domain")
config_lines = {
	tonumber(LISTEN_PORT) ~= 0 and ("bind " .. listen_address) or "",
	tonumber(LISTEN_PORT) ~= 0 and ("bind-tcp " .. listen_address) or "",
	LOCAL_PORT > 0 and ("bind [::]:" .. LOCAL_PORT .. "@lo -group direct -no-rules") or "",
	LOCAL_PORT > 0 and ("bind-tcp [::]:" .. LOCAL_PORT .. "@lo -group direct -no-rules") or "",
	AUTO_DIRECT_PORT > 0 and ("bind [::]:" .. AUTO_DIRECT_PORT .. "@lo -group auto-direct") or "",
	"log-level " .. LOG_LEVEL,
	"log-num " .. (LOG and "1" or "0"),
	LOG and string.format("log-file %q", FLAG_PATH .. "/smartdns.log") or "",
	LOG and ("log-size " .. LOG_SIZE .. "M") or "",
	string.format("cache-file %q", SMARTDNS_DATA_PATH .. "/smartdns.cache"),
	string.format("data-dir %q", data_dir),
	"server 223.5.5.5 -bootstrap-dns -set-mark 255",
	-- Set the suffix before loading hosts/leases so initial records are expanded too.
	(local_domain and local_domain ~= "") and "local-domain " .. local_domain or "",
	DNS_REDIRECT and "hosts-file /tmp/hosts/*" or "",
	is_file_nonzero("/etc/hosts") and "hosts-file /etc/hosts" or "",
	DNS_MODE == "socks" and string.format("proxy-server socks5://%s -name %s", REMOTE_PROXY_SERVER, proxy_server_name) or ""
}
if ENABLE_UI then
	merge_array(config_lines, {
		"plugin " .. UI_PLUGIN,
		"smartdns-ui.www-root /usr/share/smartdns/wwwroot",
		"smartdns-ui.ip http://[::]:" .. UI_PORT,
		"smartdns-ui.max-query-log-age " .. (UI_LOG_MAX_AGE * 86400)
	})
end
if DNS_REDIRECT then
	local hosts = {}
	api.uci:foreach("dhcp", "host", function(s)
		if datatypes.hostname(s.name or "") and datatypes.ip4addr(s.ip or "") then
			hosts[#hosts + 1] = s.ip .. " " .. s.name
		end
	end)

	local hosts_file = FLAG_PATH .. "/dhcp-static-hosts"
	if fs.writefile(hosts_file, table.concat(hosts, "\n") .. "\n") and #hosts > 0 then
		table.insert(config_lines, string.format("hosts-file %q", hosts_file))
	end

	-- SmartDNS monitors the lease file and updates local records without a restart.
	local lease_file = api.uci_get("dhcp", "@dnsmasq[0]", "leasefile")
	if not lease_file or lease_file == "" then lease_file = "/tmp/dhcp.leases" end
	table.insert(config_lines, string.format("dnsmasq-lease-file %q", lease_file))
	local odhcpd_lease = api.uci_get("dhcp", "odhcpd", "leasefile")
	if odhcpd_lease and odhcpd_lease ~= "" then
		table.insert(config_lines, string.format("odhcpd-lease-file %q", odhcpd_lease))
	end
end
for _, server_param in ipairs(DIRECT_SERVERS) do
	table.insert(config_lines, server_param .. " -group direct -exclude-default-group")
end
if DEFAULT_DNS_GROUP == AUTO_GROUP then
	-- 自动组先通过独立入口去除 CNAME，再按原逻辑筛选 IP。
	table.insert(auto_config_lines, "server 127.0.0.1:" .. AUTO_DIRECT_PORT .. " -group " .. AUTO_GROUP .. " -exclude-default-group -whitelist-ip")
	table.insert(auto_config_lines, "group-begin auto-direct -inherit none")
	merge_array(auto_config_lines, DIRECT_SERVERS)
	merge_array(auto_config_lines, {"force-no-CNAME yes", "group-end"})
end

-- 由下方 DNS_MODE 分支调用，服务器参数来自 PassWall 的 REMOTE_DNS 或 TUN_DNS。
local function add_remote_server(server_param)
	table.insert(config_lines, server_param .. " -group proxy -exclude-default-group")
	if DEFAULT_DNS_GROUP == AUTO_GROUP then
		-- 远程副本作为自动组的后备服务器，保留代理、ECS 和传输协议参数。
		local auto_param = server_param .. " -group " .. AUTO_GROUP .. " -exclude-default-group -fallback"
		if NO_PROXY_IPV6 == "1" then auto_param = auto_param .. " -blacklist-ip" end
		table.insert(auto_config_lines, auto_param)
	end
end

if DNS_MODE == "socks" then
	for w in string.gmatch(REMOTE_DNS, '[^|]+') do
		local server_param = make_server_param(w)

		if not api.is_local_ip(w) then
			server_param = server_param .. " -proxy " .. proxy_server_name
		end

		if SUBNET and SUBNET ~= "" and SUBNET ~= "0" then
			server_param = server_param .. " -subnet " .. SUBNET
		end
		add_remote_server(server_param)
	end
else
	add_remote_server("server " .. TUN_DNS:gsub("#", ":"))
	log("  - " .. DNS_MODE:gsub("^%l",string.upper) .. " " .. TUN_DNS .. " -> 分组(proxy)")
end

if DEFAULT_DNS_GROUP == AUTO_GROUP then
	-- 仅自动组的服务器启用 IP 过滤，普通直连和代理组保持各自行为。
	if NO_PROXY_IPV6 == "1" then
		table.insert(auto_config_lines, "ip-rules ::/0 -blacklist-ip")
	end
	for _, name in ipairs({"chnroute", "chnroute6"}) do
		local path = RULES_PATH .. "/" .. name
		if is_file_nonzero(path) then
			local set_name = AUTO_GROUP .. "-" .. name
			table.insert(auto_config_lines, string.format("ip-set -name %s -file %s", set_name, path))
			local ip_rules = "ip-rules ip-set:" .. set_name .. " -whitelist-ip"
			if name == "chnroute6" and NO_PROXY_IPV6 == "1" then
				-- 最长前缀匹配时，大陆 IPv6 网段也需要黑名单标记才能过滤远程结果。
				ip_rules = ip_rules .. " -blacklist-ip"
			end
			table.insert(auto_config_lines, ip_rules)
		else
			log("  * 注意：SmartDNS 自动模式大陆 IP 列表不存在或为空：" .. path)
		end
	end
	merge_array(config_lines, auto_config_lines)
end

table.insert(config_lines, force_qtype_soa)

if DEFAULT_DNS_GROUP then
	local domain_rules_str = "domain-rules /./ -nameserver " .. DEFAULT_DNS_GROUP
	if DEFAULT_DNS_GROUP == "proxy" then
		-- 代理仍禁止写入缓存，去掉会被直连继承且无法反向覆盖的过期缓存限制。
		domain_rules_str = domain_rules_str .. " -no-cache -speed-check-mode none -d no"
		domain_rules_str = domain_rules_str .. " -address " .. ((only_global and IS_SHUNT_NODE) and "-6" or (NO_PROXY_IPV6 == "1" and "#6" or "-6"))
	end
	table.insert(config_lines, domain_rules_str)
end

local setflag = (NFTFLAG == "1") and "inet#passwall#" or ""
local set_type = (NFTFLAG == "1") and "-nftset" or "-ipset"

--预设排序标签(越往后优先级越高)
for i = 1, 10 do
	table.insert(config_lines, "#--" .. i)
end

--屏蔽列表
local file_block_host = CACHE_RULES_PATH .. "/block_host"
if not fs.access(file_block_host .. "_ok") then
	api.remove(file_block_host .. "*")
end
local block_geosite_flag = fs.access(file_block_host) and fs.access(file_block_host .. "_ok") and fs.access(file_block_host .. "_geo")
if USE_BLOCK_LIST == "1" and not fs.access(file_block_host) then
	local block_domain, lookup_block_domain = {}, {}
	local geosite_arg = ""
	local f = io.open(USER_RULES_PATH .. "/block_host")
	if f then
		for line in f:lines() do
			if not line:find("#") and line:find("geosite:") then
				line = string.match(line, ":([^:]+)$")
				geosite_arg = geosite_arg .. (geosite_arg ~= "" and "," or "") .. line
			else
				line = api.get_std_domain(line)
				if line ~= "" and not line:find("#") then
					insert_unique(block_domain, line, lookup_block_domain)
				end
			end
		end
		f:close()
	end
	if #block_domain > 0 then
		local f_out = io.open(file_block_host, "w")
		for i = 1, #block_domain do
			f_out:write(block_domain[i] .. "\n")
		end
		f_out:close()
	end
	local success = true
	if USE_GEOVIEW == "1" and geosite_arg ~= "" then
		local code, out = get_geosite(geosite_arg, file_block_host)
		if code == 0 then
			log("  - 解析[屏蔽列表] Geosite 到屏蔽域名表(blocklist)完成")
			sys.call("touch " .. file_block_host .. "_geo")
		else
			log("  - 解析[屏蔽列表] Geosite 到屏蔽域名表(blocklist)失败！[" .. out .. "]")
			success = false
		end
	end
	if success and fs.access(file_block_host) then
		sys.call("touch " .. file_block_host .. "_ok")
	end
end
if USE_BLOCK_LIST == "1" and is_file_nonzero(file_block_host) then
	if block_geosite_flag then
		log("  - [屏蔽列表] Geosite 使用缓存结果，跳过重复解析")
	end
	local domain_set_name = "psw-block"
	tmp_lines = {
		string.format("domain-set -name %s -file %s", domain_set_name, file_block_host),
		string.format("domain-rules /domain-set:%s/ -a #", domain_set_name)
	}
	insert_array_after(config_lines, tmp_lines, "#--8")
end

--始终用国内DNS解析节点域名
local file_vpslist = TMP_PATH .. "/vpslist"
if not is_file_nonzero(file_vpslist) then
	local f_out = io.open(file_vpslist, "w")
	local written_domains = {}
	local function process_address(address)
		address = (address or ""):lower()
		if api.vps_domain_exclude(address) then return end
		if datatypes.hostname(address) and not written_domains[address] then
			f_out:write(address .. "\n")
			written_domains[address] = true
		end
	end
	api.uci_foreach_c("nodes", function(t)
		process_address(t.address)
		process_address(t.download_address)
		local dns, _ = api.get_domain_port_from_url(t.domain_resolver_dns or t.domain_resolver_dns_https or "")
		if dns and dns ~= "" then
			process_address(dns)
		end
	end)
	f_out:close()
end
if is_file_nonzero(file_vpslist) then
	local domain_set_name = "psw-vpslist"
	tmp_lines = {
		string.format("domain-set -name %s -file %s", domain_set_name, file_vpslist)
	}
	local sets = {
		"#4:" .. setflag .. "psw_vps",
		"#6:" .. setflag .. "psw_vps6"
	}
	local domain_rules_str = string.format('domain-rules /domain-set:%s/ -nameserver direct', domain_set_name) .. DIRECT_RULE_OPTIONS
	domain_rules_str = domain_rules_str .. " " .. set_type .. " " .. table.concat(sets, ",")
	table.insert(tmp_lines, domain_rules_str)
	insert_array_after(config_lines, tmp_lines, "#--9")
	log("  - 节点列表中的域名(vpslist)使用分组：direct")
end

--直连（白名单）列表
local file_direct_host = CACHE_RULES_PATH .. "/direct_host"
if not fs.access(file_direct_host .. "_ok") then
	api.remove(file_direct_host .. "*")
end
local direct_geosite_flag = fs.access(file_direct_host) and fs.access(file_direct_host .. "_ok") and fs.access(file_direct_host .. "_geo")
if USE_DIRECT_LIST == "1" and not fs.access(file_direct_host) then
	local direct_domain, lookup_direct_domain = {}, {}
	local geosite_arg = ""
	local f = io.open(USER_RULES_PATH .. "/direct_host")
	if f then
		for line in f:lines() do
			if not line:find("#") and line:find("geosite:") then
				line = string.match(line, ":([^:]+)$")
				geosite_arg = geosite_arg .. (geosite_arg ~= "" and "," or "") .. line
			else
				line = api.get_std_domain(line)
				if line ~= "" and not line:find("#") and not line:find(":") then
					insert_unique(direct_domain, line, lookup_direct_domain)
				end
			end
		end
		f:close()
	end
	if #direct_domain > 0 then
		local f_out = io.open(file_direct_host, "w")
		for i = 1, #direct_domain do
			f_out:write(direct_domain[i] .. "\n")
		end
		f_out:close()
	end
	local success = true
	if USE_GEOVIEW == "1" and geosite_arg ~= "" then
		local code, out = get_geosite(geosite_arg, file_direct_host)
		if code == 0 then
			log("  - 解析[直连列表] Geosite 到域名白名单(whitelist)完成")
			sys.call("touch " .. file_direct_host .. "_geo")
		else
			log("  - 解析[直连列表] Geosite 到域名白名单(whitelist)失败！[" .. out .. "]")
			success = false
		end
	end
	if success and fs.access(file_direct_host) then
		sys.call("touch " .. file_direct_host .. "_ok")
	end
end
if USE_DIRECT_LIST == "1" and is_file_nonzero(file_direct_host) then
	if direct_geosite_flag then
		log("  - [直连列表] Geosite 使用缓存结果，跳过重复解析")
	end
	local domain_set_name = "psw-directlist"
	tmp_lines = {
		string.format("domain-set -name %s -file %s", domain_set_name, file_direct_host)
	}
	local sets = {
		"#4:" .. setflag .. "psw_white",
		"#6:" .. setflag .. "psw_white6"
	}
	local domain_rules_str = string.format('domain-rules /domain-set:%s/ -nameserver direct', domain_set_name) .. DIRECT_RULE_OPTIONS
	domain_rules_str = domain_rules_str .. " " .. set_type .. " " .. table.concat(sets, ",")
	table.insert(tmp_lines, domain_rules_str)
	insert_array_after(config_lines, tmp_lines, "#--7")
	log("  - 域名白名单(whitelist)使用分组：direct")
end

--代理（黑名单）列表
local file_proxy_host = CACHE_RULES_PATH .. "/proxy_host"
if not fs.access(file_proxy_host .. "_ok") then
	api.remove(file_proxy_host .. "*")
end
local proxy_geosite_flag = fs.access(file_proxy_host) and fs.access(file_proxy_host .. "_ok") and fs.access(file_proxy_host .. "_geo")
if USE_PROXY_LIST == "1" and not fs.access(file_proxy_host) then
	local proxy_domain, lookup_proxy_domain = {}, {}
	local geosite_arg = ""
	local f = io.open(USER_RULES_PATH .. "/proxy_host")
	if f then
		for line in f:lines() do
			if not line:find("#") and line:find("geosite:") then
				line = string.match(line, ":([^:]+)$")
				geosite_arg = geosite_arg .. (geosite_arg ~= "" and "," or "") .. line
			else
				line = api.get_std_domain(line)
				if line ~= "" and not line:find("#") and not line:find(":") then
					insert_unique(proxy_domain, line, lookup_proxy_domain)
				end
			end
		end
		f:close()
	end
	if #proxy_domain > 0 then
		local f_out = io.open(file_proxy_host, "w")
		for i = 1, #proxy_domain do
			f_out:write(proxy_domain[i] .. "\n")
		end
		f_out:close()
	end
	local success = true
	if USE_GEOVIEW == "1" and geosite_arg ~= "" then
		local code, out = get_geosite(geosite_arg, file_proxy_host)
		if code == 0 then
			log("  - 解析[代理列表] Geosite 到代理域名表(blacklist)完成")
			sys.call("touch " .. file_proxy_host .. "_geo")
		else
			log("  - 解析[代理列表] Geosite 到代理域名表(blacklist)失败！[" .. out .. "]")
			success = false
		end
	end
	if success and fs.access(file_proxy_host) then
		sys.call("touch " .. file_proxy_host .. "_ok")
	end
end
if USE_PROXY_LIST == "1" and is_file_nonzero(file_proxy_host) then
	if proxy_geosite_flag then
		log("  - [代理列表] Geosite 使用缓存结果，跳过重复解析")
	end
	local domain_set_name = "psw-proxylist"
	tmp_lines = {
		string.format("domain-set -name %s -file %s", domain_set_name, file_proxy_host)
	}
	local domain_rules_str = string.format('domain-rules /domain-set:%s/ -nameserver proxy', domain_set_name)
	domain_rules_str = domain_rules_str .. " -no-cache -speed-check-mode none -d no"
	local sets = {
		"#4:" .. setflag .. "psw_black"
	}
	if NO_PROXY_IPV6 == "1" then
		domain_rules_str = domain_rules_str .. " -address #6 " .. set_type .. " " .. table.concat(sets, ",")
	else
		table.insert(sets, "#6:" .. setflag .. "psw_black6")
		domain_rules_str = domain_rules_str .. " -address -6 " .. set_type .. " " .. table.concat(sets, ",")
	end
	table.insert(tmp_lines, domain_rules_str)
	insert_array_after(config_lines, tmp_lines, "#--6")
	log("  - 代理域名表(blacklist)使用分组：proxy")
end

--GFW列表
if USE_GFW_LIST == "1" and is_file_nonzero(RULES_PATH .. "/gfwlist") then
	local domain_set_name = "psw-gfwlist"
	tmp_lines = {
		string.format("domain-set -name %s -file %s", domain_set_name, RULES_PATH .. "/gfwlist")
	}
	local domain_rules_str = string.format('domain-rules /domain-set:%s/ -nameserver proxy', domain_set_name)
	domain_rules_str = domain_rules_str .. " -no-cache -speed-check-mode none -d no"
	local sets = {
		"#4:" .. setflag .. "psw_gfw"
	}
	if NO_PROXY_IPV6 == "1" then
		domain_rules_str = domain_rules_str .. " -address #6 " .. set_type .. " " .. table.concat(sets, ",")
	else
		table.insert(sets, "#6:" .. setflag .. "psw_gfw6")
		domain_rules_str = domain_rules_str .. " -address -6 " .. set_type .. " " .. table.concat(sets, ",")
	end
	table.insert(tmp_lines, domain_rules_str)
	insert_array_after(config_lines, tmp_lines, "#--5")
	log("  - 防火墙域名表(gfwlist)使用分组：proxy")
end

--中国列表
if CHN_LIST ~= "0" and is_file_nonzero(RULES_PATH .. "/chnlist") then
	local domain_set_name = "psw-chnlist"
	tmp_lines = {
		string.format("domain-set -name %s -file %s", domain_set_name, RULES_PATH .. "/chnlist")
	}

	if CHN_LIST == "direct" then
		local sets = {
			"#4:" .. setflag .. "psw_chn",
			"#6:" .. setflag .. "psw_chn6"
		}
		local domain_rules_str = string.format('domain-rules /domain-set:%s/ -nameserver direct', domain_set_name) .. DIRECT_RULE_OPTIONS
		domain_rules_str = domain_rules_str .. " " .. set_type .. " " .. table.concat(sets, ",")
		table.insert(tmp_lines, domain_rules_str)
		insert_array_after(config_lines, tmp_lines, "#--4")
		log("  - 中国域名表(chnlist)使用分组：direct")
	end

	--回中国模式
	if CHN_LIST == "proxy" then
		local domain_rules_str = string.format('domain-rules /domain-set:%s/ -nameserver proxy', domain_set_name)
		domain_rules_str = domain_rules_str .. " -no-cache -speed-check-mode none -d no"
		local sets = {
			"#4:" .. setflag .. "psw_chn"
		}
		if NO_PROXY_IPV6 == "1" then
			domain_rules_str = domain_rules_str .. " -address #6 " .. set_type .. " " .. table.concat(sets, ",")
		else
			table.insert(sets, "#6:" .. setflag .. "psw_chn6")
			domain_rules_str = domain_rules_str .. " -address -6 " .. set_type .. " " .. table.concat(sets, ",")
		end
		table.insert(tmp_lines, domain_rules_str)
		insert_array_after(config_lines, tmp_lines, "#--4")
		log("  - 中国域名表(chnlist)使用分组：proxy")
	end
end

--分流规则
if IS_SHUNT_NODE and not only_global then
	local direct_domain, lookup_direct_domain = {}, {}
	local proxy_domain, lookup_proxy_domain = {}, {}
	local black_domain, lookup_black_domain = {}, {}
	local CACHE_FLAG_PATH = CACHE_RULES_PATH .. "/" .. FLAG
	local shunt_direct_host = CACHE_FLAG_PATH .. "/shunt_direct_host"
	local shunt_proxy_host = CACHE_FLAG_PATH .. "/shunt_proxy_host"
	local shunt_black_host = CACHE_FLAG_PATH .. "/shunt_black_host"
	local geosite_direct_arg, geosite_proxy_arg, geosite_black_arg = "", "", ""
	local SHUNT_LIST = ""

	local t = api.uci_get_c(NODE)
	local default_node_id = t["default_node"] or "_direct"
	api.uci_foreach_c("shunt_rules", function(s)
		local _node_id = t[s[".name"]]
		if _node_id and t["shunt_group"] == s.group then
			if _node_id == "_default" then
				_node_id = default_node_id
			end

			local domain_list = s.domain_list or ""
			for line in string.gmatch(domain_list, "[^\r\n]+") do
				if line ~= "" and not line:find("#") and not line:find("regexp:") and not line:find("ext:") and not line:find("rule-set:") and not line:find("rs:") then
					if line:find("geosite:") then
						line = string.match(line, ":([^:]+)$")
						if _node_id == "_direct" then
							geosite_direct_arg = geosite_direct_arg .. (geosite_direct_arg ~= "" and "," or "") .. line
						elseif  _node_id == "_blackhole" then
							geosite_black_arg = geosite_black_arg .. (geosite_black_arg ~= "" and "," or "") .. line
						else
							geosite_proxy_arg = geosite_proxy_arg .. (geosite_proxy_arg ~= "" and "," or "") .. line
						end
					else
						if line:find("domain:") or line:find("full:") then
							line = string.match(line, ":([^:]+)$")
						end
						line = api.get_std_domain(line)
						if line ~= "" and not line:find("#") then
							if _node_id == "_direct" then
								insert_unique(direct_domain, line, lookup_direct_domain)
							elseif  _node_id == "_blackhole" then
								insert_unique(black_domain, line, lookup_black_domain)
							else
								insert_unique(proxy_domain, line, lookup_proxy_domain)
							end
						end
					end
				end
			end

			SHUNT_LIST = SHUNT_LIST .. domain_list .. (_node_id:sub(1, 1) == "_" and "not-node" or "node")

			if _node_id ~= "_direct" and _node_id ~= "_blackhole" then
				log(string.format("  - Sing-Box/Xray分流规则(%s)使用分组：proxy", s.remarks))
			end
		end
	end)

	local MD5_FILE = CACHE_FLAG_PATH .. "/md5.txt"
	local cache_md5 = ""
	local USE_CACHE = true
	if fs.access(MD5_FILE) then
		cache_md5 = fs.readfile(MD5_FILE)
	end
	local new_md5 = api.md5_string(SHUNT_LIST)
	if cache_md5 == "" or new_md5 == "" or cache_md5 ~= new_md5 then
		api.remove(CACHE_FLAG_PATH)
		sys.call("mkdir -p %s" % CACHE_FLAG_PATH)
		fs.writefile(MD5_FILE, new_md5)
		USE_CACHE = false
	end

	if not is_file_nonzero(shunt_direct_host) then
		if #direct_domain > 0 then
			local f_out = io.open(shunt_direct_host, "w")
			for i = 1, #direct_domain do
				f_out:write(direct_domain[i] .. "\n")
			end
			f_out:close()
		end
	end

	if not is_file_nonzero(shunt_proxy_host) then
		if #proxy_domain > 0 then
			local f_out = io.open(shunt_proxy_host, "w")
			for i = 1, #proxy_domain do
				f_out:write(proxy_domain[i] .. "\n")
			end
			f_out:close()
		end
	end

	if not is_file_nonzero(shunt_black_host) then
		if #black_domain > 0 then
			local f_out = io.open(shunt_black_host, "w")
			for i = 1, #black_domain do
				f_out:write(black_domain[i] .. "\n")
			end
			f_out:close()
		end
	end

	if not USE_CACHE and USE_GEOVIEW == "1" then
		local ok = true
		local function resolve(arg, dest)
		if arg == "" then return end
			local code, out = get_geosite(arg, dest)
			if code ~= 0 then
				ok = false
				log("  - 解析[分流节点] Geosite 失败！[" .. out .. "]")
			end
		end
		resolve(geosite_direct_arg, shunt_direct_host)
		resolve(geosite_proxy_arg,  shunt_proxy_host)
		resolve(geosite_black_arg,  shunt_black_host)
		if ok then
			log("  - 解析[分流节点] Geosite 完成")
		else
			api.remove(MD5_FILE)
		end
	end

	if USE_CACHE and USE_GEOVIEW == "1" and (geosite_direct_arg ~= "" or geosite_proxy_arg ~= "" or geosite_black_arg ~= "") then
		log("  - [分流节点] Geosite 使用缓存结果，跳过重复解析")
	end

	if is_file_nonzero(shunt_direct_host) then
		local domain_set_name = "psw-shunt-direct"
		tmp_lines = {
			string.format("domain-set -name %s -file %s", domain_set_name, shunt_direct_host)
		}
		local domain_rules_str = string.format('domain-rules /domain-set:%s/ -nameserver proxy', domain_set_name)
		domain_rules_str = domain_rules_str .. " -no-cache -speed-check-mode none -d no"
		local sets = {
			"#4:" .. setflag .. "psw_shunt",
			"#6:" .. setflag .. "psw_shunt6"
		}
		domain_rules_str = domain_rules_str .. " -address -6 " .. set_type .. " " .. table.concat(sets, ",")
		table.insert(tmp_lines, domain_rules_str)
		insert_array_after(config_lines, tmp_lines, "#--1")
	end

	if is_file_nonzero(shunt_proxy_host) then
		local domain_set_name = "psw-shunt-proxy"
		tmp_lines = {
			string.format("domain-set -name %s -file %s", domain_set_name, shunt_proxy_host)
		}
		local domain_rules_str = string.format('domain-rules /domain-set:%s/ -nameserver proxy', domain_set_name)
		domain_rules_str = domain_rules_str .. " -no-cache -speed-check-mode none -d no"
		local sets = {
			"#4:" .. setflag .. "psw_shunt",
			"#6:" .. setflag .. "psw_shunt6"
		}
		domain_rules_str = domain_rules_str .. " -address -6 " .. set_type .. " " .. table.concat(sets, ",")
		table.insert(tmp_lines, domain_rules_str)
		insert_array_after(config_lines, tmp_lines, "#--2")
	end

	if is_file_nonzero(shunt_black_host) then
		local domain_set_name = "psw-shunt-black"
		tmp_lines = {
			string.format("domain-set -name %s -file %s", domain_set_name, shunt_black_host)
		}
		local domain_rules_str = string.format('domain-rules /domain-set:%s/ -nameserver proxy', domain_set_name)
		domain_rules_str = domain_rules_str .. " -no-cache -speed-check-mode none -d no"
		local sets = {
			"#4:" .. setflag .. "psw_shunt",
			"#6:" .. setflag .. "psw_shunt6"
		}
		domain_rules_str = domain_rules_str .. " -address -6 " .. set_type .. " " .. table.concat(sets, ",")
		table.insert(tmp_lines, domain_rules_str)
		insert_array_after(config_lines, tmp_lines, "#--3")
	end
end


if #config_lines > 0 then
	local f_out = io.open(TMP_CONF_FILE, "w")
	for i = 1, #config_lines do
		line = config_lines[i]
		if line ~= "" and not line:find("^#--") then
			f_out:write(line .. "\n")
		end
	end
	f_out:close()
end

if DEFAULT_DNS_GROUP then
	log(string.format("  - 默认 DNS 分组：%s", DEFAULT_DNS_GROUP == AUTO_GROUP and "自动" or DEFAULT_DNS_GROUP))
end

if DNS_REDIRECT then
	log("  - DNS 重定向直接使用 SmartDNS，DHCP 租约由 SmartDNS 自动加载。")
else
	log("  - SmartDNS已作为Dnsmasq上游，如果你自行配置了错误的DNS流程，将会导致域名(直连/代理)分流失效！！！")
end
