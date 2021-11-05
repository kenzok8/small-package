o = Map("koolproxy")

t = o:section(TypedSection,"rss_rule", translate("GodProxy 规则订阅"))
t.description = translate("请确保订阅规则的兼容性")
t.anonymous = true
t.addremove = true
t.sortable = true
t.template = "cbi/tblsection"
t.extedit = luci.dispatcher.build_url("admin/services/koolproxy/rss_rule/%s")

e = t:option(Flag, "load", translate("启用"))
e.rmempty = false
e.default = 0

e = t:option(DummyValue, "name", translate("规则名称"))
function e.cfgvalue(...)
	return Value.cfgvalue(...) or translate("None")
end

e = t:option(DummyValue,"url", translate("规则地址"))
function e.cfgvalue(...)
	return Value.cfgvalue(...) or translate("None")
end

t.create = function(...)
	local sid = TypedSection.create(...)
	if sid then
		luci.http.redirect(t.extedit % sid)
		return
	end
end

e = t:option(DummyValue, "time", translate("更新时间"))

function Download()
	local t,e
	t = nixio.open("/tmp/upload/koolproxyca.tar.gz","r")
	luci.http.header('Content-Disposition','attachment; filename="koolproxyCA.tar.gz"')
	luci.http.prepare_content("application/octet-stream")
	while true do
		e = t:read(nixio.const.buffersize)
		if(not e)or(#e==0)then
			break
		else
			luci.http.write(e)
		end
	end
	t:close()
	luci.http.close()
end

local t,e
t = "/tmp/upload/"
nixio.fs.mkdir(t)
luci.http.setfilehandler(
function(o,a,i)
	if not e then
		if not o then return end
		e = nixio.open(t..o.file,"w")
		if not e then
			return
		end
	end
	if a and e then
		e:write(a)
	end
	if i and e then
		e:close()
		e = nil
		luci.sys.call("/usr/share/koolproxy/camanagement restore 2>&1 >/dev/null")
	end
end)

return o
