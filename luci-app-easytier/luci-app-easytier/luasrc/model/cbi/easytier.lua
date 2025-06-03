local http = luci.http
local nixio = require "nixio"

m = Map("easytier")
m.description = translate('一个简单、安全、去中心化的内网穿透 VPN 组网方案，使用 Rust 语言和 Tokio 框架实现。 项目地址：<a href="https://github.com/EasyTier/EasyTier" target="_blank">github.com/EasyTier/EasyTier</a>&nbsp;&nbsp;<a href="http://easytier.cn" target="_blank">官网文档</a>&nbsp;&nbsp;<a href="http://qm.qq.com/cgi-bin/qm/qr?_wv=1027&k=jhP2Z4UsEZ8wvfGPLrs0VwLKn_uz0Q_p&authKey=OGKSQLfg61YPCpVQuvx%2BxE7hUKBVBEVi9PljrDKbHlle6xqOXx8sOwPPTncMambK&noverify=0&group_code=949700262" target="_blank">QQ群</a>&nbsp;&nbsp;<a href="https://doc.oee.icu">菜鸟教程</a>')

m:section(SimpleSection).template  = "easytier/easytier_status"

-- easytier-core
s=m:section(TypedSection, "easytier", translate("EasyTier配置"))
s.addremove=false
s.anonymous=true
s:tab("general", translate("基本设置"))
s:tab("privacy", translate("高级设置"))
s:tab("infos", translate("连接信息"))
s:tab("upload", translate("上传程序"))

switch = s:taboption("general",Flag, "enabled", translate("Enable"))
switch.rmempty = false

btncq = s:taboption("general", Button, "btncq", translate("重启"))
btncq.inputtitle = translate("重启")
btncq.description = translate("在没有修改参数的情况下快速重新启动一次")
btncq.inputstyle = "apply"
btncq:depends("enabled", "1")
btncq.write = function()
  luci.sys.call("/etc/init.d/easytier restart >/dev/null 2>&1 &")  -- 执行重启命令
end

etcmd = s:taboption("general",ListValue, "etcmd", translate("启动方式"),
	translate("官方Web控制台：<a href='https://easytier.cn/web' target='_blank'>https://easytier.cn/web</a><br>官方配置文件生成器：<a href='https://easytier.cn/web/index.html#/config_generator' target='_blank'>https://easytier.cn/web/index.html#/config_generator</a><br>注意配置RPC端口为15888"))
etcmd.default = "etcmd"
etcmd:value("etcmd",translate("默认"))
etcmd:value("config",translate("配置文件"))
etcmd:value("web",translate("Web配置"))

et_config = s:taboption("general",TextValue, "et_config", translate("配置文件"),
	translate("配置文件在/etc/easytier/config.toml<br>命令行的启动参数和此配置文件的参数不会同步<br>注意填写tun网卡名和端口用以自动防火墙放行"))
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

web_config = s:taboption("general", Value, "web_config", translate("Web服务器地址"),
	translate("Web配置服务器地址。（-w 参数）<br>自建Web服务器 输入格式：udp://服务器地址:22020/账户名<br>官方Web服务器 输入格式：账户名 <br>官方Web控制台：<a href='https://easytier.cn/web' target='_blank'>https://easytier.cn/web</a>"))
web_config.placeholder = "admin"
web_config:depends("etcmd", "web")

network_name = s:taboption("general", Value, "network_name", translate("网络名称"),
	translate("用于识别此 VPN 网络的网络名称（--network-name 参数）"))
network_name.password = true
network_name.placeholder = "test"
network_name:depends("etcmd", "etcmd")
network_name:depends("log", "error")
network_name:depends("log", "warn")
network_name:depends("log", "info")
network_name:depends("log", "debug")
network_name:depends("log", "trace")

network_secret = s:taboption("general", Value, "network_secret", translate("网络密钥"),
	translate("网络密钥，用于验证此节点是否属于 VPN 网络（--network-secret 参数）"))
network_secret.password = true
network_secret.placeholder = "test"
network_secret:depends("etcmd", "etcmd")

ip_dhcp = s:taboption("general",Flag, "ip_dhcp", translate("启用dhcp"),
	translate("由Easytier自动确定并设置IP地址，默认从10.0.0.1开始。警告：在使用DHCP时，如果网络中出现IP冲突，IP将自动更改。（-d 参数）"))
ip_dhcp:depends("etcmd", "etcmd")

