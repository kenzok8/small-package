local http = luci.http
local nixio = require "nixio"

m = Map("easytier")
m.description = translate("A simple, secure, decentralized VPN solution for intranet penetration, implemented in Rust using the Tokio framework. "
        .. "Project URL: <a href=\"https://github.com/EasyTier/EasyTier\" target=\"_blank\">github.com/EasyTier/EasyTier</a>&nbsp;&nbsp;"
        .. "<a href=\"http://easytier.cn\" target=\"_blank\">Official Documentation</a>&nbsp;&nbsp;"
        .. "<a href=\"http://qm.qq.com/cgi-bin/qm/qr?_wv=1027&k=jhP2Z4UsEZ8wvfGPLrs0VwLKn_uz0Q_p&authKey=OGKSQLfg61YPCpVQuvx%2BxE7hUKBVBEVi9PljrDKbHlle6xqOXx8sOwPPTncMambK&noverify=0&group_code=949700262\" target=\"_blank\">QQ Group</a>&nbsp;&nbsp;")
  
m:section(SimpleSection).template  = "easytier/easytier_status"

-- easytier-core
s=m:section(TypedSection, "easytier", translate("EasyTier Configuration"))
s.addremove=false
s.anonymous=true
s:tab("general", translate("General Settings"))
s:tab("privacy", translate("Advanced Settings"))
s:tab("webconsole", translate("Self-hosted Web Server"))
s:tab("infos", translate("Connection Info"))
s:tab("upload", translate("Upload Program"))

switch = s:taboption("general",Flag, "enabled", translate("Enable"))
switch.rmempty = false

btncq = s:taboption("general", Button, "btncq", translate("Restart"))
btncq.inputtitle = translate("Restart")
btncq.description = translate("Quickly restart once without modifying any parameters")
btncq.inputstyle = "apply"
btncq:depends("enabled", "1")
btncq.write = function()
  luci.sys.call("rm -rf /tmp/easytier*.tag /tmp/easytier*.newtag >/dev/null 2>&1 &") -- 执行删除版本号信息
  luci.sys.call("/etc/init.d/easytier restart >/dev/null 2>&1 &")  -- 执行重启命令
end

etcmd = s:taboption("general", ListValue, "etcmd", translate("Startup Method"),
        translate("Official Web Console: <a href=\"https://easytier.cn/web\" target=\"_blank\">https://easytier.cn/web</a><br>"
                .. "Official Configuration File Generator: <a href=\"https://easytier.cn/web/index.html#/config_generator\" target=\"_blank\">"
                .. "https://easytier.cn/web/index.html#/config_generator</a><br>Please note to set the RPC port to 15888"))
etcmd.default = "etcmd"
etcmd:value("etcmd", translate("Default"))
etcmd:value("config", translate("Configuration File"))
etcmd:value("web", translate("Web Configuration"))

et_config = s:taboption("general", TextValue, "et_config", translate("Configuration File"),
        translate("The configuration file is located at /etc/easytier/config.toml<br>"
                .. "The command-line startup parameters and the parameters in this configuration file are not synchronized<br>"
                .. "Make sure to specify the TUN interface name and port to enable automatic firewall allowance"))
et_config.rows = 18
et_config.wrap = "off"
et_config:depends("etcmd", "config")

et_config.cfgvalue = function(self, section)
    return nixio.fs.readfile("/etc/easytier/config.toml") or ""
end
et_config.write = function(self, section, value)
    local dir = "/etc/easytier/"
    local file = dir .. "config.toml"
    -- 检查目录是否存在，如果不存在则创建
    if not nixio.fs.access(dir) then
        nixio.fs.mkdir(dir)
    end
    nixio.fs.writefile(file, value:gsub("\r\n", "\n"))
end

web_config = s:taboption("general", Value, "web_config", translate("Web Server Address"),
        translate("Web configuration server address. (-w parameter)<br>"
                .. "For a self-hosted Web server, use the format: udp://server_address:22020/username<br>"
                .. "For the official Web server, use the format: username<br>"
                .. "Official Web Console: <a href='https://easytier.cn/web'>easytier.cn/web</a>"))
web_config.placeholder = "admin"
web_config:depends("etcmd", "web")

network_name = s:taboption("general", Value, "network_name", translate("Network Name"),
        translate("The network name used to identify this VPN network (--network-name parameter)"))
network_name.password = true
network_name.placeholder = "easytier-name"
network_name.maxlength = 64
network_name.validate = function(self, value)
    if value and value ~= "" and value:match("[^%w%-_]") then
        return nil, translate("Only alphanumeric characters, hyphens and underscores allowed")
    end
    return value
end
network_name:depends("etcmd", "etcmd")

network_secret = s:taboption("general", Value, "network_secret", translate("Network Secret"),
        translate("Network secret used to verify whether this node belongs to the VPN network (--network-secret parameter)"))
