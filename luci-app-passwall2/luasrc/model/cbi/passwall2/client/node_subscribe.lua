local api = require "luci.passwall2.api"
local appname = api.appname
local uci = api.uci
local has_ss = api.is_finded("ss-redir")
local has_ss_rust = api.is_finded("sslocal")
local has_singbox = api.finded_com("sing-box")
local has_xray = api.finded_com("xray")
local has_hysteria2 = api.finded_com("hysteria")
local ss_type = {}
local trojan_type = {}
local vmess_type = {}
local vless_type = {}
local hysteria2_type = {}
if has_ss then
	local s = "shadowsocks-libev"
	table.insert(ss_type, s)
end
if has_ss_rust then
	local s = "shadowsocks-rust"
	table.insert(ss_type, s)
end
if has_singbox then
	local s = "sing-box"
	table.insert(trojan_type, s)
	table.insert(ss_type, s)
	table.insert(vmess_type, s)
	table.insert(vless_type, s)
	table.insert(hysteria2_type, s)
end
if has_xray then
	local s = "xray"
	table.insert(trojan_type, s)
	table.insert(ss_type, s)
	table.insert(vmess_type, s)
	table.insert(vless_type, s)
end
if has_hysteria2 then
	local s = "hysteria2"
	table.insert(hysteria2_type, s)
end

m = Map(appname)
api.set_apply_on_parse(m)

if api.is_js_luci() then
	m.on_after_apply = function(self)
		uci:foreach(appname, "subscribe_list", function(e)
			uci:delete(appname, e[".name"], "md5")
		end)
		uci:commit(appname)
	end
end

m.render = function(self, ...)
	Map.render(self, ...)
	api.optimize_cbi_ui()
end

-- [[ Subscribe Settings ]]--
s = m:section(TypedSection, "global_subscribe", "")
s.anonymous = true

function m.commit_handler(self)
	if self.no_commit then
		return
	end
	self.uci:foreach(appname, "subscribe_list", function(e)
		self:del(e[".name"], "md5")
	end)
end

o = s:option(ListValue, "filter_keyword_mode", translate("Filter keyword Mode"))
o:value("0", translate("Close"))
o:value("1", translate("Discard List"))
o:value("2", translate("Keep List"))
o:value("3", translate("Discard List,But Keep List First"))
o:value("4", translate("Keep List,But Discard List First"))

o = s:option(DynamicList, "filter_discard_list", translate("Discard List"))

o = s:option(DynamicList, "filter_keep_list", translate("Keep List"))

if #ss_type > 0 then
	o = s:option(ListValue, "ss_type", translatef("%s Node Use Type", "Shadowsocks"))
	for key, value in pairs(ss_type) do
		o:value(value)
	end
end

if #trojan_type > 0 then
	o = s:option(ListValue, "trojan_type", translatef("%s Node Use Type", "Trojan"))
	for key, value in pairs(trojan_type) do
		o:value(value)
	end
end

if #vmess_type > 0 then
	o = s:option(ListValue, "vmess_type", translatef("%s Node Use Type", "VMess"))
	for key, value in pairs(vmess_type) do
		o:value(value)
	end
	if has_xray then
		o.default = "xray"
	end
end

if #vless_type > 0 then
	o = s:option(ListValue, "vless_type", translatef("%s Node Use Type", "VLESS"))
	for key, value in pairs(vless_type) do
		o:value(value)
	end
	if has_xray then
		o.default = "xray"
	end
end

if #hysteria2_type > 0 then
	o = s:option(ListValue, "hysteria2_type", translatef("%s Node Use Type", "Hysteria2"))
	for key, value in pairs(hysteria2_type) do
		o:value(value)
	end
	if has_hysteria2 then
		o.default = "hysteria2"
	end
end

o = s:option(ListValue, "domain_strategy", "Sing-box " .. translate("Domain Strategy"), translate("Set the default domain resolution strategy for the sing-box node."))
o.default = ""
o:value("", translate("Auto"))
o:value("prefer_ipv4", translate("Prefer IPv4"))
o:value("prefer_ipv6", translate("Prefer IPv6"))
o:value("ipv4_only", translate("IPv4 Only"))
o:value("ipv6_only", translate("IPv6 Only"))

---- Subscribe Delete All
o = s:option(DummyValue, "_stop", translate("Delete All Subscribe Node"))
o.rawhtml = true
function o.cfgvalue(self, section)
	return string.format(
		[[<button type="button" class="cbi-button cbi-button-remove" onclick="return confirmDeleteAll()">%s</button>]],
		translate("Delete All Subscribe Node"))
end

o = s:option(DummyValue, "_update", translate("Manual subscription All"))
o.rawhtml = true
o.cfgvalue = function(self, section)
    return string.format([[
        <button type="button" class="cbi-button cbi-button-apply" onclick="ManualSubscribeAll()">%s</button>]],
	 translate("Manual subscription All"))
end

s = m:section(TypedSection, "subscribe_list", "", "<font color='red'>" .. translate("When adding a new subscription, please save and apply before manually subscribing. If you only change the subscription URL, you can subscribe manually, and the system will save it automatically.") .. "</font>")
s.addremove = true
s.anonymous = true
s.sortable = true
s.template = "cbi/tblsection"
s.extedit = api.url("node_subscribe_config", "%s")
function s.create(e, t)
	local id = TypedSection.create(e, t)
	luci.http.redirect(e.extedit:format(id))
end

o = s:option(Value, "remark", translate("Remarks"))
o.width = "auto"
o.rmempty = false
o.validate = function(self, value, t)
	if value then
		local count = 0
		m.uci:foreach(appname, "subscribe_list", function(e)
			if e[".name"] ~= t and e["remark"] == value then
				count = count + 1
			end
		end)
		if count > 0 then
			return nil, translate("This remark already exists, please change a new remark.")
		end
		return value
	end
end

o = s:option(DummyValue, "_node_count", translate("Subscribe Info"))
o.rawhtml = true
o.cfgvalue = function(t, n)
	local remark = m:get(n, "remark") or ""
	local str = m:get(n, "rem_traffic") or ""
	local expired_date = m:get(n, "expired_date") or ""
	if expired_date ~= "" then
		str = str .. (str ~= "" and "/" or "") .. expired_date
	end
	str = str ~= "" and "<br>" .. str or ""
	local num = 0
	m.uci:foreach(appname, "nodes", function(s)
		if s["add_from"] ~= "" and s["add_from"] == remark then
			num = num + 1
		end
	end)
	return string.format("%s%s", translate("Node num") .. ": " .. num, str)
end

o = s:option(Value, "url", translate("Subscribe URL"))
o.width = "auto"
o.rmempty = false

o = s:option(DummyValue, "_remove", translate("Delete the subscribed node"))
o.rawhtml = true
function o.cfgvalue(self, section)
	local remark = m:get(section, "remark") or ""
	return string.format(
		[[<button type="button" class="cbi-button cbi-button-remove" onclick="return confirmDeleteNode('%s')">%s</button>]],
		remark, translate("Delete the subscribed node"))
end

o = s:option(DummyValue, "_update", translate("Manual subscription"))
o.rawhtml = true
o.cfgvalue = function(self, section)
    return string.format([[
        <button type="button" class="cbi-button cbi-button-apply" onclick="ManualSubscribe('%s')">%s</button>]],
	section, translate("Manual subscription"))
end

s:append(Template(appname .. "/node_subscribe/js"))

return m
