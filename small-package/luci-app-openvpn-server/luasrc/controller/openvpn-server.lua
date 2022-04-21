module("luci.controller.openvpn-server",package.seeall)
function index()
	if not nixio.fs.access("/etc/config/openvpn") then
		return
	end
	entry({"admin","vpn"},firstchild(),"VPN",45).dependent=false
	local e=entry({"admin","vpn","openvpn-server"},firstchild(),_("OpenVPN Server"),1)
	e.dependent=false
	e.acl_depends={ "luci-app-openvpn-server" }
	entry({"admin","vpn","openvpn-server","base"},cbi("openvpn-server/base"),_("Base Setting"),1)
	entry({"admin","vpn","openvpn-server","client"},form("openvpn-server/client"),_("Client configuration"),2)
	entry({"admin","vpn","openvpn-server","passwd"},form("openvpn-server/passwd"),_("Username and Password"),3)
	entry({"admin","vpn","openvpn-server","vars"},form("openvpn-server/vars"),_("Certificate option"),4)
	entry({"admin","vpn","openvpn-server","log"},template("openvpn-server/log"),_("Log"),5)
	entry({"admin","vpn","openvpn-server","run"},call("act_status"))
	entry({"admin","vpn","openvpn-server","logdata"},call("act_log"))
end

function act_status()
	local e={}
	e.running=luci.sys.call("pgrep openvpn >/dev/null")==0
	e.cert=luci.sys.call("[ -s /etc/openvpn/ca.crt -a -s /etc/openvpn/client.crt -a -s /etc/openvpn/client.key -a -s /etc/openvpn/dh.pem -a -s /etc/openvpn/server.crt -a -s /etc/openvpn/server.key ] \\\
&& [ -s /etc/openvpn/ta.key -o -z \"$(uci -q get openvpn.myvpn.tls_auth)\" ] || exit 1")==0
	luci.http.prepare_content("application/json")
	luci.http.write_json(e)
end

function act_log()
	local log_data={}
	log_data.syslog=luci.sys.exec("logread | grep 'openvpn(' | sed -e 's/daemon\\S* //' -e 's/([^ ]*\\]//' -e 's/[^ ]* //'")
	luci.http.prepare_content("application/json")
	luci.http.write_json(log_data)
end