network_secret.password = true
network_secret.placeholder = "easytier-password"
network_secret.maxlength = 128
network_secret:depends("etcmd", "etcmd")

ip_dhcp = s:taboption("general", Flag, "ip_dhcp", translate("Enable DHCP"),
        translate("IP address will be automatically determined and assigned by EasyTier, starting from 10.0.0.1 by default. "
                .. "Warning: When using DHCP, if an IP conflict occurs in the network, the IP will be automatically changed. (-d parameter)"))
ip_dhcp:depends("etcmd", "etcmd")

ipaddr = s:taboption("general", Value, "ipaddr", translate("Interface IP Address"),
        translate("The IPv4 address of this VPN node. If left empty, this node will only forward packets and will not "
                .. "create a TUN device. (-i parameter)"))
ipaddr.datatype = "ip4addr"
ipaddr.placeholder = "10.0.0.1"
ipaddr:depends("etcmd", "etcmd")

ip6addr = s:taboption("general", Value, "ip6addr", translate("Interface IPV6 Address"),
        translate("ipv6 address of this vpn node, can be used together with ipv4 for dual-stack operation"
                .. "(--ipv6 parameter)"))
ip6addr.datatype = "ip6addr"
ip6addr.placeholder = "2001:db8::1"
ip6addr:depends("etcmd", "etcmd")

peeradd = s:taboption("general", DynamicList, "peeradd", translate("Peer Nodes"),
        translate("Initial connected peer nodes (-p parameter)<br>"
                .. "Public server status check: <a href='https://uptime.easytier.cn' target='_blank'>"
                .. "Click here to check</a>"))
peeradd.placeholder = "tcp://public.easytier.top:11010"
peeradd:value("tcp://public.easytier.top:11010", translate("Official Server - tcp://public.easytier.top:11010"))
peeradd:depends("etcmd", "etcmd")

--[=[
external_node = s:taboption("general", Value, "external_node", translate("Shared Node Address"),
        translate("Use a public shared node to discover peer nodes, same function as the parameter above (-e parameter)"))
external_node.default = ""
external_node.placeholder = "tcp://public.easytier.top:11010"
external_node:value("tcp://public.easytier.top:11010", translate("Official Server - tcp://public.easytier.top:11010"))
external_node:depends("etcmd", "etcmd")
]=]

proxy_network = s:taboption("general", DynamicList, "proxy_network", translate("Subnet Proxy"),
        translate("Export the local network to other peers in the VPN, allowing access to other devices in the current LAN (-n parameter)"))
proxy_network:depends("etcmd", "etcmd")

mapped_listeners = s:taboption("privacy", DynamicList, "mapped_listeners", translate("Public Addresses of Specified Listeners"),
        translate("Manually specify the public IP address of this machine, so other nodes can connect to this node using "
                .. "that address (domain names not supported).<br>For example: tcp://123.123.123.123:11223, multiple entries "
                .. "can be specified. (--mapped-listeners parameter)"))
mapped_listeners:depends("listenermode", "ON")

rpc_portal = s:taboption("privacy", Value, "rpc_portal", translate("Portal Address Port"),
        translate("RPC portal address used for management. 0 means a random port, 12345 means listening on port 12345 on localhost, "
                .. "0.0.0.0:12345 means listening on port 12345 on all interfaces.<br>The default is 0; it is recommended to "
                .. "use 15888 to avoid failure in obtaining status information (-r parameter)"))
rpc_portal.placeholder = "15888"
rpc_portal.default = "15888"
rpc_portal.datatype = "range(1,65535)"
rpc_portal:depends("etcmd", "etcmd")

rpc_portal_whitelist = s:taboption("privacy", Value, "rpc_portal_whitelist", translate("RPC Access Whitelist"),
        translate("rpc portal whitelist, only allow these addresses to access rpc portal (--rpc-portal-whitelist parameter)"))
rpc_portal_whitelist.placeholder = "127.0.0.1/32,127.0.0.0/8,::1/128"
rpc_portal_whitelist:depends("etcmd", "etcmd")

listenermode = s:taboption("general", ListValue, "listenermode", translate("Listener Port"),
        translate("OFF: Do not listen on any port, only connect to peer nodes (--no-listener parameter)<br>"
                .. "If used purely as a client (not as a server), you can choose not to listen on a port"))
listenermode:value("ON", translate("Listen"))
listenermode:value("OFF", translate("Do Not Listen"))
listenermode.default = "ON"
listenermode:depends("etcmd", "etcmd")

tcp_port = s:taboption("general", Value, "tcp_port", translate("TCP/UDP Port"),
        translate("TCP/UDP protocol port number: 11010 means TCP/UDP will listen on port 11010.<br>"
                .. "If this is the Web configuration in the config file, please fill in the same listening port for firewall allowance."))
tcp_port.datatype = "range(1,65535)"
tcp_port.default = "11010"
tcp_port:depends("listenermode", "ON")
tcp_port:depends("etcmd", "web")

