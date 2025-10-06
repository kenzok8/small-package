module("luci.controller.nginx-ha", package.seeall)

function index()
	entry({"admin", "services", "nginx-ha"}, cbi("nginx-ha"), _("Nginx High Availability"))
end
