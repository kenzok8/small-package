local d = require "luci.dispatcher"
local sys = require "luci.sys"

m = Map("luci-app-openvpn-server", translate("OpenVPN Server"))
m.template = "openvpn-server/index"

s = m:section(NamedSection, "server", "server", "")
s.addremove = false
s.anonymous = true

s:tab("general",  translate("General Settings"))
s:tab("certificate", translate("Certificate"))

o = s:taboption("general", DummyValue, "_status", translate("Current Condition"))
o.template = "openvpn-server/status"
o.value = translate("Collecting data...")

o = s:taboption("general", Flag, "enabled", translate("Enabled"))
o.rmempty = false

o = s:taboption("general", Value, "port", translate("Port"))
o.datatype = "port"
o.default = "1194"
o.rmempty = false

o = s:taboption("general", ListValue, "proto", translate("Protocol"))
o.default = "udp"
o:value("tcp", "TCP")
o:value("udp", "UDP")
o.rmempty = false

if sys.call("command -v ip6tables > /dev/null") == 0 then
	o = s:taboption("general", Flag, "ipv6", translate("Listen IPv6"))
end

o = s:taboption("general", Value, "ip_segment", translate("IP segment"))
o.datatype = "ipaddr"
o.placeholder = "172.30.1.0"
o.default = o.placeholder
o.rmempty = false

o = s:taboption("general", Value, "subnet_mask", translate("Subnet mask"))
o.datatype = "ipaddr"
o.placeholder = "255.255.255.0"
o.default = o.placeholder
o.rmempty = false

o = s:taboption("general", Flag, "lzo", translate("LZO compression"))
o.default = "1"
o.rmempty = false

o = s:taboption("general", TextValue, "extra_config", translate("Extra Config"))
o.datatype = "string"
o.rows = 3
o.wrap = "off"

o = s:taboption("general", Value, "ddns", translate("DDNS or IP"))
o.datatype = "string"
o.default = "example.com"
o.rmempty = false

o = s:taboption("general", Button, "certificate", translate("OpenVPN Client config file"))
o.inputtitle = translate("Download .ovpn file")
o.inputstyle = "reload"
o.write = function()
	luci.sys.call("sh /usr/share/openvpn-server/script/gen_client_config.sh >/dev/null 2>&1")
	local t,e
	t = nixio.open("/tmp/openvpn.ovpn","r")
	luci.http.header('Content-Disposition','attachment; filename="openvpn.ovpn"')
	luci.http.prepare_content("application/octet-stream")
	while true do
		e = t:read(nixio.const.buffersize)
		if (not e) or (#e==0) then
			break
		else
			luci.http.write(e)
		end
	end
	t:close()
	os.remove("/tmp/openvpn.ovpn")
	luci.http.close()
end

ca = s:taboption("certificate", Value, "_ca", translate("CA certificate"))
ca.template = "cbi/tvalue"
ca.rows = 15
function ca.cfgvalue(self, section)
	return nixio.fs.readfile("/usr/share/openvpn-server/ca.crt")
end

function ca.write(self, section, value)
	nixio.fs.writefile("/usr/share/openvpn-server/ca.crt", value)
end

server_crt = s:taboption("certificate", Value, "_server_crt", translate("Server certificate"))
server_crt.template = "cbi/tvalue"
server_crt.rows = 15
function server_crt.cfgvalue(self, section)
	return nixio.fs.readfile("/usr/share/openvpn-server/server.crt")
end

function server_crt.write(self, section, value)
	nixio.fs.writefile("/usr/share/openvpn-server/server.crt", value)
end

server_key = s:taboption("certificate", Value, "_server_key", translate("Server private key"))
server_key.template = "cbi/tvalue"
server_key.rows = 15
function server_key.cfgvalue(self, section)
	return nixio.fs.readfile("/usr/share/openvpn-server/server.key")
end

function server_key.write(self, section, value)
	nixio.fs.writefile("/usr/share/openvpn-server/server.key", value)
end

renew = s:taboption("certificate", Button, "_renew", translate("Renew certificate"), translate("Please wait a moment after clicking..."))
renew.inputstyle = "apply"
function renew.write(self, section, value)
	luci.sys.call("sh /usr/share/openvpn-server/script/ca_renew.sh > /dev/null 2>&1 &")
	luci.http.redirect(d.build_url("admin", "vpn", "openvpn-server"))
end

s = m:section(TypedSection, "users", translate("Users Manager"))
s.addremove = true
s.anonymous = true
s.template = "cbi/tblsection"
s.extedit = d.build_url("admin", "vpn", "openvpn-server", "user", "%s")
function s.create(e, t)
    t = TypedSection.create(e, t)
    luci.http.redirect(e.extedit:format(t))
end

o = s:option(Flag, "enabled", translate("Enabled"))
o.default = 1
o.rmempty = false

o = s:option(Value, "username", translate("Username"))
o.placeholder = translate("Username")
o.rmempty = false

o = s:option(Value, "password", translate("Password"))
o.placeholder = translate("Password")
o.rmempty = false

o = s:option(Value, "ipaddress", translate("IP address"))
o.placeholder = translate("Automatically")
o.datatype = "ip4addr"
o.rmempty = true

return m