ws_port = s:taboption("general", Value, "ws_port", translate("WS Port"),
        translate("WS protocol port number: 11011 means WS will listen on port 11011.<br>"
                .. "If this is the Web configuration in the config file, please fill in the same listening port for firewall allowance."))
ws_port.datatype = "range(1,65535)"
ws_port.default = "11011"
ws_port:depends("listenermode", "ON")
ws_port:depends("etcmd", "web")

wss_port = s:taboption("general", Value, "wss_port", translate("WSS Port"),
        translate("WSS protocol port number: 11012 means WSS will listen on port 11012.<br>"
                .. "If this is the Web configuration in the config file, please fill in the same listening port for firewall allowance."))
wss_port.datatype = "range(1,65535)"
wss_port.default = "11012"
wss_port:depends("listenermode", "ON")
wss_port:depends("etcmd", "web")

wg_port = s:taboption("general", Value, "wg_port", translate("WG Port"),
        translate("WireGuard protocol port number: 11011 means WG will listen on port 11011.<br>"
                .. "If this is the Web configuration in the config file, please fill in the same listening port for firewall allowance."))
wg_port.datatype = "range(1,65535)"
wg_port.placeholder = "11011"
wg_port:depends("listenermode", "ON")
wg_port:depends("etcmd", "web")

quic_port = s:taboption("general", Value, "quic_port", translate("QUIC Port"),
        translate("If this is the Web configuration in the config file, please fill in the same listening port for firewall allowance."))
quic_port.datatype = "range(1,65535)"
quic_port:depends("listenermode", "ON")
quic_port:depends("etcmd", "web")

local model = nixio.fs.readfile("/proc/device-tree/model") or ""
local hostname = nixio.fs.readfile("/proc/sys/kernel/hostname") or ""
model = model:gsub("\n", "")
hostname = hostname:gsub("\n", "")
local device_name_default = (model ~= "" and model) or (hostname ~= "" and hostname) or "OpenWrt"
device_name_default = device_name_default:gsub(" ", "_")
hostname_opt = s:taboption("general", Value, "desvice_name", translate("Hostname"),
        translate("The hostname used to identify this device (--hostname parameter)"))
hostname_opt.placeholder = device_name_default
hostname_opt.default = device_name_default
hostname_opt:depends("etcmd", "etcmd")
hostname_opt:depends("etcmd", "web")

uuid = s:taboption("general", Value, "uuid", translate("UUID"),
        translate("Unique identifier used to recognize this device when connecting to the web console, for issuing configuration files"))
uuid.rows = 1
uuid.wrap = "off"
uuid:depends("etcmd", "web")
uuid.cfgvalue = function(self, section)
    return nixio.fs.readfile("/etc/easytier/et_machine_id") or ""
end
uuid.write = function(self, section, value)
    nixio.fs.writefile("/etc/easytier/et_machine_id", value:gsub("\r\n", "\n"))
end

instance_name = s:taboption("privacy", Value, "instance_name", translate("Instance Name"),
        translate("Used to identify the VPN node instance on the same machine. (-m parameter)"))
instance_name.placeholder = "default"
instance_name:depends("etcmd", "etcmd")

vpn_portal = s:taboption("privacy", Value, "vpn_portal", translate("VPN Portal URL"),
        translate("Defines the URL of the VPN portal, allowing other VPN clients to connect.<br>"
                .. "Example: wg://0.0.0.0:11011/10.14.14.0/24 means the VPN portal is a WireGuard server listening on vpn."
                .. "example.com:11010, and the VPN clients are in the 10.14.14.0/24 network (--vpn-portal parameter)"))
vpn_portal.placeholder = "wg://0.0.0.0:11011/10.14.14.0/24"
vpn_portal:depends("etcmd", "etcmd")

mtu = s:taboption("privacy", Value, "mtu", translate("MTU"),
        translate("MTU for the TUN device, default is 1380 when unencrypted, and 1360 when encrypted"))
mtu.datatype = "range(1,1500)"
mtu.placeholder = "1300"
mtu:depends("etcmd", "etcmd")

default_protocol = s:taboption("privacy", ListValue, "default_protocol", translate("Default Protocol"),
        translate("The default protocol used when connecting to peer nodes (--default-protocol parameter)"))
default_protocol:value("-",translate("default"))
default_protocol:value("tcp")
default_protocol:value("udp")
default_protocol:value("ws")
default_protocol:value("wss")
default_protocol:depends("etcmd", "etcmd")

tunname = s:taboption("privacy", Value, "tunname", translate("Virtual Network Interface Name"),
        translate("Custom name for the virtual TUN interface (--dev-name parameter)<br>"
                .. "If using web configuration, please use the same virtual network interface name as in the web config for firewall allowance"))
tunname.placeholder = "tun0"
tunname:depends("etcmd", "etcmd")
tunname:depends("etcmd", "web")

