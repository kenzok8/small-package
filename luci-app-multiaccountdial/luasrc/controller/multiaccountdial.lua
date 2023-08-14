module("luci.controller.multiaccountdial", package.seeall)

function index()
	if not nixio.fs.access("/etc/config/multiaccountdial") then
		return
	end
	entry({"admin", "network", "multiaccountdial"}, cbi("multiaccountdial"), _("多账号多拨"), 103).dependent = true
	entry({"admin", "network", "multiaccountdial_redial"}, call("redial"), nil).leaf = true
	entry({"admin", "network", "add_vwan"}, call("add_vwan"), nil).leaf = true
	entry({"admin", "network", "del_vwan"}, call("del_vwan"), nil).leaf = true
  entry({"admin", "network", "syncdial_status"}, call("act_status")).leaf = true
end

function redial()
	os.execute("killall -9 pppd")
	os.execute("logger -t multiaccountdial redial")
end


function add_vwan()
	os.execute("multi_account_dial add")
	os.execute("logger -t multiaccountdial add_vwan")
end

function del_vwan()
	os.execute("multi_account_dial del")
	os.execute("logger -t multiaccountdial del_vwan")
end

function act_status()
	local e = {}
	local mwan3_status = luci.util.exec("mwan3 status")
	e.num_online = 0
	for _ in mwan3_status:gmatch("tracking is active") do
		e.num_online = e.num_online + 1
	end
	luci.http.prepare_content("application/json")
	luci.http.write_json(e)
end
