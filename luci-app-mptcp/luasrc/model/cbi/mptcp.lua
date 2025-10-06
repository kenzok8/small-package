local net = require "luci.model.network".init()
local sys = require "luci.sys"
local ifaces = sys.net:devices()
local m, s, o
local uname = nixio.uname()

m = Map("network", translate("MPTCP"), translate("Networks MPTCP settings."))

local unameinfo = nixio.uname() or { }

s = m:section(TypedSection, "globals")
o = s:option(ListValue, "multipath", translate("Multipath TCP"))
o:value("enable", translate("enable"))
o:value("disable", translate("disable"))
o = s:option(ListValue, "mptcp_checksum", translate("Multipath TCP checksum"))
o:value(1, translate("enable"))
o:value(0, translate("disable"))

if uname.release:sub(1,4) ~= "5.15" and uname.release:sub(1,1) ~= "6" then
    o = s:option(ListValue, "mptcp_debug", translate("Multipath Debug"))
    o:value(1, translate("enable"))
    o:value(0, translate("disable"))
end

o = s:option(ListValue, "mptcp_path_manager", translate("Multipath TCP path-manager"), translate("Default is fullmesh"))
o:value("default", translate("default"))
o:value("fullmesh", "fullmesh")
--if tonumber(uname.release:sub(1,4)) <= 5.15 then
if uname.release:sub(1,4) ~= "5.15" and uname.release:sub(1,1) ~= "6" then
    o:value("ndiffports", "ndiffports")
    o:value("binder", "binder")
    if uname.release:sub(1,4) ~= "4.14" then
	o:value("netlink", translate("Netlink"))
    end
end
o = s:option(ListValue, "mptcp_scheduler", translate("Multipath TCP scheduler"))
o:value("default", translate("default"))
-- if tonumber(uname.release:sub(1,4)) <= 5.15 then
if uname.release:sub(1,4) ~= "5.15" and uname.release:sub(1,1) ~= "6" then
    o:value("roundrobin", "round-robin")
    o:value("redundant", "redundant")
    if uname.release:sub(1,4) ~= "4.14" then
	o:value("blest", "BLEST")
	o:value("ecf", "ECF")
    end
end
if uname.release:sub(1,3) == "6.6" then
    for dir in io.popen([[cd /usr/share/bpf/scheduler && ls -1 *.o | sed -e 's/.o//g' -e 's/mptcp_//g']]):lines() do 
	o:value(dir, dir)
    end
    -- bpf_burst => same as the default scheduler
    -- bpf_red => sends all packets redundantly on all available subflows
    -- bpf_first => always picks the first subflow to send data
    -- bpf_rr => always picks the next available subflow to send data (round-robin)
end

-- if tonumber(uname.release:sub(1,4)) <= 5.15 then
if uname.release:sub(1,4) ~= "5.15" and uname.release:sub(1,1) ~= "6" then
    o = s:option(Value, "mptcp_syn_retries", translate("Multipath TCP SYN retries"))
    o.datatype = "uinteger"
    o.rmempty = false
end
-- if tonumber(uname.release:sub(1,4)) <= 5.15 then
if uname.release:sub(1,4) ~= "5.15" and uname.release:sub(1,1) ~= "6" then
    o = s:option(ListValue, "mptcp_version", translate("Multipath TCP version"))
    o:value(0, translate("0"))
    o:value(1, translate("1"))
    o.default = 0
end
o = s:option(ListValue, "congestion", translate("Congestion Control"),translate("Default is bbr"))
local availablecong = sys.exec("sysctl -n net.ipv4.tcp_available_congestion_control | xargs -n1 | sort | xargs")
for cong in string.gmatch(availablecong, "[^%s]+") do
	if cong == "bbr" and string.match(availablecong, "bbr1") then
		o:value(cong, "bbr3")
	else
		o:value(cong, cong)
	end
end

