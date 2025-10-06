-- Copyright 2018 Nick Peng (pymumu@gmail.com)

function index()


o = Map("netdate", "<font color='green'>" .. translate("实时监控") .."</font>",     "<font color='purple'>" .. translate( "强大的实时监控数据，需要中文版请点击：【升级中文版】") .."</font>")

t = o:section(TypedSection, "netdate")
t.anonymous = true
t.description = translate(string.format("%s<br /><br />", status))

t:tab("base",translate("Basic Settings"))

e = t:taboption("base", Button, "restart", translate("手动更新"))
e.inputtitle = translate("升级中文版")
e.inputstyle = "reload"
e.write = function()
	luci.sys.call("/usr/share/netdata/netdatacn 2>&1 >/dev/null")
	luci.http.redirect(luci.dispatcher.build_url("admin","status","netdata"))
end

t=o:section(TypedSection,"rss_rules",translate("技术支持"))
t.anonymous = true
t:append(Template("feedback"))
return o
