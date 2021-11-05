o = Map("koolproxy")

t = o:section(TypedSection, "global")
t.title = translate("证书恢复")
t.description = translate("上传恢复已备份的证书，文件名必须为koolproxyCA.tar.gz")
t.anonymous = true

e = t:option(DummyValue,"c1status")
e = t:option(FileUpload,"")
e.template = "koolproxy/caupload"

t = o:section(TypedSection, "global")
t.title = translate("证书备份")
t.description = translate("下载备份的证书")
t.anonymous = true

e = t:option(DummyValue,"",nil)
e.template = "koolproxy/cadvalue"
if nixio.fs.access("/usr/share/koolproxy/data/certs/ca.crt") then
	e = t:option(DummyValue,"c2status")
	e = t:option(Button,"certificate")
	e.inputtitle = translate("下载证书备份")
	e.inputstyle = "reload"
	e.write=function()
		luci.sys.call("/usr/share/koolproxy/camanagement backup 2>&1 >/dev/null")
		Download()
		luci.http.redirect(luci.dispatcher.build_url("admin","services","koolproxy"))
	end
end

return o
