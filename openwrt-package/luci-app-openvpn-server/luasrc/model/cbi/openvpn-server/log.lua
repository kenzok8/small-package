f = SimpleForm("luci-app-openvpn-server")
f.reset = false
f.submit = false
f:append(Template("openvpn-server/log"))
return f
