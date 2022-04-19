module("luci.controller.netkeeper-interception", package.seeall)

function index()
	if not nixio.fs.access("/etc/config/netkeeper-interception") then
		return
	end
	local page
	page = entry({"admin", "services", "netkeeper-interception"}, cbi("netkeeper-interception"), _("Netkeeper Interception"), 100)
	page.dependent = true
	entry({"admin","services","netkeeper-interception","status"},call("act_status")).leaf=true
	entry({"admin","services","netkeeper-interception","authreq"},call("act_authreq")).leaf=true
end

function act_status()
	local e={}
	if nixio.fs.access("/var/run/netkeeper-interception.pid") then
		e.running=luci.sys.call("pgrep pppoe-server|grep $(cat /var/run/netkeeper-interception.pid) -q")==0
	else
		e.running=0
	end
	luci.http.prepare_content("application/json")
	luci.http.write_json(e)
end

function string.tohex(str)
    return (str:gsub('.', function (c)
        return string.format('%02X ', string.byte(c))
    end))
end

function act_authreq()
	local e={}
	if nixio.fs.access("/var/Last_AuthReq") then
		local r=nixio.fs.readfile("/var/Last_AuthReq")
		r=string.tohex(r)
		e.authreq=r
	else
		e.authreq=""
	end
	luci.http.prepare_content("application/json")
	luci.http.write_json(e)
end