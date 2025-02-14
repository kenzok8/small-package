local server_table={}
luci.model.uci.cursor():foreach("bypass","servers",function(s)
	if (s.type=="ss" and not nixio.fs.access("/usr/bin/ss-local")) or (s.type=="ssr" and not nixio.fs.access("/usr/bin/ssr-local")) or s.type=="socks5" or s.type=="tun" then
		return
	end
	if s.alias then
		server_table[s[".name"]]="[%s]:%s"%{string.upper(s.type),s.alias}
	elseif s.server and s.server_port then
		server_table[s[".name"]]="[%s]:%s:%s"%{string.upper(s.type),s.server,s.server_port}
	end
end)

local function is_finded(e)
	return luci.sys.exec('type -t -p "%s"' % e) ~= "" and true or false
end

local key_table={}
for key,_ in pairs(server_table) do
    table.insert(key_table,key)
end

table.sort(key_table)

m=Map("bypass")

s=m:section(TypedSection,"global",translate("Server failsafe auto swith settings"))
s.anonymous=true

o=s:option(Flag,"monitor_enable",translate("Enable Process Deamon"))
o.default=1

o=s:option(Flag,"enable_switch",translate("Enable Auto Switch"))
o.default=1

o=s:option(Value,"switch_time",translate("Switch check cycly(second)"))
o.datatype="uinteger"
o.default=300
o:depends("enable_switch",1)

o=s:option(Value,"switch_timeout",translate("Check timout(second)"))
o.datatype="uinteger"
o.default=5
o:depends("enable_switch",1)

o=s:option(Value,"switch_try_count",translate("Check Try Count"))
o.datatype="uinteger"
o.default=3
o:depends("enable_switch",1)

s=m:section(TypedSection,"socks5_proxy",translate("Global SOCKS5 Proxy Server"))
s.anonymous=true

o=s:option(ListValue,"server",translate("Server"))
o:value("",translate("Disable"))
o:value("same",translate("Same as Global Server"))
for _,key in pairs(key_table) do o:value(key,server_table[key]) end

o=s:option(Value,"local_port",translate("Local Port"))
o.datatype="port"
o.placeholder=1080

-- [[ fragmen Settings ]]--
if is_finded("xray") then
s = m:section(TypedSection, "global_xray_fragment", translate("Xray Fragment Settings"))
s.anonymous = true

o = s:option(Flag, "fragment", translate("Fragment"), translate("TCP fragments, which can deceive the censorship system in some cases, such as bypassing SNI blacklists."))
o.default = 0

o = s:option(ListValue, "fragment_packets", translate("Fragment Packets"), translate("\"1-3\" is for segmentation at TCP layer, applying to the beginning 1 to 3 data writes by the client. \"tlshello\" is for TLS client hello packet fragmentation."))
o.default = "tlshello"
o:value("tlshello", "tlshello")
o:value("1-1", "1-1")
o:value("1-2", "1-2")
o:value("1-3", "1-3")
o:value("1-5", "1-5")
o:depends("fragment", true)

o = s:option(Value, "fragment_length", translate("Fragment Length"), translate("Fragmented packet length (byte)"))
o.default = "100-200"
o:depends("fragment", true)

o = s:option(Value, "fragment_interval", translate("Fragment Interval"), translate("Fragmentation interval (ms)"))
o.default = "10-20"
o:depends("fragment", true)

o = s:option(Flag, "noise", translate("Noise"), translate("UDP noise, Under some circumstances it can bypass some UDP based protocol restrictions."))
o.default = 0

s = m:section(TypedSection, "xray_noise_packets", translate("Xray Noise Packets"))
s.description = translate(
    "<font style='color:red'>" .. translate("To send noise packets, select \"Noise\" in Xray Settings.") .. "</font>" ..
    "<br/><font><b>" .. translate("For specific usage, see:") .. "</b></font>" ..
    "<a href='https://xtls.github.io/config/outbounds/freedom.html' target='_blank'>" ..
    "<font style='color:green'><b>" .. translate("Click to the page") .. "</b></font></a>")
s.template = "cbi/tblsection"
s.sortable = true
s.anonymous = true
s.addremove = true

s.remove = function(self, section)
	for k, v in pairs(self.children) do
		v.rmempty = true
		v.validate = nil
	end
	TypedSection.remove(self, section)
end

o = s:option(Flag, "enabled", translate("Enable"))
o.default = 1
o.rmempty = false

o = s:option(ListValue, "type", translate("Type"))
o.default = "base64"
o:value("rand", "rand")
o:value("str", "str")
o:value("base64", "base64")

o = s:option(Value, "domainStrategy", translate("Domain Strategy"))
o.default = "UseIP"
o:value("AsIs", "AsIs")
o:value("UseIP", "UseIP")
o:value("UseIPv4", "UseIPv4")
o:value("ForceIP", "ForceIP")
o:value("ForceIPv4", "ForceIPv4")
o.rmempty = false

o = s:option(Value, "packet", translate("Packet"))
o.datatype = "minlength(1)"
o.rmempty = false

o = s:option(Value, "delay", translate("Delay (ms)"))
o.datatype = "or(uinteger,portrange)"
o.rmempty = false
end

return m
