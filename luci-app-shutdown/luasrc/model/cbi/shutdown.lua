m = Map("system", translate("Shutdown / Reboot"),
	translate("Use the buttons below to reboot or shut down the device."))

s = m:section(SimpleSection)
s.template = "shutdown/actions"

return m
