f = SimpleForm("easytier")
f.reset = false
f.submit = false
f:append(Template("easytier/easytier_log"))
return f