disable_encryption = s:taboption("privacy", Flag, "disable_encryption", translate("Disable Encryption"),
        translate("Disable encryption for communication with peer nodes. "
                .. "If encryption is disabled, all other nodes must also have encryption disabled (-u parameter)"))
disable_encryption:depends("etcmd", "etcmd")

encryption_algorithm = s:taboption("privacy", ListValue, "encryption_algorithm", translate("Encryption Algorithm"),
        translate("encryption algorithm to use, supported: xor, chacha20, aes-gcm, aes-256-gcm, openssl-aes-gcm, openssl-chacha20, openssl-aes-256-gcm. default (aes-gcm) (--encryption-algorithm parameter)"))
encryption_algorithm.default = "aes-gcm"
encryption_algorithm:value("xor",translate("xor"))
encryption_algorithm:value("chacha20",translate("chacha20"))
encryption_algorithm:value("aes-gcm",translate("aes-gcm"))
encryption_algorithm:value("aes-256-gcm",translate("aes-256-gcm"))
encryption_algorithm:value("openssl-aes-gcm",translate("openssl-aes-gcm"))
encryption_algorithm:value("openssl-chacha20",translate("openssl-chacha20"))
encryption_algorithm:value("openssl-aes-256-gcm",translate("openssl-aes-256-gcm"))
encryption_algorithm:depends("etcmd", "etcmd")

multi_thread = s:taboption("privacy", Flag, "multi_thread", translate("Enable Multithreading"),
        translate("Enable multithreaded operation; single-threaded by default (--multi-thread parameter)"))
multi_thread:depends("etcmd", "etcmd")

multi_thread_count = s:taboption("privacy", Value, "multi_thread_count", translate("Number of Threads"),
        translate("the number of threads to use, default is 2, only effective when multi-thread is enabled, must be greater than 2 (--multi-thread-count parameter)"))
multi_thread_count.placeholder = "2"
multi_thread_count:depends("etcmd", "etcmd")

disable_ipv6 = s:taboption("privacy", Flag, "disable_ipv6", translate("Disable IPv6"),
        translate("Do not use IPv6 (--disable-ipv6 parameter)"))
disable_ipv6:depends("etcmd", "etcmd")

latency_first = s:taboption("privacy", Flag, "latency_first", translate("Enable Latency First"),
        translate("Latency-first mode: attempts to forward traffic via the lowest latency path. "
                .. "By default, the shortest path is used (--latency-first parameter)"))
latency_first:depends("etcmd", "etcmd")

comp = s:taboption("privacy", ListValue, "comp", translate("Compression Algorithm"),
        translate("Compression algorithm to use (--compression parameter)"))
comp.default = "none"
comp:value("none",translate("default"))
comp:value("zstd",translate("zstd"))
comp:depends("etcmd", "etcmd")

exit_node = s:taboption("privacy", Flag, "exit_node", translate("Enable Exit Node"),
        translate("Allow this node to act as an exit node (--enable-exit-node parameter)"))
exit_node:depends("etcmd", "etcmd")

exit_nodes = s:taboption("privacy", DynamicList, "exit_nodes", translate("Exit Node Addresses"),
        translate("Exit nodes to forward all traffic through. These are virtual IPv4 addresses. "
                .. "Priority is determined by the order in the list (--exit-nodes parameter)"))
exit_nodes:depends("etcmd", "etcmd")

smoltcp = s:taboption("privacy", Flag, "smoltcp", translate("Use Userspace TCP/IP Stack"),
        translate("Enable smoltcp stack for subnet proxying (--use-smoltcp parameter)"))
smoltcp:depends("etcmd", "etcmd")

no_tun = s:taboption("privacy", Flag, "no_tun", translate("No TUN Mode"),
        translate("Do not create a TUN device; subnet proxying can still be used to access nodes (--no-tun parameter)"))
no_tun:depends("etcmd", "etcmd")

proxy_forward = s:taboption("privacy", Flag, "proxy_forward", translate("Disable Built-in NAT"),
        translate("Use system kernel to forward subnet proxy packets, disabling built-in NAT (--proxy-forward-by-system parameter)"))
proxy_forward:depends("etcmd", "etcmd")

manual_routes = s:taboption("privacy", DynamicList, "manual_routes", translate("Route CIDR"),
        translate("Manually assign route CIDRs. This disables subnet proxying and WireGuard routes propagated from peer nodes "
                .. "(--manual-routes parameter)"))
manual_routes.placeholder = "192.168.0.0/16"
manual_routes:depends("etcmd", "etcmd")

relay_network = s:taboption("privacy", Flag, "relay_network", translate("Forward Whitelisted Network Traffic"),
        translate("Only forward traffic for whitelisted networks. By default, all networks are allowed"))
relay_network:depends("etcmd", "etcmd")

whitelist = s:taboption("privacy", DynamicList, "whitelist", translate("Whitelisted Networks"),
        translate("Only forward traffic for whitelisted networks. Input is a wildcard string, "
                .. "e.g., '*' (all networks), 'def*' (networks prefixed with 'def')<br>Multiple networks can be specified. "
                .. "If empty, forwarding is disabled (--relay-network-whitelist parameter)"))