ipaddr = s:taboption("general",Value, "ipaddr", translate("接口IP地址"),
	translate("此VPN节点的IPv4地址，如果为空，则此节点将仅转发数据包，不会创建TUN设备（-i 参数）"))
ipaddr.datatype = "ip4addr"
ipaddr.placeholder = "10.0.0.1"
ipaddr:depends("etcmd", "etcmd")

peeradd = s:taboption("general",DynamicList, "peeradd", translate("对等节点"),
	translate("初始连接的对等节点，和下方参数作用一样 （-p 参数）<br>公共服务器可用状态查询：<a href='https://easytier.gd.nkbpal.cn/status/easytier' target='_blank'>点此查询</a>"))
peeradd.placeholder = "tcp://public.easytier.top:11010"
peeradd:value("tcp://public.easytier.top:11010", translate("官方服务器-tcp://public.easytier.top:11010"))
peeradd:depends("etcmd", "etcmd")

external_node = s:taboption("general", Value, "external_node", translate("共享节点地址"),
	translate("使用公共共享节点来发现对等节点，和上方参数作用一样 （-e 参数）"))
external_node.default = ""
external_node.placeholder = "tcp://public.easytier.top:11010"
external_node:value("tcp://public.easytier.top:11010", translate("官方服务器-tcp://public.easytier.top:11010"))
external_node:depends("etcmd", "etcmd")

proxy_network = s:taboption("general",DynamicList, "proxy_network", translate("子网代理"),
	translate("将本地网络导出到 VPN 中的其他对等点，可访问当前局域网内其他设备 （-n 参数）"))
proxy_network:depends("etcmd", "etcmd")

mapped_listeners = s:taboption("privacy",DynamicList, "mapped_listeners", translate("指定监听器的公网地址"),
	translate("手动指定本机的公网地址，其他节点可以使用该地址连接到本节点（不支持域名）。<br>例如：tcp://123.123.123.123:11223，可以指定多个。（--mapped-listeners 参数）"))
mapped_listeners:depends("listenermode", "ON")

rpc_portal = s:taboption("privacy", Value, "rpc_portal", translate("门户地址端口"),
	translate("用于管理的 RPC 门户地址。0 表示随机端口，12345 表示监听本地主机的 12345 端口，0.0.0.0:12345 表示在所有接口上监听 12345 端口。<br>默认值为 0，建议选 15888 防止无法获取状态信息 （-r 参数）"))
rpc_portal.placeholder = "15888"
rpc_portal.default = "15888"
rpc_portal.datatype = "range(1,65535)"
rpc_portal:depends("etcmd", "etcmd")

listenermode = s:taboption("general",ListValue, "listenermode", translate("监听端口"),
	translate("OFF:不监听任何端口，只连接到对等节点 （--no-listener 参数）<br>单纯作为客户端使用（不作为服务器）可以不监听端口"))
listenermode:value("ON",translate("监听"))
listenermode:value("OFF",translate("不监听"))
listenermode.default = "OFF"
listenermode:depends("etcmd", "etcmd")

listener6 = s:taboption("general",Flag, "listener6", translate("同时监听IPV6"),
	translate("默认只监听IPV4，对等节点只能使用IPV4连接，启用后将同时监听IPV6端口"))
listener6:depends("listenermode", "ON")
listener6:depends("etcmd", "etcmd")

tcp_port = s:taboption("general",Value, "tcp_port", translate("tcp/udp端口"),
	translate("tcp/udp协议，端口号：11010，表示 tcp/udp 将在 11010 上监听 <br>如果是配置文件Web配置请填写一样的监听端口用于防火墙放行"))
tcp_port.datatype = "range(1,65535)"
tcp_port.default = "11010"
tcp_port:depends("listenermode", "ON")
tcp_port:depends("etcmd", "web")

ws_port = s:taboption("general",Value, "ws_port", translate("ws端口"),
	translate("ws协议，端口号：11011，表示 ws 将在 11011 上监听 <br>如果是配置文件Web配置请填写一样的监听端口用于防火墙放行"))
ws_port.datatype = "range(1,65535)"
ws_port.default = "11011"
ws_port:depends("listenermode", "ON")
ws_port:depends("etcmd", "web")

wss_port = s:taboption("general",Value, "wss_port", translate("wss端口"),
	translate("wss协议，端口号：11012，表示 wss 将在 11012 上监听 <br>如果是配置文件Web配置请填写一样的监听端口用于防火墙放行"))
