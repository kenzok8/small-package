local m, s, o
local sys = require "luci.sys"
local fs = require "nixio.fs"

mp = Map("homeredirect", translate("Home Redirect - Port forwarding utility"))
mp.description = translate("HomeLede port forwarding application - fills the gaps left by firewall port forwarding, mainly used for cross-family forwarding under CGNAT.")
mp:section(SimpleSection).template  = "homeredirect/index"

s = mp:section(TypedSection, "global")
s.anonymous = true

enabled = s:option(Flag, "enabled", translate("Master switch"))
enabled.default = 0
enabled.rmempty = false

-- TLS certificate pair: configure both or neither; files must exist
cert = s:option(Value, "cert", translate("TLS certificate"),
	translate("Required by TLS rules. PEM certificate path, e.g. /etc/acme/your.domain/fullchain.cer. Configure together with the private key."))
cert.optional = true
cert.rmempty = true

key = s:option(Value, "key", translate("TLS private key"),
	translate("PEM private key path matching the certificate above, e.g. /etc/acme/your.domain/your.domain.key. With a combined cert+key file, set both fields to the same path."))
key.optional = true
key.rmempty = true

cert.validate = function(self, value, section)
	if value and #value > 0 then
		local kv = key:formvalue(section)
		if not kv or #kv == 0 then
			return nil, translate("Private key is missing - certificate and key must be configured as a pair")
		end
		if not fs.access(value) then
			return nil, translate("Certificate file not found")
		end
	end
	return value
end

key.validate = function(self, value, section)
	if value and #value > 0 then
		local cv = cert:formvalue(section)
		if not cv or #cv == 0 then
			return nil, translate("Certificate is missing - certificate and key must be configured as a pair")
		end
		if not fs.access(value) then
			return nil, translate("Key file not found")
		end
	end
	return value
end

o = s:option(DummyValue, "_tls_status", translate("TLS status"))
o.rawhtml = true
o.cfgvalue = function(self, section)
	local c = cert:cfgvalue(section)
	local k = key:cfgvalue(section)
	if c and #c > 0 and k and #k > 0 then
		if fs.access(c) and fs.access(k) then
			return '<font color="green"><b>' .. translate("Ready") .. '</b></font>'
		else
			return '<font color="red"><b>' .. translate("File missing") .. '</b></font>'
		end
	end
	return '<font color="gray">' .. translate("Not configured") .. '</font>'
end

s = mp:section(TypedSection, "redirect", translate("Redirect Configuration"))
s.addremove = true
s.anonymous = true
s.template = "cbi/tblsection"
s.sortable = true
s.description = translate("Typical scenarios: 1) CGNAT, only public IPv6 - forward a public v6 port to an internal IPv4 service (cross-family). 2) Moving target - use a domain name as destination, re-resolved on every connection. 3) TLS frontend - terminate TLS on the router, backend stays plain.")

enabled = s:option(Flag, "enabled", translate("Enabled"))
enabled.rmempty = false

name = s:option(Value, "name", translate("Name"))
name.optional = false
name.rmempty = false

proto = s:option(ListValue, "proto", translate("Transport Protocol"))
proto.default = "tcp6"
proto:value("tcp4", "TCP/IPv4")
proto:value("udp4", "UDP/IPv4")
proto:value("tcp6", "TCP/IPv6")
proto:value("udp6", "UDP/IPv6")
proto:value("tls4", "TLS/IPv4")
proto:value("tls6", "TLS/IPv6")

src_dport = s:option(Value, "src_dport", translate("Source Port"))
src_dport.datatype = "port"
src_dport.optional = false
src_dport.rmempty = false

dest_ip = s:option(Value, "dest_ip", translate("Destination Address"))
dest_ip.optional = false
dest_ip.rmempty = false

dest_port = s:option(Value, "dest_port", translate("Destination Port"))
dest_port.datatype = "port"
dest_port.optional = false
dest_port.rmempty = false

ipv6only = s:option(Flag, "ipv6only", translate("IPv6 only"))
ipv6only.default = ipv6only.enabled
ipv6only.rmempty = false

o = s:option(DummyValue, "rs", translate("Status"))
o.default = "…"

return mp
