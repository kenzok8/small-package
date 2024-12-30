-- Copyright 2020 lwz322 <lwz322@qq.com> #modify by superzjg@gmail.com 20240811
-- Licensed to the public under the MIT License.

local uci = require "luci.model.uci".cursor()
local util = require "luci.util"
local fs = require "nixio.fs"
local sys = require "luci.sys"

local m, s, o
local server_table = { }

local function frps_version()
	local file = uci:get("frps", "main", "client_file")

	if not file or file == "" or not fs.stat(file) then
		return "<em style=\"color: red;\">%s</em>" % translate("可执行文件无效")
	end

	if not fs.access(file, "rwx", "rx", "rx") then
		fs.chmod(file, 755)
	end

	local version = util.trim(sys.exec("%s -v 2>/dev/null" % file))
	if version == "" then
		return "<em style=\"color: red;\">%s</em>" % translate("未能获取到版本信息")
	end
	if version < "0.52.0" then
		return "<em style=\"color: red;\">%s</em>" % translatef("升级至 0.52.0 或以上才支持toml配置文件，当前版本：%s", version)
	end
	return translatef("版本: %s", version)
end

m = Map("frps", "%s - %s" % { translate("Frps"), translate("通用设置") },
"<p>%s</p><p>%s</p>" % {
	translate("Frp 是一个可用于内网穿透的高性能的反向代理应用。"),
	translatef("获取更多信息，请访问：%s",
		"<a href=\"https://github.com/fatedier/frp\" target=\"_blank\">https://github.com/fatedier/frp</a>；官方文档：<a href=\"https://gofrp.org/zh-cn/\" target=\"_blank\">gofrp.org</a>")
})

m:append(Template("frps/status_header"))

s = m:section(NamedSection, "main", "frps")
s.addremove = false
s.anonymous = true

s:tab("general", translate("常规选项"))
s:tab("basic", translate("基础选项"))
s:tab("advanced", translate("高级选项"))
s:tab("dashboard", translate("管理面板选项"))

o = s:taboption("general", Flag, "enabled", translate("启用"))

o = s:taboption("general", Value, "client_file", translate("可执行文件路径"), frps_version())
o.datatype = "file"
o.rmempty = false
o.default = "/usr/bin/frps"

o = s:taboption("general", ListValue, "run_user", translate("以用户身份运行"))
o:value("", translate("-- 默认 --"))
local user
for user in util.execi("cat /etc/passwd | cut -d':' -f1") do
	o:value(user)
end

o = s:taboption("general", ListValue, "set_firewall", translate("防火墙通信规则"), translate("检测：启动服务，无规则将建立，停止服务时不删除<br/>强制：启动时删除并重建，停止时删除"))
o:value("no", translate("不操作"))
o:value("check", translate("检测"))
o:value("force", translate("强制"))
o.default = "no"
o = s:taboption("general", Value, "tcp_ports", translate("防火墙通信规则-TCP端口"), translate("多端口号用空格隔开，下同"))
o:depends("set_firewall", "check")
o:depends("set_firewall", "force")
o = s:taboption("general", Value, "udp_ports", translate("防火墙通信规则-UDP端口"))
o:depends("set_firewall", "check")
o:depends("set_firewall", "force")

o = s:taboption("general", Flag, "enable_logging", translate("启用日志"),
	translate("Frp 运行日志设置。不含 luci-app 日志（此部分在“系统日志”查看）"))

o = s:taboption("general", Flag, "std_redirect", translate("重定向标准输出"),
    translate("Frp的标准输出、标准错误重定向到日志文件"))
o:depends("enable_logging", "1")

o = s:taboption("general", Value, "log__to", translate("日志文件"),translate("填写文件路径，留空相当于填入 console（日志打印在标准输出中）"))
o:depends("enable_logging", "1")
o.default = "/var/log/frps.log"

o = s:taboption("general", ListValue, "log__level", translate("日志等级"),translate("留空默认：info"))
o:depends("enable_logging", "1")
o:value("", translate("（空）"))
o:value("trace", translate("追踪"))
o:value("debug", translate("调试"))
o:value("info", translate("信息"))
o:value("warn", translate("警告"))
o:value("error", translate("错误"))

o = s:taboption("general", Value, "log__maxDays", translate("日志保存天数"),translate("留空默认 3 天（不含当天），会按日期命名文件，1天1个"))
o:depends("enable_logging", "1")
o.datatype = "uinteger"
o.placeholder = '3'

o = s:taboption("general", Flag, "log__disablePrintColor", translate("禁用日志颜色"), 
    translate("当日志文件为 console 时禁用日志颜色，默认不禁用"))
o:depends("enable_logging", "1")
o.enabled= "true"
o.disabled = ""

o = s:taboption("basic", Value, "bindAddr", translate("绑定地址"), translate("留空，即所有地址（含IPv6）"))
o.placeholder = "0.0.0.0"
o = s:taboption("basic", Value, "bindPort", translate("绑定端口"))
o.datatype = "integer"
o.placeholder = "7000"

