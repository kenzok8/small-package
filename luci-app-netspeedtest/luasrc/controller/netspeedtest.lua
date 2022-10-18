-- Copyright (C) 2020-2022  sirpdboy  <herboy2008@gmail.com> https://github.com/sirpdboy/netspeedtest

module("luci.controller.netspeedtest", package.seeall)
local fs=require"nixio.fs"
function index()
	entry({"admin","network","netspeedtest"},alias("admin", "network", "netspeedtest", "speedtestweb"),_("Net Speedtest"), 90).dependent = true
	entry({"admin","network","netspeedtest","speedtestweb"},cbi("netspeedtest/speedtestweb"),_("Lan Speedtest Web"),20).leaf = true
	entry({"admin","network","netspeedtest","speedtestiperf3"},cbi("netspeedtest/speedtestiperf3", {hideapplybtn=true, hidesavebtn=true, hideresetbtn=true}),_("Lan Speedtest Iperf3"),30).leaf = true
        entry({"admin","network","netspeedtest","speedtestwan"},cbi("netspeedtest/speedtestwan", {hideapplybtn=true, hidesavebtn=true, hideresetbtn=true}),_("Wan Speedtest"), 40).leaf = true

	entry({"admin", "network", "netspeedtest", "checknet"}, call("check_net"))
	
	entry({"admin", "network", "speedtestweb_status"}, call("speedtestweb_status"))
	entry({"admin", "network", "iperf3_status"}, call("iperf3_status"))

	entry({"admin", "network","test_iperf0"}, post("test_iperf0"), nil).leaf = true
	entry({"admin", "network","test_iperf1"}, post("test_iperf1"), nil).leaf = true
	
	--entry({"admin","network","netspeedtest", "wanrun"}, post("wanrun"), nil).leaf = true
	entry({"admin","network","netspeedtest", "wanrun"}, call("wanrun"))
	entry({"admin", "network", "netspeedtest", "realtime_log"}, call("get_log")) 
	entry({"admin", "network", "netspeedtest", "dellog"},call("dellog"))
end

function speedtestweb_status()
	local e={}
	e.run=luci.sys.call("pgrep speedtest-web >/dev/null")==0
	luci.http.prepare_content("application/json")
	luci.http.write_json(e)
end

function iperf3_status()
	local e={}
	e.run=luci.sys.call("pgrep iperf3 >/dev/null")==0
	luci.http.prepare_content("application/json")
	luci.http.write_json(e)
end

function testout(cmd, addr)
		luci.http.prepare_content("text/plain")
		local util = io.popen(cmd)
		if util then
			while true do
				local ln = util:read("*l")
				if not ln then break end
				luci.http.write(ln)
				luci.http.write("\n")
			end
			util:close()
		end

end

function test_iperf0(addr)
       luci.sys.call("pgrep -f unblockneteasemusic | xargs kill -9 >/dev/null 2>&1 ")
       luci.sys.call("/etc/init.d/unblockneteasemusic stop ")
       luci.sys.call("/etc/init.d/unblockmusic stop ")
       testout("iperf3 -s ", addr)
end

function test_iperf1(addr)
	luci.sys.call("pgrep -f iperf3 | xargs kill -9 >/dev/null 2>&1 ")
	luci.sys.call("/etc/init.d/unblockneteasemusic restart")
	luci.sys.call("/etc/init.d/unblockmusic restart")
end

function get_log()
    local e = {}
    e.running = luci.sys.call("busybox ps -w | grep netspeedtest | grep -v grep >/dev/null") == 0
    e.log = fs.readfile("/var/log/netspeedtest.log") or ""
	luci.http.prepare_content("application/json")
	luci.http.write_json(e)
end

function dellog()
	fs.writefile("/var/log/netspeedtest.log","")
	http.prepare_content("application/json")
	http.write('')
end

function wanrun()
    testout("/etc/init.d/netspeedtest nstest ")
end

