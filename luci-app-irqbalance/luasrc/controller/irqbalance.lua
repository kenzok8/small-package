module("luci.controller.irqbalance", package.seeall)

function index()
	if not nixio.fs.access("/etc/config/irqbalance") then return end
	entry({"admin", "system", "irqbalance"}, cbi("irqbalance"), _("Irqbalance"), 9).dependent = true
	entry({"admin", "system", "irqbalance", "status"}, call("irq_status")).leaf = true
--	entry({"admin", "system", "irqbalance", "status"}, call("irq_status"))
end

function irq_status()
	local log_data={}
	log_data.syslog=luci.sys.exec("cat /proc/interrupts |egrep '^[ ][ ]*(CPU|[0-9]*:)'")
	luci.http.prepare_content("application/json")
	luci.http.write_json(log_data)
end

