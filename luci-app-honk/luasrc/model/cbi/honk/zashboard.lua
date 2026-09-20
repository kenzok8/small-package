local m

m = SimpleForm("honk")
m.reset = false
m.submit = false

m:append(Template("honk/honk_zashboard"))

return m