o = s:taboption("basic", ListValue, "auth__method", translate("鉴权方式"),
	translate("留空默认 token，若用 oidc 请使用“高级选项”中的 “额外选项” 添加参数"))
o:value("", translate("（空）"))
o:value("token")
o:value("oidc")

o = s:taboption("basic", Value, "auth__token", translate("鉴权令牌"))
o.password = true
o:depends("auth__method", "")
o:depends("auth__method", "token")

o = s:taboption("basic", Flag, "transport__tcpMux", translate("关闭 TCP 复用"),
	translate("Frps 默认开启 tcpMux。提示：frpc 和 frps 要作相同设置"))
o.enabled = "false"
o.disabled = ""

o = s:taboption("basic", Value, "transport__tcpMuxKeepaliveInterval", translate("tcpMux心跳检查间隔秒数"))
o:depends("transport__tcpMux", "")
o.datatype = "uinteger"
o.placeholder = "30"

o = s:taboption("basic", Value, "kcpBindPort", translate("KCP绑定端口"), 
    translatef("UDP端口用于kcp协议，建议不要与QUIC端口冲突；留空以禁用kcp"))
o.datatype = "port"

o = s:taboption("basic", Value, "quicBindPort", translate("QUIC绑定端口"), 
    translatef("UDP端口用于quic协议，建议不要与KCP端口冲突；留空以禁用quic"))
o.datatype = "port"

o = s:taboption("basic", Value, "vhostHTTPPort", translate("虚拟主机HTTP端口"), 
    translatef("如果希望支持虚拟主机，则必须设定 http 或 https 端口"))
o.datatype = "port"

o = s:taboption("basic", Value, "vhostHTTPSPort", translate("虚拟主机HTTPS端口"), 
    translatef("注意：frpc 默认禁用了TLS第一个自定义字节，可能影响端口号复用，建议查阅官方文档"))
o.datatype = "port"

o = s:taboption("advanced", Value, "transport__maxPoolCount", translate("最大连接池大小"),
	translate("每个代理的连接池大小 poolCount 不会超过此值"))
o.datatype = "uinteger"
o.placeholder = '5'

o = s:taboption("advanced", Value, "maxPortsPerClient", translate("单客户端最大代理数"),
	translate("限制每个客户端最多可映射端口数，留空则默认为0（不限制）"))
o.datatype = "uinteger"
o.placeholder = '0'

o = s:taboption("advanced", Value, "allowPorts", translate("允许的端口"),
	translate("允许代理绑定的服务端端口，默认留空（不限制）。注意用英文逗号和中横线，例如，简写为：3000-4000,5000,6000-50000 即可，后台会转换格式"))

o = s:taboption("advanced", Value, "subDomainHost", translate("子域名后缀"), 
	translatef("如果subDomainHost不为空，例如frps.com；可在frpc中对类型为http(s)的代理设置subdomain，若设为test，路由将使用test.frps.com"))
o.datatype = "host"

o = s:taboption("advanced", Flag, "transport__tls__force", translate("强制frps只接受TLS连接"))
o.enabled = "true"
o.disabled = ""

o = s:taboption("advanced", Value, "transport__tls__certFile", translate("TLS服务端证书文件路径"))
o.datatype = "file"

o = s:taboption("advanced", Value, "transport__tls__keyFile", translate("TLS服务端密钥文件路径"))
o.datatype = "file"

o = s:taboption("advanced", Value, "transport__tls__trustedCaFile", translate("TLS CA证书路径"))
o.datatype = "file"

o = s:taboption("advanced", Value, "transport__heartbeatTimeout", translate("心跳超时"),
    translate("与客户端心跳连接的超时时间（秒），负数禁用，默认-1，因frp默认开启TCP复用（tcpmux）进行心跳检测"))
o.datatype = "integer"
o.placeholder = "-1"

o = s:taboption("advanced", Value, "proxyBindAddr", translate("代理监听地址"),
	translate("使代理监听在不同的地址（新手慎用）。留空，即默认在绑定地址监听"))

o = s:taboption("advanced", DynamicList, "extra_setting", translate("额外选项"),
	translatef("点击添加列表，一行一条，写入frp的配置文件的通用部分末尾；格式错误可能导致无法启动服务"))
o.placeholder = "option = value"

o = s:taboption("dashboard", Value, "webServer__addr", translate("面板地址"), translatef("默认本机访问；要远程访问按需设置"))
o.datatype = "host"
o.placeholder = "127.0.0.1"
o = s:taboption("dashboard", Value, "webServer__port", translate("面板端口"))
o.datatype = "port"

o = s:taboption("dashboard", Value, "webServer__user", translate("登录用户名"))

o = s:taboption("dashboard", Value, "webServer__password", translate("登录密码"))
o.password = true

o = s:taboption("dashboard", Value, "webServer__tls__certFile", translate("TLS证书文件路径"), translate("证书和密钥都配置表示面板开启TLS；都留空即不开启"))
o.datatype = "file"
o = s:taboption("dashboard", Value, "webServer__tls__keyFile", translate("TLS密钥文件路径"))
o.datatype = "file"

return m