wss_port.datatype = "range(1,65535)"
wss_port.default = "11012"
wss_port:depends("listenermode", "ON")
wss_port:depends("etcmd", "web")

wg_port = s:taboption("general",Value, "wg_port", translate("wg端口"),
	translate("wireguard协议，端口号：11011，表示 wg 将在 11011 上监听 <br>如果是配置文件Web配置请填写一样的监听端口用于防火墙放行"))
wg_port.datatype = "range(1,65535)"
wg_port.placeholder = "11011"
wg_port:depends("listenermode", "ON")
wg_port:depends("etcmd", "web")

local model = nixio.fs.readfile("/proc/device-tree/model") or ""
local hostname = nixio.fs.readfile("/proc/sys/kernel/hostname") or ""
model = model:gsub("\n", "")
hostname = hostname:gsub("\n", "")
local device_name = (model ~= "" and model) or (hostname ~= "" and hostname) or "OpenWrt"
device_name = device_name:gsub(" ", "_")
desvice_name = s:taboption("general", Value, "desvice_name", translate("主机名"),
    translate("用于标识此设备的主机名 （--hostname 参数）"))
desvice_name.placeholder = device_name
desvice_name.default = device_name
desvice_name:depends("etcmd", "etcmd")
desvice_name:depends("etcmd", "web")

uuid = s:taboption("general", Value, "uuid", translate("uuid"),
    translate("连接web控制台时识别此设备的唯一标识，用于下发配置文件"))
uuid.rows = 1
uuid.wrap = "off"
uuid:depends("etcmd", "web")
uuid.cfgvalue = function(self, section)
    return nixio.fs.readfile("/etc/easytier/et_machine_id") or ""
end
uuid.write = function(self, section, value)
    nixio.fs.writefile("/etc/easytier/et_machine_id", value:gsub("\r\n", "\n"))
end

instance_name = s:taboption("privacy",Value, "instance_name", translate("实例名称"),
	translate("用于在同一台机器中标识此 VPN 节点的实例名称，启用日志需要填写，web配置时填一样的instance_name名称 （-m 参数）"))
instance_name.placeholder = "default"
instance_name:depends("etcmd", "etcmd")
instance_name:depends("etcmd", "web")

vpn_portal = s:taboption("privacy",Value, "vpn_portal", translate("VPN门户URL"),
	translate("定义 VPN 门户的 URL，允许其他 VPN 客户端连接。<br> 示例：wg://0.0.0.0:11011/10.14.14.0/24，表示 VPN 门户是一个在 vpn.example.com:11010 上监听的 WireGuard 服务器，并且 VPN 客户端位于 10.14.14.0/24 网络中（--vpn-portal 参数）"))
vpn_portal.placeholder = "wg://0.0.0.0:11011/10.14.14.0/24"
vpn_portal:depends("etcmd", "etcmd")

mtu = s:taboption("privacy",Value, "mtu", translate("MTU"),
	translate("TUN 设备的 MTU，默认值为非加密时的 1380，加密时为 1360"))
mtu.datatype = "range(1,1500)"
mtu.placeholder = "1300"
mtu:depends("etcmd", "etcmd")

default_protocol = s:taboption("privacy",ListValue, "default_protocol", translate("默认协议"),
	translate("连接对等节点时使用的默认协议（--default-protocol 参数）"))
default_protocol:value("-",translate("默认"))
default_protocol:value("tcp")
default_protocol:value("udp")
default_protocol:value("ws")
default_protocol:value("wss")
default_protocol:depends("etcmd", "etcmd")

tunname = s:taboption("privacy",Value, "tunname", translate("虚拟网卡名称"),
	translate("自定义虚拟网卡TUN接口的名称（--dev-name 参数）<br>如果是WEB配置请填写和WEB配置一样的虚拟网卡名称用于防火墙放行"))
tunname.placeholder = "tun0"
tunname:depends("etcmd", "etcmd")
tunname:depends("etcmd", "web")

disable_encryption = s:taboption("general",Flag, "disable_encryption", translate("禁用加密"),
	translate("禁用对等节点通信的加密，若关闭加密则其他节点也必须关闭加密 （-u 参数）"))
disable_encryption:depends("etcmd", "etcmd")

multi_thread = s:taboption("general",Flag, "multi_thread", translate("启用多线程"),
	translate("使用多线程运行时，默认为单线程 （--multi-thread 参数）"))
multi_thread:depends("etcmd", "etcmd")

