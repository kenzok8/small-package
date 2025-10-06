
module("luci.controller.openvpn-server", package.seeall)

function index()
	if not nixio.fs.access("/etc/config/openvpn") then
		return
	end
	
	entry({"admin", "services", "openvpn-server"},firstchild(), _("OpenVPN Server"), 1).dependent = true

	entry({"admin", "services", "openvpn-server", "general"}, cbi("openvpn-server/openvpn-server"), _("OpenVPN Server"), 1).leaf = true
	entry({"admin", "services", "openvpn-server", "log"},form("openvpn-server/openvpn-server_run_log"), _("Running log"), 2).leaf = true
	entry({"admin", "services", "openvpn-server", "passlog"},form("openvpn-server/openvpn-server_pass_log"), _("Login log"), 3).leaf = true

	entry({"admin", "services", "openvpn-server","status"},call("act_status")).leaf=true
end

function act_status()
  local e={}
  e.running=luci.sys.call("pgrep openvpn >/dev/null")==0
  luci.http.prepare_content("application/json")
  luci.http.write_json(e)
end