whitelist:depends("relay_network", "1")

socks_port = s:taboption("privacy", Value, "socks_port", translate("SOCKS5 Port"),
        translate("Enable a SOCKS5 server to allow SOCKS5 clients to access the virtual network. "
                .. "Leave blank to disable (--socks5 parameter)"))
socks_port.datatype = "range(1,65535)"
socks_port.placeholder = "1080"
socks_port:depends("etcmd", "etcmd")

disable_p2p = s:taboption("privacy", Flag, "disable_p2p", translate("Disable P2P"),
        translate("Disable P2P communication; only use nodes specified by -p to forward packets (--disable-p2p parameter)"))
disable_p2p:depends("etcmd", "etcmd")

p2p_only = s:taboption("privacy", Flag, "p2p_only", translate("P2P only"),
        translate("only communicate with peers that already establish p2p connection. (--p2p-only parameter)"))
p2p_only:depends("etcmd", "etcmd")

disable_udp = s:taboption("privacy", Flag, "disable_udp", translate("Disable UDP"),
        translate("Disable UDP hole punching (--disable-udp-hole-punching parameter)"))
disable_udp:depends("etcmd", "etcmd")

udp_white_port = s:taboption("privacy", Value, "udp_white_port", translate("UDP whitelist"),
        translate("udp port whitelist. Supports single ports (53) and ranges (5000-6000). (--udp-whitelist parameter)"))
udp_white_port:depends("etcmd", "etcmd")

disable_tcp = s:taboption("privacy", Flag, "disable_tcp", translate("Disable TCP"),
        translate("Disable TCP hole punching (--disable-tcp-hole-punching parameter)"))
disable_tcp:depends("etcmd", "etcmd")

tcp_white_port = s:taboption("privacy", Value, "tcp_white_port", translate("TCP whitelist"),
        translate("tcp port whitelist. Supports single ports (53) and ranges (5000-6000). (--tcp-whitelist parameter)"))
tcp_white_port:depends("etcmd", "etcmd")

disable_sym = s:taboption("privacy", Flag, "disable_sym", translate("Disable sym"),
        translate("if true, disable udp nat hole punching for symmetric nat (NAT4), which is based on birthday attack and may be blocked by ISP. (--disable-sym-hole-punching parameter)"))
disable_sym:depends("etcmd", "etcmd")

relay_all = s:taboption("privacy", Flag, "relay_all", translate("Allow Forwarding"),
        translate("Forward RPC packets from all peer nodes, even if they are not in the relay network whitelist.<br>"
                .. "This can help peer nodes in non-whitelisted networks establish P2P connections. (--relay-all-peer-rpc parameter)"))
relay_all:depends("etcmd", "etcmd")

bind_device = s:taboption("privacy", Flag, "bind_device", translate("Bind to Physical NIC Only"),
        translate("Bind the connector socket to the physical device to avoid routing issues.<br>"
                .. "For example, if the subnet proxy segment conflicts with a peer node, "
                .. "binding the physical NIC enables normal communication. (--bind-device parameter)"))
bind_device.default = "0"
bind_device:depends("etcmd", "etcmd")

kcp_proxy = s:taboption("privacy", Flag, "kcp_proxy", translate("Enable KCP Proxy"),
        translate("Convert TCP traffic to KCP traffic to reduce latency and improve speed.<br>"
                .. "All nodes in the virtual network must be using EasyTier version v2.2.0 or higher for this feature. "
                .. "(--enable-kcp-proxy parameter)"))
kcp_proxy:depends("etcmd", "etcmd")

kcp_input = s:taboption("privacy", Flag, "kcp_input", translate("Disable KCP Input"),
        translate("Disallow other nodes from using KCP proxy TCP streams to this node.<br>"
                .. "KCP proxy-enabled nodes accessing this node will still use the original method. (--disable-kcp-input parameter)"))
kcp_input:depends("etcmd", "etcmd")

disable_relay_kcp = s:taboption("privacy", Flag, "disable_relay_kcp", translate("Disable relay kcp"),
        translate("If true, disable relay kcp packets. avoid consuming too many bandwidth. default is false. (--disable-relay-kcp parameter)"))
disable_relay_kcp:depends("etcmd", "etcmd")

relay_kcp = s:taboption("privacy", Flag, "relay_kcp", translate("Relay foreign network kcp"),
        translate("If true, allow relay kcp packets from foreign network. default is false (not forward foreign network kcp packets). (--enable-relay-foreign-network-kcp parameter)"))
relay_kcp:depends("etcmd", "etcmd")

quic_proxy = s:taboption("privacy", Flag, "quic_proxy", translate("Enable QUIC Proxy"),
        translate("Proxy tcp streams with QUIC, improving the latency and throughput on the network with udp packet loss.<br>"
                .. "All nodes in the virtual network must be using EasyTier version v2.3.2 or higher for this feature. "
                .. "(--enable-quic-proxy parameter)"))