disable_ipv6 = s:taboption("privacy",Flag, "disable_ipv6", translate("禁用ipv6"),
	translate("不使用ipv6 （--disable-ipv6 参数）"))
disable_ipv6:depends("etcmd", "etcmd")

latency_first = s:taboption("general",Flag, "latency_first", translate("启用延迟优先"),
	translate("延迟优先模式，将尝试使用最低延迟路径转发流量，默认使用最短路径 （--latency-first 参数）"))
latency_first:depends("etcmd", "etcmd")

comp = s:taboption("general",ListValue, "comp", translate("压缩算法"),
	translate("使用的压缩算法 （--compression  参数）"))
comp.default = "none"
comp:value("none",translate("默认"))
comp:value("zstd",translate("zstd"))
comp:depends("etcmd", "etcmd")

exit_node = s:taboption("privacy",Flag, "exit_node", translate("启用出口节点"),
	translate("允许此节点成为出口节点 （--enable-exit-node 参数）"))
exit_node:depends("etcmd", "etcmd")

exit_nodes = s:taboption("privacy",DynamicList, "exit_nodes", translate("出口节点地址"),
	translate("转发所有流量的出口节点，虚拟 IPv4 地址，优先级由列表顺序确定（--exit-nodes 参数）"))
exit_nodes:depends("etcmd", "etcmd")

smoltcp = s:taboption("privacy",Flag, "smoltcp", translate("使用用户态协议栈"),
	translate("为子网代理启用smoltcp堆栈（--use-smoltcp 参数）"))
smoltcp:depends("etcmd", "etcmd")

no_tun = s:taboption("privacy",Flag, "no_tun", translate("无tun模式"),
	translate("不创建TUN设备，可以使用子网代理访问节点（ --no-tun 参数）"))
no_tun:depends("etcmd", "etcmd")

proxy_forward = s:taboption("privacy",Flag, "proxy_forward", translate("禁用内置NAT"),
	translate("通过系统内核转发子网代理数据包，禁用内置NAT（ --proxy-forward-by-system 参数）"))
proxy_forward:depends("etcmd", "etcmd")

manual_routes = s:taboption("privacy",DynamicList, "manual_routes", translate("路由CIDR"),
	translate("手动分配路由CIDR，将禁用子网代理和从对等节点传播的wireguard路由。（--manual-routes 参数）"))
manual_routes.placeholder = "192.168.0.0/16"
manual_routes:depends("etcmd", "etcmd")

relay_network = s:taboption("privacy",Flag, "relay_network", translate("转发白名单网络的流量"),
	translate("仅转发白名单网络的流量，默认允许所有网络"))
relay_network:depends("etcmd", "etcmd")

whitelist = s:taboption("privacy",DynamicList, "whitelist", translate("白名单网络"),
	translate("仅转发白名单网络的流量，输入是通配符字符串，例如：'*'（所有网络），'def*'（以def为前缀的网络）<br>可以指定多个网络。如果参数为空，则禁用转发。（--relay-network-whitelist 参数）"))
whitelist:depends("relay_network", "1")

socks_port = s:taboption("privacy",Value, "socks_port", translate("socks5端口"),
	translate("启用 socks5 服务器，允许 socks5 客户端访问虚拟网络，留空则不开启（--socks5 参数）"))
socks_port.datatype = "range(1,65535)"
socks_port.placeholder = "1080"
socks_port:depends("etcmd", "etcmd")

disable_p2p = s:taboption("privacy",Flag, "disable_p2p", translate("禁用P2P"),
	translate("禁用P2P通信，只通过-p指定的节点转发数据包 （ --disable-p2p 参数）"))
disable_p2p:depends("etcmd", "etcmd")

disable_udp = s:taboption("privacy",Flag, "disable_udp", translate("禁用UDP"),
	translate("禁用UDP打洞功能（ --disable-udp-hole-punching 参数）"))
disable_udp:depends("etcmd", "etcmd")

relay_all = s:taboption("privacy",Flag, "relay_all", translate("允许转发"),
	translate("转发所有对等节点的RPC数据包，即使对等节点不在转发网络白名单中。<br>这可以帮助白名单外网络中的对等节点建立P2P连接。（ -relay-all-peer-rpc 参数）"))
relay_all:depends("etcmd", "etcmd")

bind_device = s:taboption("privacy",Flag, "bind_device", translate("仅使用物理网卡"),
	translate("将连接器的套接字绑定到物理设备以避免路由问题。<br>比如子网代理网段与某节点的网段冲突，绑定物理设备后可以与该节点正常通信。（ --bind-device 参数）"))
