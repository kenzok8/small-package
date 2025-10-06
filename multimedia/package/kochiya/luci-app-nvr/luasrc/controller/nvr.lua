module("luci.controller.nvr",package.seeall)

function index()
	if not nixio.fs.access("/etc/config/nvr") then
		return
	end

	local page = entry({"admin", "services", "nvr"}, cbi("nvr"), _("NVR"),20)
	page.dependent = true
	entry({"admin", "services", "nvr", "status"}, call("nvr_status")).leaf = true
end

function nvr_status()
	local nvrrecord = luci.sys.exec("ps -w | grep nvrrecord | grep -v grep | awk '{print$1}' 2>/dev/null ")
	local pushpid   = luci.sys.exec("ps -w | grep 'f flv rtmp' | grep -v grep | awk '{print$1}' 2>/dev/null ")

	local e = {
		nvrrecord = nvrrecord,
		pushpid = pushpid
	}

	luci.http.prepare_content("application/json")
	luci.http.write_json(e)
end