quic_proxy:depends("etcmd", "etcmd")

quic_input = s:taboption("privacy", Flag, "quic_input", translate("Disable QUIC Input"),
    translate("Do not allow other nodes to use QUIC to proxy tcp streams to this node.") ..
    translate("When a node with QUIC proxy enabled accesses this node, the original tcp connection is preserved.") ..
    translate("<br>QUIC proxy-enabled nodes accessing this node will still use the original method. (--disable-quic-input parameter)"))
quic_input:depends("etcmd", "etcmd")

port_forward = s:taboption("privacy", DynamicList, "port_forward", translate("Port Forwarding"),
        translate("Forward a local port to a remote port within the virtual network.<br>"
                .. "Example: udp://0.0.0.0:12345/10.126.126.1:23456 means forwarding local UDP port 12345 to 10.126.126.1:23456 "
                .. "in the virtual network.<br>Multiple entries can be specified. (--port-forward parameter)"))
port_forward:depends("etcmd", "etcmd")

accept_dns = s:taboption("privacy", Flag, "accept_dns", translate("Enable Magic DNS"),
        translate("With Magic DNS, you can access other nodes using domain names, e.g., <hostname>.et.net. "
                .. "Magic DNS will modify your system DNS settings, please enable with caution. (--accept-dns parameter)"))
accept_dns:depends("etcmd", "etcmd")

private_mode = s:taboption("privacy", Flag, "private_mode", translate("Enable Private Mode"),
        translate("When enabled, nodes with a different network name and password are not allowed to handshake or "
                .. "relay via this node. (--private-mode parameter)"))
private_mode:depends("etcmd", "etcmd")

foreign_relay_bps_limit = s:taboption("privacy", Value, "foreign_relay_bps_limit", translate("Forwarding Rate"),
        translate("the maximum bps limit for foreign network relay, default is no limit. unit: BPS (bytes per second). "
                .. "(--foreign-relay-bps-limit parameter)"))
foreign_relay_bps_limit:depends("etcmd", "etcmd")

extra_args = s:taboption("privacy", Value, "extra_args", translate("Extra Parameters"),
    translate("Additional command-line arguments passed to the backend process"))
extra_args.placeholder = "--tcp-whitelist 80 --udp-whitelist 53"
extra_args:depends("etcmd", "etcmd")

log = s:taboption("general", ListValue, "log", translate("Program Log"),
        translate("Runtime log is located at /tmp/easytier.log. View it in the log section above.<br>"
                .. "Levels: Error < Warning < Info < Debug < Trace"))
log.default = "off"
log:value("off", translate("Off"))
log:value("error", translate("Error"))
log:value("warn", translate("Warning"))
log:value("info", translate("Info"))
log:value("debug", translate("Debug"))
log:value("trace", translate("Trace"))

-- Network Configuration Options
auto_config_interface = s:taboption("privacy", Flag, "auto_config_interface", translate("Auto Configure Interface"),
        translate("Automatically create and configure the EasyTier network interface"))
auto_config_interface.default = "1"

interface_netmask = s:taboption("privacy", Value, "interface_netmask", translate("Interface Netmask"),
        translate("Subnet mask for the EasyTier interface (default: 255.0.0.0)"))
interface_netmask.placeholder = "255.0.0.0"
interface_netmask.default = "255.0.0.0"
interface_netmask.datatype = "ip4addr"
interface_netmask:depends("auto_config_interface", "1")

auto_config_firewall = s:taboption("privacy", Flag, "auto_config_firewall", translate("Auto Configure Firewall"),
        translate("Automatically add and manage firewall rules"))
auto_config_firewall.default = "1"

et_forward = s:taboption("privacy", MultiValue, "et_forward", translate("Access Control"),
        translate("Set traffic permission rules between different network zones"))
et_forward:value("etfwlan", translate("Allow traffic from EasyTier virtual network to LAN"))
et_forward:value("etfwwan", translate("Allow traffic from EasyTier virtual network to WAN"))
et_forward:value("lanfwet", translate("Allow traffic from LAN to EasyTier virtual network"))
et_forward:value("wanfwet", translate("Allow traffic from WAN to EasyTier virtual network"))
et_forward.default = "etfwlan etfwwan lanfwet"
et_forward.rmempty = true

check = s:taboption("privacy", Flag, "check", translate("Connectivity Check"),
        translate("Enable connectivity check to specify remote device IPs; if all specified IPs fail to ping, "
                .. "the EasyTier program will restart."))

checkip = s:taboption("privacy", DynamicList, "checkip", translate("Check IPs"),
        translate("Make sure the remote device IPs entered here are correct and reachable; "
                .. "incorrect entries may cause ping failures and repeated program restarts."))
checkip.rmempty = true
checkip.datatype = "ip4addr"
checkip:depends("check", "1")