bind_device.default = "0"
bind_device:depends("etcmd", "etcmd")

kcp_proxy = s:taboption("privacy",Flag, "kcp_proxy", translate("启用KCP代理"),
	translate("将TCP流量转为 KCP 流量，降低传输延迟，提升传输速度。<br>KCP 代理功能需要虚拟网内所有节点的 EasyTier 版本在 v2.2.0 以上。（ --enable-kcp-proxy 参数）"))
kcp_proxy:depends("etcmd", "etcmd")

kcp_input = s:taboption("privacy",Flag, "kcp_input", translate("禁用KCP输入"),
	translate("不允许其他节点使用 KCP 代理 TCP 流到此节点。<br>开启 KCP 代理的节点访问此节点时，依然使用原始。（ --disable-kcp-input 参数）"))
kcp_input:depends("etcmd", "etcmd")

accept_dns = s:taboption("privacy",Flag, "accept_dns", translate("启用魔法DNS"),
	translate("使用魔法DNS，您可以使用域名访问其他节点，例如：<hostname>.et.net。魔法DNS将修改您的系统DNS设置，请谨慎启用。（--accept-dns 参数）"))
accept_dns:depends("etcmd", "etcmd")

log = s:taboption("general",ListValue, "log", translate("程序日志"),
	translate("运行日志在/tmp/easytier.log,可在上方日志查看<br>若启动失败，请前往 状态- 系统日志 查看具体启动失败日志<br>详细程度：警告<信息<调试<跟踪"))
log.default = "off"
log:value("off",translate("关闭"))
log:value("error",translate("错误"))
log:value("warn",translate("警告"))
log:value("info",translate("信息"))
log:value("debug",translate("调试"))
log:value("trace",translate("跟踪"))

et_forward = s:taboption("privacy",MultiValue, "et_forward", translate("访问控制"),
	translate("设置不同网络区域之间的流量允许规则"))
et_forward:value("etfwlan", translate("允许从虚拟网络 EasyTier 到局域网 lan 的流量"))
et_forward:value("etfwwan", translate("允许从虚拟网络 EasyTier 到广域网 wan 的流量"))
et_forward:value("lanfwet", translate("允许从局域网 lan 到虚拟网络 EasyTier 的流量"))
et_forward:value("wanfwet", translate("允许从广域网 wan 到虚拟网络 EasyTier 的流量"))
et_forward.default = "etfwlan etfwwan lanfwet"
et_forward.rmempty = true

check = s:taboption("privacy",Flag, "check", translate("通断检测"),
        translate("开启通断检测后，可以指定对端的设备IP，当所有指定的IP都ping不通时将会重启easytier程序"))

checkip=s:taboption("privacy",DynamicList,"checkip",translate("检测IP"),
        translate("确保这里的对端设备IP地址填写正确且可访问，若填写错误将会导致无法ping通，程序反复重启"))
checkip.rmempty = true
checkip.datatype = "ip4addr"
checkip:depends("check", "1")

checktime = s:taboption("privacy",ListValue, "checktime", translate("间隔时间 (分钟)"),
        translate("检测间隔的时间，每隔多久检测指定的IP通断一次"))
for s=1,60 do
checktime:value(s)
end
checktime:depends("check", "1")

local process_status = luci.sys.exec("ps | grep easytier-core| grep -v grep")

btn0 = s:taboption("infos", Button, "btn0")
btn0.inputtitle = translate("node信息")
btn0.description = translate("点击按钮刷新，查看本机信息")
btn0.inputstyle = "apply"
btn0.write = function()
if process_status ~= "" then
   luci.sys.call("$(dirname $(uci -q get easytier.@easytier[0].easytierbin))/easytier-cli node >/tmp/easytier-cli_node 2>&1")
else
    luci.sys.call("echo '错误：程序未运行！请启动程序后重新点击刷新' >/tmp/easytier-cli_node")
end
end

btn0info = s:taboption("infos", DummyValue, "btn0info")
btn0info.rawhtml = true
btn0info.cfgvalue = function(self, section)
    local content = nixio.fs.readfile("/tmp/easytier-cli_node") or ""
    return string.format("<pre>%s</pre>", luci.util.pcdata(content))
end

