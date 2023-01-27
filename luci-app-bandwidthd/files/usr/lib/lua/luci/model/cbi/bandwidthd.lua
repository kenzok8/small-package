--Alex<1886090@gmail.com>


local state_msg = "" 


local bandwidthd_on = (luci.sys.call("pidof bandwidthd > /dev/null") == 0)
local router_ip = luci.sys.exec("uci get network.lan.ipaddr")

if bandwidthd_on then	
	state_msg = "<b><font color=\"green\">" .. translate("Running") .. "</font></b>"
else
	state_msg = "<b><font color=\"red\">" .. translate("Not running") .. "</font></b>"
end

m=Map("bandwidthd",translate("Bandwidthd"),translate("通过Bandwidthd可以通过图形界面观察某一网段所有IP的流量状况，并且可以绘制图形，弥补OpenWrt不能分IP观察流量的缺陷<br>状态 - ") .. state_msg .. "<br><br>web观察页面：<a href='http://" .. router_ip .. "/bandwidthd'>http://" .. router_ip .. "/bandwidthd</a>")
s=m:section(TypedSection,"bandwidthd","")
s.addremove=false
s.anonymous=true
	view_enable = s:option(Flag,"enabled",translate("Enable"))
	view_dev = s:option(Value,"dev",translate("dev")) 
	view_subnets = s:option(Value,"subnets",translate("subnets"))
	view_skip_intervals = s:option(Value,"skip_intervals",translate("skip_intervals"))
	view_skip_intervals.datatype="uinteger"
	view_graph_cutoff = s:option(Value,"graph_cutoff",translate("graph_cutoff"))
	view_graph_cutoff.datatype="uinteger"
	view_promiscuous = s:option(Value,"promiscuous",translate("promiscuous"))
	view_output_cdf = s:option(Value,"output_cdf",translate("output_cdf"))
	view_recover_cdf = s:option(Value,"recover_cdf",translate("recover_cdf"))
	view_filter = s:option(Value,"filter",translate("filter"))
	view_graph = s:option(Value,"graph",translate("graph"))
	view_meta_refresh = s:option(Value,"meta_refresh",translate("meta_refresh"))
	view_meta_refresh.datatype="uinteger"
-- ---------------------------------------------------
local apply = luci.http.formvalue("cbi.apply")
if apply then
	os.execute("/etc/init_bandwidthd.sh restart >/dev/null 2>&1 &")
end

return m