checktime = s:taboption("privacy", ListValue, "checktime", translate("Interval Time (minutes)"),
        translate("Interval time for checking connectivity; how often the specified IPs are pinged."))
for s = 1, 60 do
    checktime:value(s)
end
checktime:depends("check", "1")

local process_status = luci.sys.exec("ps | grep easytier-core| grep -v grep")

-- 连接信息 tab - 使用 HTM 模板展示
conninfo = s:taboption("infos", DummyValue, "_conninfo")
conninfo.template = "easytier/easytier_conninfo"
conninfo.rawhtml = true

btnrm = s:taboption("infos", Button, "btnrm")
btnrm.inputtitle = translate("Check for Updates")
btnrm.description = translate("Click the button to start checking for updates and refresh the version display in the status bar above")
btnrm.inputstyle = "apply"
btnrm.write = function()
  os.execute("rm -rf /tmp/easytier*.tag /tmp/easytier*.newtag /tmp/easytier-core_*")
end


easytierbin = s:taboption("upload", Value, "easytierbin", translate("easytier-core Binary Path"),
        translate("Customize the storage path for easytier-core. Make sure to provide the full path and filename. "
                .. "If the specified path has insufficient space, it will automatically move to /tmp/easytier-core"))
easytierbin.placeholder = "/usr/bin/easytier-core"
easytierbin.default = "/usr/bin/easytier-core"

webbin = s:taboption("upload", Value, "webbin", translate("easytier-web Binary Path"),
        translate("Customize the storage path for easytier-web. Make sure to provide the full path and filename, "
                .. "then upload the installer"))
webbin.placeholder = "/usr/bin/easytier-web"
webbin.default = "/usr/bin/easytier-web"

github_proxys = s:taboption("upload", Value, "github_proxys", translate("GitHub Proxy URLs"),
        translate("Space-separated list of GitHub proxy URLs for downloading binaries. "
                .. "Leave empty to use default proxies."))
github_proxys.placeholder = "https://ghproxy.net/ https://gh-proxy.com/"

fallback_version = s:taboption("upload", Value, "fallback_version", translate("Fallback Version"),
        translate("Fallback version to use when unable to fetch the latest version from GitHub."))
fallback_version.placeholder = "v2.5.0"
fallback_version.default = "v2.5.0"

local upload = s:taboption("upload", FileUpload, "upload_file")
upload.optional = true
upload.default = ""
upload.template = "easytier/other_upload"
upload.description = translate("You can directly upload the binary programs easytier-core and easytier-cli, or a compressed .zip archive. "
        .. "Uploading a new version will automatically overwrite the old one. Download link: "
        .. "<a href='https://github.com/EasyTier/EasyTier/releases' target='_blank'>github.com/EasyTier/EasyTier</a><br>"
        .. "The uploaded files will be saved in the /tmp folder. If a custom program path is specified, "
        .. "the program will be automatically moved to that path when started.<br>")
local um = s:taboption("upload",DummyValue, "", nil)
um.template = "easytier/other_dvalue"

local dir, fd, chunk
dir = "/tmp/"
nixio.fs.mkdir(dir)
http.setfilehandler(
    function(meta, chunk, eof)
        if not fd then
            if not meta then return end

            if meta and chunk then fd = nixio.open(dir .. meta.file, "w") end

            if not fd then
                um.value = translate("Error: Upload failed!")
                return
            end
        end

        if chunk and fd then
            fd:write(chunk)
        end

        if eof and fd then
            fd:close()
            fd = nil
            um.value = translate("File has been uploaded to") .. ' "/tmp/' .. meta.file .. '"'

            if string.sub(meta.file, -4) == ".zip" then
                local file_path = dir .. meta.file
                os.execute("unzip -q " .. file_path .. " -d " .. dir)
                local extracted_dir = "/tmp/easytier-linux-*/"
                os.execute("mv " .. extracted_dir .. "easytier-cli /tmp/easytier-cli")
                os.execute("mv " .. extracted_dir .. "easytier-core /tmp/easytier-core")
                os.execute("mv " .. extracted_dir .. "easytier-web-embed /tmp/easytier-web-embed")
                if nixio.fs.access("/tmp/easytier-cli") then
                    um.value = um.value .. "\n" .. translate("- Program /tmp/easytier-cli uploaded successfully, restart the plugin to take effect")
                end
                if nixio.fs.access("/tmp/easytier-core") then
                    um.value = um.value .. "\n" .. translate("- Program /tmp/easytier-core uploaded successfully, restart the plugin to take effect")
                end
                if nixio.fs.access("/tmp/easytier-web-embed") then
                    um.value = um.value .. "\n" .. translate("- Program /tmp/easytier-web uploaded successfully, restart the plugin to take effect")
                end
            end

	        if string.sub(meta.file, -7) == ".tar.gz" then
                local file_path = dir .. meta.file
                os.execute("tar -xzf " .. file_path .. " -C " .. dir)
		        local extracted_dir = "/tmp/easytier-linux-*/"
                os.execute("mv " .. extracted_dir .. "easytier-cli /tmp/easytier-cli")
                os.execute("mv " .. extracted_dir .. "easytier-core /tmp/easytier-core")
		        os.execute("mv " .. extracted_dir .. "easytier-web-embed /tmp/easytier-web-embed")
                if nixio.fs.access("/tmp/easytier-cli") then
                    um.value = um.value .. "\n" .. translate("- Program /tmp/easytier-cli uploaded successfully, restart the plugin to take effect")
                end
                if nixio.fs.access("/tmp/easytier-core") then
                    um.value = um.value .. "\n" .. translate("- Program /tmp/easytier-core uploaded successfully, restart the plugin to take effect")
                end
                if nixio.fs.access("/tmp/easytier-web-embed") then
                    um.value = um.value .. "\n" .. translate("- Program /tmp/easytier-web uploaded successfully, restart the plugin to take effect")
                end
            end

            os.execute("chmod +x /tmp/easytier-core")
            os.execute("chmod +x /tmp/easytier-cli")
            os.execute("chmod +x /tmp/easytier-web-embed")
		   
        end
    end
)
if luci.http.formvalue("upload") then
    local f = luci.http.formvalue("ulfile")
