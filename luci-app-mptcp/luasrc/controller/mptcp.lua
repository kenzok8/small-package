-- Copyright 2008 Steven Barth <steven@midlink.org>
-- Copyright 2011 Jo-Philipp Wich <jow@openwrt.org>
-- Copyright 2018-2023 Ycarus (Yannick Chabanois) <ycarus@zugaina.org>
-- Licensed to the public under the Apache License 2.0.

module("luci.controller.mptcp", package.seeall)


function index()
	local uname = nixio.uname()
	entry({"admin", "network", "mptcp"}, alias("admin", "network", "mptcp", "settings"), _("MPTCP"))
	if uname ~= nil and uname.release:sub(1,1) == "5" then
		entry({"admin", "network", "mptcp", "settings"}, cbi("mptcp"), _("Settings"),2).leaf = true
	else
		entry({"admin", "network", "mptcp", "settings"}, view("mptcp/mptcp"), _("Settings"),2).leaf = true
	end
	entry({"admin", "network", "mptcp", "bandwidth"}, template("mptcp/multipath"), _("Bandwidth"), 3).leaf = true
	entry({"admin", "network", "mptcp", "multipath_bandwidth"}, call("multipath_bandwidth")).leaf = true
	entry({"admin", "network", "mptcp", "interface_bandwidth"}, call("interface_bandwidth")).leaf = true
	if uname ~= nil and uname.release:sub(1,1) == "5" then
		entry({"admin", "network", "mptcp", "mptcp_check"}, template("mptcp/mptcp_check"), _("MPTCP Support Check"), 4).leaf = true
	end
	entry({"admin", "network", "mptcp", "mptcp_check_trace"}, post("mptcp_check_trace")).leaf = true
	entry({"admin", "network", "mptcp", "mptcp_fullmesh"}, template("mptcp/mptcp_fullmesh"), _("MPTCP Fullmesh"), 5).leaf = true
	entry({"admin", "network", "mptcp", "mptcp_fullmesh_data"}, post("mptcp_fullmesh_data")).leaf = true
--	entry({"admin", "network", "mptcp", "mptcp_connections"}, template("mptcp/mptcp_connections"), _("Established connections"), 6).leaf = true
	entry({"admin", "network", "mptcp", "mptcp_connections_data"}, post("mptcp_connections_data")).leaf = true
	entry({"admin", "network", "mptcp", "mptcp_monitor"}, template("mptcp/mptcp_monitor"), _("MPTCP monitoring"), 6).leaf = true
	entry({"admin", "network", "mptcp", "mptcp_monitor_data"}, post("mptcp_monitor_data")).leaf = true
end

function interface_bandwidth(iface)
	luci.http.prepare_content("application/json")
	local bwc = io.popen("luci-bwc -i %q 2>/dev/null" % iface)
	if bwc then
		luci.http.write("[")
		while true do
			local ln = bwc:read("*l")
			if not ln then break end
			luci.http.write(ln)
		end
		luci.http.write("]")
		bwc:close()
	end
end


function string.split(input, delimiter)
	input = tostring(input)
	delimiter = tostring(delimiter)
	if (delimiter=='') then return false end
	local pos,arr = 0, {}
	-- for each divider found
	for st,sp in function() return string.find(input, delimiter, pos, true) end do
		table.insert(arr, string.sub(input, pos, st - 1))
		pos = sp + 1
	end
	table.insert(arr, string.sub(input, pos))
	return arr
end