btn1 = s:taboption("infos", Button, "btn1")
btn1.inputtitle = translate("peer信息")
btn1.description = translate("点击按钮刷新，查看对端信息")
btn1.inputstyle = "apply"
btn1.write = function()
if process_status ~= "" then
   luci.sys.call("$(dirname $(uci -q get easytier.@easytier[0].easytierbin))/easytier-cli peer >/tmp/easytier-cli_peer 2>&1")
else
    luci.sys.call("echo '错误：程序未运行！请启动程序后重新点击刷新' >/tmp/easytier-cli_peer")
end
end

btn1info = s:taboption("infos", DummyValue, "btn1info")
btn1info.rawhtml = true
btn1info.cfgvalue = function(self, section)
    local content = nixio.fs.readfile("/tmp/easytier-cli_peer") or ""
    return string.format("<pre>%s</pre>", luci.util.pcdata(content))
end

btn2 = s:taboption("infos", Button, "btn2")
btn2.inputtitle = translate("connector信息")
btn2.description = translate("点击按钮刷新，查看connector信息")
btn2.inputstyle = "apply"
btn2.write = function()
if process_status ~= "" then
   luci.sys.call("$(dirname $(uci -q get easytier.@easytier[0].easytierbin))/easytier-cli connector >/tmp/easytier-cli_connector 2>&1")
else
    luci.sys.call("echo '错误：程序未运行！请启动程序后重新点击刷新' >/tmp/easytier-cli_connector")
end
end

btn2info = s:taboption("infos", DummyValue, "btn2info")
btn2info.rawhtml = true
btn2info.cfgvalue = function(self, section)
    local content = nixio.fs.readfile("/tmp/easytier-cli_connector") or ""
    return string.format("<pre>%s</pre>", luci.util.pcdata(content))
end

btn3 = s:taboption("infos", Button, "btn3")
btn3.inputtitle = translate("stun信息")
btn3.description = translate("点击按钮刷新，查看stun信息")
btn3.inputstyle = "apply"
btn3.write = function()
if process_status ~= "" then
   luci.sys.call("$(dirname $(uci -q get easytier.@easytier[0].easytierbin))/easytier-cli stun >/tmp/easytier-cli_stun 2>&1")
else
    luci.sys.call("echo '错误：程序未运行！请启动程序后重新点击刷新' >/tmp/easytier-cli_stun")
end
end

btn3info = s:taboption("infos", DummyValue, "btn3info")
btn3info.rawhtml = true
btn3info.cfgvalue = function(self, section)
    local content = nixio.fs.readfile("/tmp/easytier-cli_stun") or ""
    return string.format("<pre>%s</pre>", luci.util.pcdata(content))
end


btn4 = s:taboption("infos", Button, "btn4")
btn4.inputtitle = translate("route信息")
btn4.description = translate("点击按钮刷新，查看route信息")
btn4.inputstyle = "apply"
btn4.write = function()
if process_status ~= "" then
   luci.sys.call("$(dirname $(uci -q get easytier.@easytier[0].easytierbin))/easytier-cli route >/tmp/easytier-cli_route 2>&1")
else
    luci.sys.call("echo '错误：程序未运行！请启动程序后重新点击刷新' >/tmp/easytier-cli_route")
end
end

btn4info = s:taboption("infos", DummyValue, "btn4info")
btn4info.rawhtml = true
btn4info.cfgvalue = function(self, section)
    local content = nixio.fs.readfile("/tmp/easytier-cli_route") or ""
    return string.format("<pre>%s</pre>", luci.util.pcdata(content))
end

btn6 = s:taboption("infos", Button, "btn6")
btn6.inputtitle = translate("peer-center信息")
btn6.description = translate("点击按钮刷新，查看peer-center信息")
btn6.inputstyle = "apply"
btn6.write = function()
if process_status ~= "" then
   luci.sys.call("$(dirname $(uci -q get easytier.@easytier[0].easytierbin))/easytier-cli peer-center >/tmp/easytier-cli_peer-center 2>&1")
else
    luci.sys.call("echo '错误：程序未运行！请启动程序后重新点击刷新' >/tmp/easytier-cli_peer-center")
end
end

btn6info = s:taboption("infos", DummyValue, "btn6info")
btn6info.rawhtml = true
btn6info.cfgvalue = function(self, section)
    local content = nixio.fs.readfile("/tmp/easytier-cli_peer-center") or ""
    return string.format("<pre>%s</pre>", luci.util.pcdata(content))
end

