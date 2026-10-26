local fs = require "nixio.fs"
local sys = require "luci.sys"

local classic = {}

function classic.installed()
	return not not (
		fs.access("/usr/sbin/kai_bin", "x")
		and fs.access("/usr/sbin/kai_session", "x")
		and fs.access("/etc/init.d/kai", "x")
		and fs.access("/etc/config/kai")
		and fs.access("/usr/share/kai/kai-plugin.json")
	)
end

function classic.status()
	local installed = classic.installed()
	return {
		installed = installed,
		running = installed and sys.call("pidof kai_bin >/dev/null") == 0
	}
end

return classic
