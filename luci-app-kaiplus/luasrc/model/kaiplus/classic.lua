local fs = require "nixio.fs"
local sys = require "luci.sys"

local classic = {}

function classic.installed()
	return not not (
		fs.access("/usr/sbin/kai_bin", "x")
		and fs.access("/usr/sbin/kai_session", "x")
		and fs.access("/etc/init.d/kai", "x")
		and fs.access("/etc/config/kai")
	)
end

function classic.status()
	local installed = classic.installed()
	local port = tonumber(require("luci.model.uci").cursor():get_first("kai", "kai", "port") or "8197")
	if not port or port < 1 or port > 65535 or port % 1 ~= 0 then port = nil end
	return {
		installed = installed,
		port = port,
		running = installed and sys.call("pidof kai_bin >/dev/null") == 0
	}
end

return classic