btn7 = s:taboption("infos", Button, "btn7")
btn7.inputtitle = translate("vpn-portal信息")
btn7.description = translate("点击按钮刷新，查看vpn-portal信息")
btn7.inputstyle = "apply"
btn7.write = function()
if process_status ~= "" then
   luci.sys.call("$(dirname $(uci -q get easytier.@easytier[0].easytierbin))/easytier-cli vpn-portal >/tmp/easytier-cli_vpn-portal 2>&1")
else
    luci.sys.call("echo '错误：程序未运行！请启动程序后重新点击刷新' >/tmp/easytier-cli_vpn-portal")
end
end

btn7info = s:taboption("infos", DummyValue, "btn7info")
btn7info.rawhtml = true
btn7info.cfgvalue = function(self, section)
    local content = nixio.fs.readfile("/tmp/easytier-cli_vpn-portal") or ""
    return string.format("<pre>%s</pre>", luci.util.pcdata(content))
end

btn8 = s:taboption("infos", Button, "btn8")
btn8.inputtitle = translate("tcp/kcp代理信息")
btn8.description = translate("点击按钮刷新，查看tcp/kcp代理信息")
btn8.inputstyle = "apply"
btn8.write = function()
if process_status ~= "" then
   luci.sys.call("$(dirname $(uci -q get easytier.@easytier[0].easytierbin))/easytier-cli proxy >/tmp/easytier-cli_proxy 2>&1")
else
    luci.sys.call("echo '错误：程序未运行！请启动程序后重新点击刷新' >/tmp/easytier-cli_proxy")
end
end

btn8info = s:taboption("infos", DummyValue, "btn8info")
btn8info.rawhtml = true
btn8info.cfgvalue = function(self, section)
    local content = nixio.fs.readfile("/tmp/easytier-cli_proxy") or ""
    return string.format("<pre>%s</pre>", luci.util.pcdata(content))
end

btn5 = s:taboption("infos", Button, "btn5")
btn5.inputtitle = translate("本机启动参数")
btn5.description = translate("点击按钮刷新，查看本机完整启动参数")
btn5.inputstyle = "apply"
btn5.write = function()
if process_status ~= "" then
    luci.sys.call("echo $(cat /proc/$(pidof easytier-core)/cmdline | awk '{print $1}') >/tmp/easytier_cmd")
else
    luci.sys.call("echo '错误：程序未运行！请启动程序后重新点击刷新' >/tmp/easytier_cmd")
end
end

btn5cmd = s:taboption("infos", DummyValue, "btn5cmd")
btn5cmd.rawhtml = true
btn5cmd.cfgvalue = function(self, section)
    local content = nixio.fs.readfile("/tmp/easytier_cmd") or ""
    return string.format("<pre>%s</pre>", luci.util.pcdata(content))
end

btnrm = s:taboption("infos", Button, "btnrm")
btnrm.inputtitle = translate("检测更新")
btnrm.description = translate("点击按钮开始检测更新，刷新上方状态栏版本显示")
btnrm.inputstyle = "apply"
btnrm.write = function()
  os.execute("rm -rf /tmp/easytier*.tag /tmp/easytier*.newtag /tmp/easytier-core_*")
end


easytierbin = s:taboption("upload", Value, "easytierbin", translate("easytier-core程序路径"),
	translate("自定义easytier-core的存放路径，确保填写完整的路径及名称,若指定的路径可用空间不足将会自动移至/tmp/easytier-core"))
easytierbin.placeholder = "/usr/bin/easytier-core"
easytierbin.default = "/usr/bin/easytier-core"

webbin = s:taboption("upload", Value, "webbin", translate("easytier-web程序路径"),
	translate("自定义easytier-web的存放路径，确保填写完整的路径及名称，然后上传安装程序"))
webbin.placeholder = "/usr/bin/easytier-web"
webbin.default = "/usr/bin/easytier-web"

