-- Run with Lua 5.1: lua luci-app-fakemesh/tests/topology.lua
-- Router IO is mocked; the production RPC implementation is loaded unchanged.
local test_dir = arg[0]:match("^(.*)/[^/]+$") or "."
local f = assert(io.open(test_dir .. "/../root/usr/libexec/rpcd/luci.fakemesh"))
local source = f:read("*a"):gsub("^#![^\n]*\n", "")
f:close()

local function stream(data)
	local position = 1
	local function nextline()
		if position > #data then return nil end
		local ending = data:find("\n", position, true)
		local line = data:sub(position, ending and ending - 1 or #data)
		position = ending and ending + 1 or #data + 1
		return line
	end
	return {
		read = function(_, mode)
			if mode == "*l" then return nextline() end
			local rest = data:sub(position)
			position = #data + 1
			return rest
		end,
		lines = function() return nextline end,
		close = function() end
	}
end

local ac_mac = "02:00:00:00:00:01"
local a_mac, b_mac, c_mac = "02:00:00:00:00:02", "02:00:00:00:00:03", "02:00:00:00:00:04"
local client_mac = "02:00:00:00:00:99"

local function fixture()
	return {
		files = {
			["/sys/class/net/br-lan/address"] = ac_mac,
			["/proc/sys/kernel/hostname"] = "AC",
			["/tmp/sysinfo/model"] = "Test router",
			["/proc/net/arp"] = "",
			["/proc/net/route"] = "",
			["/tmp/hosts/fakemesh"] = ""
		},
		uci = {
			["fakemesh.default.role"] = "controller",
			["fakemesh.default.id"] = "test-mesh",
			["fakemesh.default.band"] = "5g"
		},
		ip = "192.168.1.1", fdb = "", route = "", time = 1000,
		objects = {}, ubus = {}, agents = {}, topologies = {}, calls = {}, requests = {}, processes = {}, json_values = {}
	}
end

local function instantiate(state)
	state.shell_calls = {}
	state.file_reads = {}
	state.connections = 0
	local env = setmetatable({arg = {}}, {__index = _G})
	env.io = {
		open = function(path)
			state.file_reads[path] = (state.file_reads[path] or 0) + 1
			if path == "/proc/uptime" then return stream(tostring(state.time)) end
			if state.files[path] == nil then return nil end
			return stream(state.files[path])
		end,
		popen = function(command)
			state.shell_calls[#state.shell_calls + 1] = command
			local data = ""
			if command:find("uci ", 1, true) then
				local value = state.uci[command:match("get ([%w%._]+)")]
				data = value and (value .. "\n") or ""
			elseif command:find("ip -4 -o addr show br-lan", 1, true) then data = state.ip
			elseif command:find("bridge fdb show", 1, true) then data = state.fdb
			elseif command:find("iw dev meshx1 link", 1, true) then data = state.link or ""
			elseif command:find("ip -4 route show", 1, true) then data = state.route
			end
			return stream(data)
		end
	}
	env.require = function(name)
		if name == "luci.jsonc" then return {parse = function(raw) return state.json_values[raw] end} end
		if name == "nixio" then
			return {
				waitpid = function(pid)
					local process = state.processes[pid]
					if process.killed then process.reaped = true; return pid, "signaled", 9 end
					if state.time >= process.done_at then process.reaped = true; return pid, "exited", process.code or 0 end
					return false
				end,
				kill = function(pid, signal) assert(signal == 9); state.processes[pid].killed = true end,
				poll = function(_, milliseconds) state.time = state.time + milliseconds / 1000 end
			}
		end
		if name == "ubus" then
			return {connect = function()
				state.connections = state.connections + 1
				return {
					call = function(_, object, method, args)
						state.calls[#state.calls + 1] = object .. " " .. method
						if object == "uci" and method == "get" then
							if state.uci_unavailable then return nil end
							local values = {}
							for key, value in pairs(state.uci) do
								local config, section, option = key:match("^([^.]+)%.([^.]+)%.([^.]+)$")
								if config == args.config then
									values[section] = values[section] or {}
									values[section][option] = value
								end
							end
							return {values = values}
						end
						local value = state.ubus[object] and state.ubus[object][method]
						return type(value) == "function" and value(args) or value
					end,
					objects = function() return state.objects end,
					close = function() end
				}
			end}
		end
		error("unexpected module: " .. name)
	end
	local fn = assert(loadstring(source .. [[
return {
 methods = methods,
 fetch_agents = fetch_agents_parallel,
 fetch_controller = fetch_controller_topology,
 finish_requests = finish_http_requests
}
]]))
	setfenv(fn, env)
	local api = fn()
	-- Replace only the HTTP transport. Discovery, topology resolution and
	-- client ownership still execute the production functions.
	local replaced = false
	for index = 1, 20 do
		local name = debug.getupvalue(api.fetch_agents, index)
		if not name then break end
		if name == "fetch_nodes_parallel" then
			debug.setupvalue(api.fetch_agents, index, function(nodes, method)
				local results = {}
				for _, node in ipairs(nodes) do
					state.requests[#state.requests + 1] = {ip = node.ip, method = method}
					results[node.ip] = (method == "get_topology" and state.topologies or state.agents)[node.ip]
				end
				return results
			end)
			replaced = true
		end
	end
	assert(replaced, "HTTP transport upvalue not found")
	return api
end

local function wired_port(mac, port)
	return {mac = mac, port = port or "LAN1", speed = "1000M"}
end

local function wired_client(port)
	return {mac = client_mac, access_type = "wired", port = port, port_speed = "1000M"}
end

local function agent(mac, ip, ports, clients)
	return {
		mac = mac, ip = ip, role = "agent", hostname = ip, mesh_id = "test-mesh",
		upstream = {type = "wired", parent_mac = ac_mac, port = "WAN", port_speed = "1000M"},
		wired_ports = ports or {}, clients = clients or {}
	}
end

local function register(state, node)
	state.agents[node.ip] = node
	state.files["/tmp/hosts/fakemesh"] = state.files["/tmp/hosts/fakemesh"] .. node.ip .. " " .. node.mac:gsub(":", "") .. ".ap.fakemesh\n"
end

local function by_id(topology)
	local result = {}
	for _, node in ipairs(topology.nodes) do result[node.id] = node end
	return result
end

local passed = 0
local function test(name, run)
	run()
	passed = passed + 1
	print("ok: " .. name)
end

test("sibling wired APs do not become each other's parent", function()
	local state = fixture()
	state.fdb = a_mac .. " dev lan1 master br-lan\n" .. b_mac .. " dev lan2 master br-lan\n"
	register(state, agent(a_mac, "192.168.1.2", {wired_port(b_mac, "WAN")}))
	register(state, agent(b_mac, "192.168.1.3", {wired_port(a_mac, "WAN")}))
	local topology = instantiate(state).methods.get_topology.call()
	for _, node in ipairs(topology.nodes) do
		if node.id ~= "ac" then assert(node.parent_id == "ac" and node.hop_count == 1) end
	end
	assert(topology.summary.node_count == 3)
end)

test("wired cascades select nearest parent and directly attached client node", function()
	local state = fixture()
	state.fdb = a_mac .. " dev lan1 master br-lan\n" .. b_mac .. " dev lan1 master br-lan\n" .. c_mac .. " dev lan1 master br-lan\n" .. client_mac .. " dev lan1 master br-lan\n"
	register(state, agent(a_mac, "192.168.1.2", {wired_port(b_mac), wired_port(c_mac)}, {wired_client("LAN1")}))
	register(state, agent(b_mac, "192.168.1.3", {wired_port(c_mac)}, {wired_client("LAN1")}))
	register(state, agent(c_mac, "192.168.1.4", {}, {wired_client("LAN2")}))
	local topology = instantiate(state).methods.get_topology.call()
	local nodes = by_id(topology)
	assert(nodes.node_020000000002.parent_id == "ac")
	assert(nodes.node_020000000003.parent_id == "node_020000000002")
	assert(nodes.node_020000000004.parent_id == "node_020000000003")
	assert(nodes.node_020000000004.hop_count == 3)
	assert(#topology.clients == 1 and topology.clients[1].node_id == "node_020000000004")
end)

test("AC-local wired client is not assigned to an AP uplink", function()
	local state = fixture()
	state.fdb = client_mac .. " dev lan2 master br-lan\n"
	register(state, agent(a_mac, "192.168.1.2", {}, {wired_client("WAN")}))
	local topology = instantiate(state).methods.get_topology.call()
	assert(#topology.clients == 1 and topology.clients[1].node_id == "ac")
end)

test("LAN uplink is detected from gateway FDB and excluded from local clients", function()
	local state = fixture()
	state.uci["fakemesh.default.role"] = "wap"
	state.route = "default via 192.168.1.1 dev br-lan"
	state.files["/proc/net/arp"] = "192.168.1.1 0x1 0x2 " .. ac_mac .. " * br-lan\n"
	state.files["/sys/class/net/lan2/speed"] = "2500"
	state.files["/sys/class/net/wan/speed"] = "1000"
	state.fdb = ac_mac .. " dev lan2 vlan 1 master br-lan\n" .. b_mac .. " dev lan2 master br-lan\n" .. client_mac .. " dev lan1 master br-lan\n"
	local node = instantiate(state).methods.get_node_info.call()
	assert(node.upstream.ifname == "lan2" and node.upstream.port_speed == "2500M")
	assert(#node.clients == 1 and node.clients[1].mac == client_mac)
	assert(#node.wired_ports == 1 and node.wired_ports[1].port == "LAN1")
end)

test("only associated and authorized Wi-Fi clients are counted; PHY uses Mbps", function()
	local state = fixture()
	state.objects = {"hostapd.phy0-ap0"}
	state.ubus["hostapd.phy0-ap0"] = {
		get_status = {ssid = "Test", freq = 5180},
		get_clients = {clients = {
			[client_mac] = {assoc = true, authorized = true, signal = -62, rate = {rx = 120100000, tx = 86670000}},
			[a_mac] = {assoc = false, authorized = false},
			[b_mac] = {assoc = true, authorized = false},
			[c_mac] = {assoc = 0, authorized = 1}
		}}
	}
	state.ubus.iwinfo = {assoclist = function(args)
		assert(args.device == "phy0-ap0")
		return {results = {{mac = client_mac, inactive = 250, rx = {rate = 1201000}, tx = {rate = 866700}}}}
	end}
	local node = instantiate(state).methods.get_node_info.call()
	assert(#node.clients == 1 and node.downstream.total_count == 1)
	assert(node.clients[1].rate_rx == 1201 and node.clients[1].rate_tx == 866.7)
	assert(node.clients[1].inactive_ms == 250)
	-- Older hostapd versions report kbps correctly; the result must be identical.
	state.ubus["hostapd.phy0-ap0"].get_clients.clients[client_mac].rate = {rx = 1201000, tx = 866700}
	node = instantiate(state).methods.get_node_info.call()
	assert(node.clients[1].rate_rx == 1201 and node.clients[1].rate_tx == 866.7)
	state.ubus["hostapd.phy0-ap0"].get_clients.clients[client_mac].assoc = 1
	state.ubus["hostapd.phy0-ap0"].get_clients.clients[client_mac].authorized = 1
	assert(#instantiate(state).methods.get_node_info.call().clients == 1)
	-- A historical natflow record must not resurrect an unauthorized station.
	state.ubus["luci.natflow"] = {get_mac_users = {result = {{mac = b_mac, access_type = "wireless", ip = {"192.168.1.99"}}}}}
	local topology = instantiate(state).methods.get_topology.call()
	assert(#topology.clients == 1 and topology.clients[1].mac == client_mac)
	assert(topology.clients[1].idle_time == 0)
	assert(topology.clients[1].rate_rx == 1201 and topology.clients[1].rate_tx == 866.7)
end)

test("Wi-Fi PHY rates handle missing iwinfo data and match MACs case-insensitively", function()
	local state = fixture()
	local mac = "AA:BB:CC:DD:EE:99"
	state.objects = {"hostapd.phy0-ap0"}
	state.ubus["hostapd.phy0-ap0"] = {
		get_status = {ssid = "Test", freq = 5180},
		get_clients = {clients = {[mac] = {assoc = true, authorized = true, rate = {rx = 120100000, tx = 86670000}}}}
	}
	local client = instantiate(state).methods.get_node_info.call().clients[1]
	assert(client.rate_rx == 0 and client.rate_tx == 0)
	state.ubus.iwinfo = {assoclist = {results = {{mac = mac:lower(), inactive = 100, rx = {rate = 5500}}}}}
	client = instantiate(state).methods.get_node_info.call().clients[1]
	assert(client.mac == mac and client.inactive_ms == 100)
	assert(client.rate_rx == 5.5 and client.rate_tx == 0)
	state.ubus.iwinfo.assoclist.results[1] = {mac = mac:lower(), rx = {rate = 0}, tx = {rate = 0}}
	client = instantiate(state).methods.get_node_info.call().clients[1]
	assert(client.rate_rx == 0 and client.rate_tx == 0)
end)

test("roaming ownership uses per-node activity before signal strength", function()
	local state = fixture()
	state.objects = {"hostapd.phy0-ap0"}
	state.ubus["hostapd.phy0-ap0"] = {
		get_status = {ssid = "Test", freq = 5180},
		get_clients = {clients = {[client_mac] = {assoc = true, authorized = true, signal = -90}}}
	}
	state.ubus.iwinfo = {assoclist = {results = {{mac = client_mac, inactive = 100}}}}
	register(state, agent(a_mac, "192.168.1.2", {}, {{mac = client_mac, access_type = "wireless", signal = -30, inactive_ms = 900000}}))
	local topology = instantiate(state).methods.get_topology.call()
	assert(topology.clients[1].node_id == "ac")
	state.agents["192.168.1.2"].clients[1].inactive_ms = 10
	topology = instantiate(state).methods.get_topology.call()
	assert(topology.clients[1].node_id == "node_020000000002")
end)

test("wireless parent cycles are repaired before hop calculation", function()
	local state = fixture()
	local a = agent(a_mac, "192.168.1.2")
	local b = agent(b_mac, "192.168.1.3")
	a.mesh_bssid, b.mesh_bssid = a_mac, b_mac
	a.upstream = {type = "wireless", parent_bssid = b_mac}
	b.upstream = {type = "wireless", parent_bssid = a_mac}
	register(state, a); register(state, b)
	local topology = instantiate(state).methods.get_topology.call()
	local nodes = by_id(topology)
	for _, node in ipairs(topology.nodes) do
		local visited = {}
		while node.id ~= "ac" do
			assert(not visited[node.id])
			visited[node.id] = true
			node = assert(nodes[node.parent_id])
		end
	end
	assert(topology.summary.max_hops == 2)
end)

test("bypass deployment discovers the matching controller instead of gateway", function()
	local state = fixture()
	state.uci["fakemesh.default.role"] = "agent"
	state.uci["network.meshx0.hostname"] = "MESH-AGENT_020000000002"
	state.ip = "192.168.1.2"
	state.files["/proc/net/route"] = "br-lan 00000000 01A8A8C0 0003 0 0 10 00000000\n"
	state.ubus.umdns = {browse = {
		["_fakemesh_test-mesh._tcp"] = {AC = {ipv4 = "192.168.1.1"}},
		["_fakemesh_other-mesh._tcp"] = {Other = {ipv4 = "192.168.1.10"}}
	}}
	state.agents["192.168.1.1"] = {mac = ac_mac, role = "controller", mesh_id = "test-mesh"}
	state.agents["192.168.168.1"] = {mac = a_mac, role = "agent", mesh_id = "test-mesh"}
	state.topologies["192.168.1.1"] = {mesh_id = "test-mesh", nodes = {{id = "ac", role = "controller"}}, clients = {}}
	local topology = instantiate(state).methods.get_topology.call()
	assert(topology.current_node_id == "node_020000000002")
	assert(topology.nodes[1].id == "ac" and topology.nodes[1].online ~= false)
	for _, request in ipairs(state.requests) do
		assert(request.ip ~= "192.168.1.10")
		assert(request.method ~= "get_topology" or request.ip == "192.168.1.1")
	end
end)

test("controller failures continue to validated gateway and reject wrong Mesh ID", function()
	local state = fixture()
	state.ubus.umdns = {browse = {["_fakemesh_test-mesh._tcp"] = {
		First = {ipv4 = "192.168.1.10"}, Wrong = {ipv4 = "192.168.1.11"}
	}}}
	state.files["/proc/net/route"] = "br-lan 00000000 0101A8C0 0003 0 0 10 00000000\n"
	state.agents["192.168.1.10"] = {mac = ac_mac, role = "controller", mesh_id = "test-mesh"}
	state.agents["192.168.1.11"] = {mac = ac_mac, role = "controller", mesh_id = "other-mesh"}
	state.agents["192.168.1.1"] = {mac = ac_mac, role = "controller", mesh_id = "test-mesh"}
	state.topologies["192.168.1.10"] = {mesh_id = "test-mesh", nodes = {false}, clients = {}}
	state.topologies["192.168.1.1"] = {mesh_id = "test-mesh", nodes = {{id = "ac", role = "controller"}}, clients = {}}
	local api = instantiate(state)
	local topology, ip = api.fetch_controller({call = function() return state.ubus.umdns.browse end}, {ip = "192.168.1.2", mesh_id = "test-mesh"})
	assert(topology and ip == "192.168.1.1")
	for _, request in ipairs(state.requests) do
		assert(request.method ~= "get_topology" or request.ip ~= "192.168.1.11")
	end
end)

test("Mesh IDs preserve spaces through both config paths and mDNS discovery", function()
	for _, legacy in ipairs({false, true}) do
		local state = fixture()
		local mesh_id = " room mesh "
		state.uci_unavailable = legacy
		state.uci["fakemesh.default.id"] = mesh_id
		state.uci["fakemesh.default.role"] = "agent"
		state.uci["network.meshx0.hostname"] = "MESH-AGENT_020000000002"
		state.ip = "192.168.1.2"
		state.ubus.umdns = {browse = {["_fakemesh_" .. mesh_id .. "._tcp"] = {AC = {ipv4 = "192.168.1.1"}}}}
		state.agents["192.168.1.1"] = {mac = ac_mac, role = "controller", mesh_id = mesh_id}
		state.topologies["192.168.1.1"] = {mesh_id = mesh_id, nodes = {{id = "ac", role = "controller"}}, clients = {}}
		local api = instantiate(state)
		assert(api.methods.get_node_info.call().mesh_id == mesh_id)
		local topology = api.methods.get_topology.call()
		assert(topology.mesh_id == mesh_id and #topology.nodes == 1)
		assert(topology.current_node_id == "node_020000000002")
	end
end)

test("a controller refresh shares config, ARP, IPv6 and one ubus connection", function()
	local state = fixture()
	state.files["/proc/net/arp"] = "192.168.1.99 0x1 0x2 " .. client_mac .. " * br-lan\n"
	state.fdb = client_mac .. " dev lan1 master br-lan\n"
	local topology = instantiate(state).methods.get_topology.call()
	assert(topology.clients[1].ip == "192.168.1.99")
	assert(state.connections == 1 and state.file_reads["/proc/net/arp"] == 1)
	local ipv6, configs = 0, 0
	for _, command in ipairs(state.shell_calls) do
		assert(not command:find("uci ", 1, true))
		if command:find("ip -6 -o neigh show", 1, true) then ipv6 = ipv6 + 1 end
	end
	for _, call in ipairs(state.calls) do if call == "uci get" then configs = configs + 1 end end
	assert(ipv6 == 1 and configs == 2)
	assert(#state.shell_calls == 6)
end)

test("6 GHz clients and backhauls include low channels in both topology paths", function()
	for _, role in ipairs({"controller", "agent"}) do
		for _, freq in ipairs({5935, 5955, 6115}) do
			local state = fixture()
			state.uci["fakemesh.default.role"] = role
			state.link = "Connected to " .. ac_mac .. "\nSSID: test-mesh\nfreq: " .. freq .. "\n"
			state.objects = {"hostapd.phy0-ap0"}
			state.ubus["hostapd.phy0-ap0"] = {
				get_status = {ssid = "Test6G", freq = freq},
				get_clients = {clients = {[client_mac] = {assoc = true, authorized = true}}}
			}
			local topology = instantiate(state).methods.get_topology.call()
			assert(topology.clients[1].band == "6G")
			assert(topology.summary.wifi_6g == 1 and topology.summary.wifi_2g == 0 and topology.summary.wifi_5g == 0)
			if role == "agent" then assert(topology.nodes[2].upstream.band == "6G") end
		end
	end
end)

test("offline and unknown uplinks never invent an Ethernet speed", function()
	local state = fixture()
	register(state, agent(a_mac, "192.168.1.2"))
	state.agents["192.168.1.2"] = nil
	local live = agent(b_mac, "192.168.1.3")
	live.upstream.port_speed = nil
	register(state, live)
	local unknown = agent(c_mac, "192.168.1.4")
	unknown.upstream = {type = "unknown"}
	register(state, unknown)
	local topology = instantiate(state).methods.get_topology.call()
	local nodes = by_id(topology)
	assert(nodes.node_020000000002.uplink.type == "unknown")
	assert(nodes.node_020000000003.uplink.type == "wired" and nodes.node_020000000003.uplink.speed == nil)
	assert(nodes.node_020000000004.uplink.type == "unknown")
	assert(topology.summary.wired_nodes == 1 and topology.summary.offline_agents == 1)
end)

test("foreign, mismatched and malformed node reports only take that node offline", function()
	local invalid = {
		function(n) n.mesh_id = "other-mesh" end,
		function(n) n.mac = b_mac end,
		function(n) n.role = "controller" end,
		function(n) n.radios = "invalid" end,
		function(n) n.clients = {{mac = client_mac, ips = {false}}} end,
		function(n) n.upstream = {parent_bssid = {}} end,
		function(n) n.wired_ports = {{mac = false}} end,
		function(n) n.uptime = "invalid" end
	}
	for _, corrupt in ipairs(invalid) do
		local state = fixture()
		local bad = agent(a_mac, "192.168.1.2")
		register(state, bad)
		corrupt(bad)
		register(state, agent(c_mac, "192.168.1.4", {}, {wired_client("LAN1")}))
		local topology = instantiate(state).methods.get_topology.call()
		local nodes = by_id(topology)
		assert(nodes.node_020000000002.online == false)
		assert(nodes.node_020000000004.online and #topology.clients == 1)
	end
end)

test("standalone agents retain known wired, wireless and unknown backhauls", function()
	for _, link in ipairs({"wired", "wireless", "unknown"}) do
		local state = fixture()
		state.uci["fakemesh.default.role"] = link == "wired" and "wap" or "agent"
		if link == "wired" then
			state.route = "default via 192.168.1.1 dev br-lan"
			state.files["/proc/net/arp"] = "192.168.1.1 0x1 0x2 " .. ac_mac .. " * br-lan\n"
			state.files["/sys/class/net/lan2/speed"] = "2500"
			state.fdb = ac_mac .. " dev lan2 master br-lan\n"
		elseif link == "wireless" then
			state.link = "Connected to " .. ac_mac .. "\nSSID: test-mesh\nsignal: -51 dBm\nfreq: 5955\nrx bitrate: 1201.0 MBit/s\n"
		end
		local topology = instantiate(state).methods.get_topology.call()
		local controller, node = topology.nodes[1], topology.nodes[2]
		assert(controller.online == false and controller.uplink.type == "root")
		assert(node.uplink.type == link and node.upstream.type == link and node.online)
		assert(node.uplink ~= node.upstream and node.uplink ~= node.backhaul)
		if link == "wired" then
			assert(node.uplink.port == "LAN2" and node.uplink.speed == "2500M" and topology.summary.wired_nodes == 1)
		elseif link == "wireless" then
			assert(node.uplink.band == "6G" and node.uplink.signal == -51 and node.uplink.rx_bitrate == 1201 and topology.summary.wireless_nodes == 1)
		else
			assert(node.uplink.speed == nil and topology.summary.wired_nodes == 0 and topology.summary.wireless_nodes == 0)
		end
	end
end)

test("natflow mesh records need a live node report before becoming clients", function()
	local state = fixture()
	register(state, agent(a_mac, "192.168.1.2", {}, {{mac = client_mac, access_type = "wireless", band = "6G", associated = true, authorized = true}}))
	state.ubus["luci.natflow"] = {get_mac_users = {result = {
		{mac = client_mac, access_type = "wireless_mesh", ifname = "meshx0", ip = {"192.168.1.99"}, idle_time = 900, rx_speed_bytes = 1024},
		{mac = b_mac, access_type = "wired", ifname = "lan1", ip = {"192.168.1.98"}},
		{mac = c_mac, access_type = "vpn", ifname = "wg0", ip = {"10.0.0.2"}}
	}}}
	local topology = instantiate(state).methods.get_topology.call()
	assert(#topology.clients == 3 and topology.summary.wifi_6g == 1)
	for _, client in ipairs(topology.clients) do
		if client.mac == client_mac then
			assert(client.node_id == "node_020000000002" and client.access_type == "wireless" and client.rx_speed == 1024)
		end
	end
	state.agents["192.168.1.2"].clients[1].access_type = "wired"
	state.agents["192.168.1.2"].clients[1].port = "LAN1"
	topology = instantiate(state).methods.get_topology.call()
	assert(#topology.clients == 3 and topology.summary.wired == 2)
	for _, client in ipairs(topology.clients) do
		if client.mac == client_mac then assert(client.node_id == "node_020000000002" and client.access_type == "wired") end
	end
	-- NAT state can outlive both an association and the node's HTTP report.
	state.agents["192.168.1.2"].clients = {}
	for _, offline in ipairs({false, true}) do
		if offline then state.agents["192.168.1.2"] = nil end
		topology = instantiate(state).methods.get_topology.call()
		assert(#topology.clients == 2 and topology.summary.wired == 1 and topology.summary.vpn == 1)
		for _, client in ipairs(topology.clients) do
			assert(client.mac ~= client_mac and client.node_id == "ac")
		end
	end
end)

test("node IPs exclude NAT-only aliases before address filtering", function()
	for _, access_type in ipairs({"wired", "vpn"}) do
		for _, address_source in ipairs({"natflow", "dhcp", "arp"}) do
			local state = fixture()
			local user = {mac = client_mac, access_type = access_type, ifname = access_type == "vpn" and "wg0" or "lan1", ip = {}}
			if address_source == "natflow" then user.ip = {state.ip, "192.168.1.99"}
			elseif address_source == "dhcp" then state.files["/tmp/dhcp.leases"] = "0 " .. client_mac .. " " .. state.ip .. " alias *\n"
			else state.files["/proc/net/arp"] = state.ip .. " 0x1 0x2 " .. client_mac .. " * br-lan\n" end
			state.ubus["luci.natflow"] = {get_mac_users = {result = {user,
				{mac = b_mac, access_type = "wired", ip = {"192.168.1.98"}},
				{mac = c_mac, access_type = "wired", ip = {}, ip6 = {"2001:db8::1"}}
			}}}
			local topology = instantiate(state).methods.get_topology.call()
			assert(#topology.clients == 2 and topology.summary.wired == 2)
			for _, client in ipairs(topology.clients) do assert(client.mac ~= client_mac) end
		end
	end
	local state = fixture()
	state.ubus["luci.natflow"] = {get_mac_users = {result = {
		{mac = "00:00:00:00:00:00", access_type = "vpn", ifname = "wg0", ip = {"10.0.0.1", state.ip}},
		{mac = ac_mac, access_type = "vpn", ifname = "wg0", ip = {"10.0.0.2"}},
		{mac = "", access_type = "vpn", ifname = "wg1", ip = {"10.0.0.3"}}
	}}}
	local topology = instantiate(state).methods.get_topology.call()
	assert(#topology.clients == 1 and topology.clients[1].ip == "10.0.0.3" and topology.summary.vpn == 1)
end)

test("node IP aliases cannot bypass filtering through FDB or node reports", function()
	for _, reporter in ipairs({"fdb", "agent"}) do
		local state = fixture()
		state.ubus["luci.natflow"] = {get_mac_users = {result = {{mac = b_mac, access_type = "wired", ip = {"192.168.1.98"}}}}}
		if reporter == "fdb" then
			state.fdb = client_mac .. " dev lan1 master br-lan\n"
			state.files["/proc/net/arp"] = state.ip .. " 0x1 0x2 " .. client_mac .. " * br-lan\n"
		else
			local client = wired_client("LAN1")
			client.ip = state.ip
			register(state, agent(a_mac, "192.168.1.2", {}, {client}))
		end
		local topology = instantiate(state).methods.get_topology.call()
		assert(#topology.clients == 1 and topology.clients[1].mac == b_mac and topology.summary.wired == 1)
	end
end)

test("request deadline kills and reaps stalled children and closes responses", function()
	local state = fixture()
	state.processes = {[1] = {done_at = 1000}, [2] = {done_at = math.huge}}
	state.json_values.ready = {result = {0, {mac = a_mac}}}
	local function response(raw)
		local handle = {closed = false, data = raw}
		function handle:seek() end
		function handle:read() local data = self.data; self.data = ""; return data end
		function handle:close() self.closed = true end
		return handle
	end
	local ready, stalled = response("ready"), response("partial")
	local api = instantiate(state)
	local result = api.finish_requests({{pid = 1, ip = "192.168.1.2", response = ready}, {pid = 2, ip = "192.168.1.3", response = stalled}}, 1002)
	assert(result["192.168.1.2"].mac == a_mac and result["192.168.1.3"] == nil)
	assert(state.time < 1002.1 and state.processes[2].killed and state.processes[2].reaped)
	assert(ready.closed and stalled.closed)
end)

print(string.format("%d topology regression tests passed", passed))