-- if tonumber(uname.release:sub(1,4)) >= 5.15 then
if uname.release:sub(1,4) == "5.15" or uname.release:sub(1,1) == "6" then
    if uname.release:sub(1,1) == "6" then
	-- Only available since 5.19
        o = s:option(ListValue, "mptcp_pm_type", translate("Path Manager type"))
        o:value(0, translate("In-kernel path manager"))
        o:value(1, translate("Userspace path manager"))
        o.default = 0
    end

    o = s:option(ListValue, "mptcp_disable_initial_config", translate("Initial MPTCP configuration"))
    o:depends("mptcp_pm_type",1)
    o:value("0", translate("enable"))
    o:value("1", translate("disable"))
    o.default = "0"

    o = s:option(ListValue, "mptcp_force_multipath", translate("Force Multipath configuration"))
    o:depends("mptcp_pm_type",1)
    o:value("1", translate("enable"))
    o:value("0", translate("disable"))
    o.default = "1"

    o = s:option(ListValue, "mptcpd_enable", translate("Enable MPTCPd"))
    o:depends("mptcp_pm_type",1)
    o:value("enable", translate("enable"))
    o:value("disable", translate("disable"))
    o.default = "disable"

    o = s:option(DynamicList, "mptcpd_path_manager", translate("MPTCPd path managers"))
    for dir in io.popen([[cd /usr/lib/mptcpd && ls -1 *.so | sed 's/.so//g']]):lines() do 
	o:value(dir, dir)
    end
    o:depends("mptcp_pm_type",1)

    o = s:option(DynamicList, "mptcpd_plugins", translate("MPTCPd plugins"))
    for dir in io.popen([[cd /usr/lib/mptcpd && ls -1 *.so | sed 's/.so//g']]):lines() do 
	o:value(dir, dir)
    end
    o:depends("mptcp_pm_type",1)

    o = s:option(DynamicList, "mptcpd_addr_flags", translate("MPTCPd Address annoucement flags"))
    o:value("subflow","subflow")
    o:value("signal","signal")
    o:value("backup","backup")
    o:value("fullmesh","fullmesh")
    o:depends("mptcp_pm_type",1)

    o = s:option(DynamicList, "mptcpd_notify_flags", translate("MPTCPd Address notification flags"))
    o:value("existing","existing")
    o:value("skip_link_local","skip_link_local")
    o:value("skip_loopback","skip_loopback")
    o:depends("mptcp_pm_type",1)

    o = s:option(Value, "mptcp_subflows", translate("Max subflows"),translate("specifies the maximum number of additional subflows allowed for each MPTCP connection"))
    o.datatype = "uinteger"
    o.rmempty = false
    o.default = 3

    o = s:option(Value, "mptcp_stale_loss_cnt", translate("Retranmission intervals"),translate("The number of MPTCP-level retransmission intervals with no traffic and pending outstanding data on a given subflow required to declare it stale. A low stale_loss_cnt value allows for fast active-backup switch-over, an high value maximize links utilization on edge scenarios e.g. lossy link with high BER or peer pausing the data processing."))
    o.datatype = "uinteger"
    o.rmempty = false
    o.default = 4

    o = s:option(Value, "mptcp_add_addr_accepted", translate("Max add address"),translate("specifies the maximum number of ADD_ADDR (add address) suboptions accepted for each MPTCP connection"))
    o.datatype = "uinteger"
    o.rmempty = false
    o.default = 1

    o = s:option(Value, "mptcp_add_addr_timeout", translate("Control message timeout"),translate("Set the timeout after which an ADD_ADDR (add address) control message will be resent to an MPTCP peer that has not acknowledged a previous ADD_ADDR message."))
    o.datatype = "uinteger"
    o.rmempty = false
    o.default = 120

else
    o = s:option(Value, "mptcp_fullmesh_num_subflows", translate("Fullmesh subflows for each pair of IP addresses"))
    o.datatype = "uinteger"
    o.rmempty = false
    o.default = 1
    --o:depends("mptcp_path_manager","fullmesh")

    o = s:option(ListValue, "mptcp_fullmesh_create_on_err", translate("Re-create fullmesh subflows after a timeout"))
    o:value(1, translate("enable"))
    o:value(0, translate("disable"))
    --o:depends("mptcp_path_manager","fullmesh")

    o = s:option(Value, "mptcp_ndiffports_num_subflows", translate("ndiffports subflows number"))
    o.datatype = "uinteger"
    o.rmempty = false
    o.default = 1
    --o:depends("mptcp_path_manager","ndiffports")

    o = s:option(ListValue, "mptcp_rr_cwnd_limited", translate("Fill the congestion window on all subflows for round robin"))
    o:value("Y", translate("enable"))
    o:value("N", translate("disable"))
    o.default = "Y"
    --o:depends("mptcp_scheduler","roundrobin")

    o = s:option(Value, "mptcp_rr_num_segments", translate("Consecutive segments that should be sent for round robin"))
    o.datatype = "uinteger"
    o.rmempty = false
    o.default = 1
    --o:depends("mptcp_scheduler","roundrobin")
end

s = m:section(TypedSection, "interface", translate("Interfaces Settings"))
function s.filter(self, section)
    return not section:match("^oip.*") and not section:match("^lo.*") and section ~= "omrvpn" and section ~= "omr6in4"
end
o = s:option(ListValue, "multipath", translate("Multipath TCP"), translate("One interface must be set as master"))
o:value("on", translate("enabled"))
o:value("off", translate("disabled"))
o:value("master", translate("master"))
o:value("backup", translate("backup"))
--o:value("handover", translate("handover"))
o.default = "off"

function m.on_after_apply(self,map)
    sys.call('/etc/init.d/mptcp reload')
end

return m