local upload = s:taboption("upload", FileUpload, "upload_file")
upload.optional = true
upload.default = ""
upload.template = "easytier/other_upload"
upload.description = translate("可直接上传二进制程序easytier-core和easytier-cli或者以.zip结尾的压缩包,上传新版本会自动覆盖旧版本，下载地址：<a href='https://github.com/EasyTier/EasyTier/releases' target='_blank'>github.com/EasyTier/EasyTier</a><br>上传的文件将会保存在/tmp文件夹里，如果自定义了程序路径那么启动程序时将会自动移至自定义的路径<br>")
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
                um.value = translate("错误：上传失败！")
                return
            end
        end
        if chunk and fd then
            fd:write(chunk)
        end
        if eof and fd then
            fd:close()
            fd = nil
            um.value = translate("文件已上传至") .. ' "/tmp/' .. meta.file .. '"'

            if string.sub(meta.file, -4) == ".zip" then
                local file_path = dir .. meta.file
                os.execute("unzip -q " .. file_path .. " -d " .. dir)
                local extracted_dir = "/tmp/easytier-linux-*/"
                os.execute("mv " .. extracted_dir .. "easytier-cli /tmp/easytier-cli")
                os.execute("mv " .. extracted_dir .. "easytier-core /tmp/easytier-core")
		os.execute("mv " .. extracted_dir .. "easytier-web-embed /tmp/easytier-web-embed")
               if nixio.fs.access("/tmp/easytier-cli") then
                    um.value = um.value .. "\n" .. translate("-程序/tmp/easytier-cli上传成功，重启一次插件才生效")
                end
               if nixio.fs.access("/tmp/easytier-core") then
                    um.value = um.value .. "\n" .. translate("-程序/tmp/easytier-core上传成功，重启一次插件才生效")
                end
		if nixio.fs.access("/tmp/easytier-web-embed") then
                    um.value = um.value .. "\n" .. translate("-程序/tmp/easytier-web上传成功，重启一次插件才生效")
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
                    um.value = um.value .. "\n" .. translate("-程序/tmp/easytier-cli上传成功，重启一次插件才生效")
                end
               if nixio.fs.access("/tmp/easytier-core") then
                    um.value = um.value .. "\n" .. translate("-程序/tmp/easytier-core上传成功，重启一次插件才生效")
                end
		if nixio.fs.access("/tmp/easytier-web-embed") then
                    um.value = um.value .. "\n" .. translate("-程序/tmp/easytier-web上传成功，重启一次插件才生效")
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

-- easytier-web
s=m:section(TypedSection, "easytierweb", translate("自建Web服务器"))
s.addremove=false
s.anonymous=true

switch = s:option(Flag, "enabled", translate("Enable"))
switch.rmempty = false

btncq = s:option(Button, "btncq", translate("重启"))
btncq.inputtitle = translate("重启")
btncq.description = translate("在没有修改参数的情况下快速重新启动一次")
btncq.inputstyle = "apply"
btncq:depends("enabled", "1")
btncq.write = function()
  luci.sys.call("/etc/init.d/easytier restart >/dev/null 2>&1 &")  -- 执行重启命令
end

db_path = s:option(Value, "db_path", translate("数据库文件路径"),
	translate(" sqlite3 数据库文件路径, 用于保存所有数据。（ -d 参数）"))
db_path.default = "/etc/easytier/et.db"

web_protocol = s:option(ListValue, "web_protocol", translate("监听协议"),
	translate("配置服务器的监听协议，用于被 easytier-core 连接。（ -p 参数）"))
web_protocol.default = "udp"
web_protocol:value("udp",translate("UDP"))
web_protocol:value("tcp",translate("TCP"))

web_port = s:option(Value, "web_port", translate("服务端口"),
	translate("配置服务器的监听端口，用于被 easytier-core 连接。（ -c 参数）"))
web_port.datatype = "range(1,65535)"
web_port.placeholder = "22020"
web_port.default = "22020"

api_port = s:option(Value, "api_port", translate("API端口"),
	translate("restful 服务器的监听端口，作为 ApiHost 并被 web 前端使用。（ -a 参数）"))
api_port.datatype = "range(1,65535)"
api_port.placeholder = "11211"
api_port.default = "11211"

html_port = s:option(Value, "html_port", translate("web界面端口"),
	translate("web dashboard 服务器的前端监听端口，留空不启用。（ -l 参数）"))
html_port.datatype = "range(1,65535)"
html_port.placeholder = "11210"

weblog = s:option(ListValue, "weblog", translate("程序日志"),
	translate("运行日志在/tmp/easytierweb.log,可在上方日志查看<br>若启动失败，请前往 状态- 系统日志 查看具体启动失败日志<br>详细程度：警告<信息<调试<跟踪"))
weblog.default = "off"
weblog:value("off",translate("关闭"))
weblog:value("error",translate("错误"))
weblog:value("warn",translate("警告"))
weblog:value("info",translate("信息"))
weblog:value("debug",translate("调试"))
weblog:value("trace",translate("跟踪"))

return m
