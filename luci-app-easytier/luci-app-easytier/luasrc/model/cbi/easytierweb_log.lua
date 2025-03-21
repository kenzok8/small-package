f = SimpleForm("easytier")
f.reset = false
f.submit = false
f:append(Template("easytier/easytierweb_log"))
return f