function multipath_bandwidth()
	local result = { };
	local uci = luci.model.uci.cursor()
	local res={ };
	local str="";
	local tmpstr="";

	uci:foreach("network", "interface", function(s)
		local intname = s[".name"]
		local label = s["label"]
		local dev = get_device(intname)
		if dev == "" then
			dev = get_device(s["device"])
			if dev == "" then
				dev = get_device(s["ifname"])
			end
		end
		local multipath = s["multipath"] or ""
		if dev ~= "lo" and dev ~= "" then
			if multipath == "" then
				multipath = uci:get("openmptcprouter", intname, "multipath") or ""
			end
			if multipath == "" then
				multipath = "off"
			end
			if multipath == "on" or multipath == "master" or multipath == "backup" or multipath == "handover" then
				local bwc = luci.sys.exec("luci-bwc -i %q 2>/dev/null" % dev) or ""
				if bwc ~= nil then
					--result[dev] = "[" .. string.gsub(bwc, '[\r\n]', '') .. "]"
					if label ~= nil then
						result[intname .. " (" .. label .. ")" ] = "[" .. string.gsub(bwc, '[\r\n]', '') .. "]"
					else
						result[intname] = "[" .. string.gsub(bwc, '[\r\n]', '') .. "]"
					end
				else
					if label ~= nil then
						result[intname .. " (" .. label .. ")" ] = "[]"
					else
						result[intname] = "[]"
					end
				end
			end
		end
	end)

	res["total"]={ };
	for i=1,60 do
		res["total"][i]={}
		for j=1,5 do
			res["total"][i][j]=0
		end
	end

	for key,value in pairs(result) do
		res[key]={}
		value=(string.gsub(value, "^%[%[", ""))
		value=(string.gsub(value, "%]%]", ""))
		local temp1 = string.split(value, "],")
		if temp1[2] ~= nil then
			res[key][1]=temp1[1]
			for i=2,60 do
				res[key][i]={}
				if temp1[i] ~= nil then
					res[key][i]=(string.gsub(temp1[i], "%[", " "))
				end
			end
			for i=1,60 do
				res[key][i] = string.split(res[key][i], ",")
				for j=1,5 do
					res[key][i][j]= tonumber(res[key][i][j])
					res["total"][i][j]= tonumber(res["total"][i][j])
					if j ==1 then
						if res[key][i][j] ~= nil and res[key][i][j] > 0 then
							res["total"][i][j] = res[key][i][j]
						else
							res["total"][i][j] = 0
						end
					else
						if res[key][i][j] ~= nil and res[key][i][j] > 0 then
							res["total"][i][j] = res["total"][i][j] + res[key][i][j]
						end
					end
				end
			end
		end
	end
	for i=1,60 do
		for j=1,5 do
			if "number"== type(res["total"][i][j]) then
				res["total"][i][j]= tostring(res["total"][i][j])
			end
		end
	end
	for i=1,60 do
		if i == 60 then
			tmpstr = "["..table.concat(res["total"][i], ",")
		else
			tmpstr = "["..table.concat(res["total"][i], ",").."],"
		end
		str  = str..tmpstr
	end
	str  = "["..str.."]]"
	result["total"]=str

	luci.http.prepare_content("application/json")
	luci.http.write_json(result)
end

function get_device(interface)
	local dump = require("luci.util").ubus("network.interface.%s" % interface, "status", {})
	if dump then
		return dump['l3_device']
	else
		return ""
	end
end

function mptcp_check_trace(iface)
	luci.http.prepare_content("text/plain")
	local tracebox
	local uci    = require "luci.model.uci".cursor()
	local interface = get_device(iface)
	local server = uci:get("shadowsocks-libev", "sss0", "server") or ""
	if server == "" then return end
	if interface == "" then
		tracebox = io.popen("tracebox -s /usr/share/tracebox/omr-mptcp-trace.lua " .. server)
	else
		tracebox = io.popen("tracebox -s /usr/share/tracebox/omr-mptcp-trace.lua -i " .. interface .. " " .. server)
	end
	if tracebox then
		while true do
			local ln = tracebox:read("*l")
			if not ln then break end
			luci.http.write(ln)
			luci.http.write("\n")
		end
	end
	return
end

function mptcp_fullmesh_data()
	luci.http.prepare_content("text/plain")
	local fullmesh
	fullmesh = io.popen("multipath -f")
	if fullmesh then
		while true do
			local ln = fullmesh:read("*l")
			if not ln then break end
			luci.http.write(ln)
			luci.http.write("\n")
		end
	end
	return
end

function mptcp_monitor_data()
	luci.http.prepare_content("text/plain")
	local fullmesh
	fullmesh = io.popen("multipath -m")
	if fullmesh:read() ~= nil then
		while true do
			local ln = fullmesh:read("*l")
			if not ln then break end
			luci.http.write(ln)
			luci.http.write("\n")
		end
	end
	return
end

function mptcp_connections_data()
	luci.http.prepare_content("text/plain")
	local connections
	connections = io.popen("multipath -c")
	if connections:read() ~= nil then
		while true do
			local ln = connections:read("*l")
			if not ln then break end
			luci.http.write(ln)
			luci.http.write("\n")
		end
	end
	return
end
