--[[
LuCI - Lua Configuration Interface

Copyright 2015 Cezary Jackiewicz <cezary.jackiewicz@gmail.com>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0
]]--

local map, section, net = ...

local device, apn, service, pincode, username, password
local ipv6, metric, dns


device = section:taboption("general", Value, "device", translate("Modem device"))
device.rmempty = false

local device_suggestions = nixio.fs.glob("/dev/ttyUSB*")
	or nixio.fs.glob("/dev/cdc-wdm*")

if device_suggestions then
	local node
	for node in device_suggestions do
		device:value(node)
	end
end


mode = section:taboption("general", Value, "mode", translate("Service Type"))
mode.default = "auto"
mode:value("preferlte", translate("Prefer LTE"))
mode:value("preferumts", translate("Prefer UMTS"))
mode:value("lte", "LTE")
mode:value("umts", "UMTS/GPRS")
mode:value("gsm", translate("GPRS only"))
mode:value("auto", translate("auto"))


apn = section:taboption("general", Value, "apn", translate("APN"))


pincode = section:taboption("general", Value, "pincode", translate("PIN"))


username = section:taboption("general", Value, "username", translate("PAP/CHAP username"))


password = section:taboption("general", Value, "password", translate("PAP/CHAP password"))
password.password = true


if luci.model.network:has_ipv6() then

	ipv6 = section:taboption("advanced", Flag, "ipv6",
		translate("Enable IPv6 negotiation on the PPP link"))

	ipv6.default = ipv6.disabled
	ipv6.rmempty = false

end


metric = section:taboption("advanced", Value, "metric",
	translate("Use gateway metric"))

metric.placeholder = "0"
metric.datatype    = "uinteger"


dns = section:taboption("advanced", DynamicList, "dns",
	translate("Use custom DNS servers"))

dns.datatype = "ipaddr"
dns.cast     = "string"
