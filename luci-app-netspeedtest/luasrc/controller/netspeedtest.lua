-- Copyright (C) 2020-2022  sirpdboy  <herboy2008@gmail.com> https://github.com/sirpdboy/netspeedtest

module("luci.controller.netspeedtest", package.seeall)
local fs=require"nixio.fs"
local sys  = require "luci.sys"
function index()

    if not nixio.fs.access("/etc/config/netspeedtest") then return end
    local e = entry({"admin","network","netspeedtest"},alias("admin", "network", "netspeedtest", "homebox"),_("Net Speedtest"), 90)
    e.dependent=false
    e.acl_depends = { "luci-app-netspeedtest" }
	entry({"admin","network","netspeedtest","homebox"},cbi("netspeedtest/homebox"),_("Lan homebox Web"),20).leaf = true
	entry({"admin","network","netspeedtest","speedtestiperf3"},cbi("netspeedtest/speedtestiperf3", {hideapplybtn=true, hidesavebtn=true, hideresetbtn=true}),_("Lan Speedtest Iperf3"),30).leaf = true
        entry({"admin","network","netspeedtest","speedtestwan"},cbi("netspeedtest/speedtestwan", {hideapplybtn=true, hidesavebtn=true, hideresetbtn=true}),_("Wan Speedtest"), 40).leaf = true

	entry({"admin", "network", "netspeedtest", "checknet"}, call("check_net"))
	entry({"admin", "network", "iperf3_status"}, call("iperf3_status"))

	entry({"admin", "network","test_iperf0"}, post("test_iperf0"), nil).leaf = true
	entry({"admin", "network","test_iperf1"}, post("test_iperf1"), nil).leaf = true

	entry({"admin","network","netspeedtest", "speedtestrun"}, call("speedtestrun"))
	entry({"admin","network","netspeedtest", "netperfrun"}, call("netperfrun"))

	entry({"admin", "network", "netspeedtest", "realtime_log"}, call("get_log")) 
	entry({"admin", "network", "netspeedtest", "dellog"},call("dellog"))
end


function iperf3_status()
	local e={}
	e.run=sys.call("pgrep iperf3 >/dev/null")==0
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
       sys.call("pgrep -f unblockneteasemusic | xargs kill -9 >/dev/null 2>&1 ")
       sys.call("/etc/init.d/unblockneteasemusic stop ")
       sys.call("/etc/init.d/unblockmusic stop ")
       testout("iperf3 -s ", addr)
end

function test_iperf1(addr)
	sys.call("pgrep -f iperf3 | xargs kill -9 >/dev/null 2>&1 ")
	sys.call("/etc/init.d/unblockneteasemusic restart")
	sys.call("/etc/init.d/unblockmusic restart")
end

function get_log()
    local e = {}
    e.running = sys.call("busybox ps -w | grep netspeedtest | grep -v grep >/dev/null") == 0
    e.log = fs.readfile("/var/log/netspeedtest.log") or ""
	luci.http.prepare_content("application/json")
	luci.http.write_json(e)
end

function dellog()
	fs.writefile("/var/log/netspeedtest.log","")
	http.prepare_content("application/json")
	http.write('')
end

function speedtestrun()
    testout("/etc/init.d/netspeedtest nstest ")
end

function netperfrun()
    testout("sh /usr/bin/netperftest")
end
