m = Map("frps", "%s - %s" % { translate("Frps"), translate("查看日志文件") })

m:append(Template("frps/frps_log"))

return m