end

-- Self-hosted Web Console tab options

web_enabled = s:taboption("webconsole", Flag, "web_enabled", translate("Enable"))
web_enabled.rmempty = false

web_btncq = s:taboption("webconsole", Button, "web_btncq", translate("Restart"))
web_btncq.inputtitle = translate("Restart")
web_btncq.description = translate("Quickly restart once without modifying any parameters")
web_btncq.inputstyle = "apply"
web_btncq.write = function()
  luci.sys.call("/etc/init.d/easytier restart >/dev/null 2>&1 &")
end

web_db_path = s:taboption("webconsole", Value, "web_db_path", translate("Database File Path"),
        translate("Path to the sqlite3 database file used to store all data. (-d parameter)"))
web_db_path.default = "/etc/easytier/et.db"

web_protocol = s:taboption("webconsole", ListValue, "web_protocol", translate("Listening Protocol"),
        translate("Configure the server's listening protocol for easytier-core to connect. (-p parameter)"))
web_protocol.default = "udp"
web_protocol:value("udp",translate("UDP"))
web_protocol:value("tcp",translate("TCP"))
web_protocol:value("ws",translate("WS"))

web_port = s:taboption("webconsole", Value, "web_port", translate("Server Port"),
        translate("Configure the server's listening port for easytier-core to connect. (-c parameter)"))
web_port.datatype = "range(1,65535)"
web_port.placeholder = "22020"
web_port.default = "22020"

web_fw_web = s:taboption("webconsole", Flag, "web_fw_web", translate("WAN access to WEB"),
        translate("Automatically add firewall rules to allow WAN access to this WEB console"))

web_api_port = s:taboption("webconsole", Value, "web_api_port", translate("API Port"),
        translate("Listening port of the RESTful server, used as ApiHost by the web frontend. (-a parameter)"))
web_api_port.datatype = "range(1,65535)"
web_api_port.placeholder = "11211"
web_api_port.default = "11211"

web_html_port = s:taboption("webconsole", Value, "web_html_port", translate("Web Interface Port"),
        translate("Frontend listening port for the web dashboard server. Leave empty to disable. (-l parameter)"))
web_html_port.datatype = "range(1,65535)"
web_html_port.default = "11211"

web_fw_api = s:taboption("webconsole", Flag, "web_fw_api", translate("WAN access to API"),
        translate("Automatically add firewall rules to allow WAN access to the API control page"))

web_api_host = s:taboption("webconsole", Value, "web_api_host", translate("Default API Server URL"),
        translate("The URL of the API server, used for connecting the web frontend. (--api-host parameter)<br>"
                .. "Example: http://[current device IP or resolved domain name]:[API port]"))

web_geoip_db = s:taboption("webconsole", Value, "web_geoip_db", translate("GEOIP_DB Path"),
        translate("GeoIP2 database file path used to locate the client. Defaults to an embedded file (country-level information only)."
		.. "<br>Recommended: https://github.com/P3TERX/GeoLite.mmdb (--geoip-db parameter)"))
web_geoip_db.placeholder = "/etc/easytier/GeoLite.mmdb"

web_weblog = s:taboption("webconsole", ListValue, "web_weblog", translate("Program Log"),
        translate("Runtime log located at /tmp/easytierweb.log, viewable in the log section above.<br>"
                .. "Levels: Error < Warning < Info < Debug < Trace"))
web_weblog.default = "off"
web_weblog:value("off", translate("Off"))
web_weblog:value("error", translate("Error"))
web_weblog:value("warn", translate("Warning"))
web_weblog:value("info", translate("Info"))
web_weblog:value("debug", translate("Debug"))
web_weblog:value("trace", translate("Trace"))

return m
