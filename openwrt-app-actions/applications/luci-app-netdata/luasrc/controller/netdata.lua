module("luci.controller.netdata", package.seeall)

function index()
	if not (luci.sys.call("pidof netdata > /dev/null") == 0) then
		return
	end
	local fs = require "nixio.fs"

	entry({"admin","status","netdata"},template("netdata"),_("NetData"),10).leaf=true


end