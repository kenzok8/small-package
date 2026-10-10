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
	local env = setmetatable({arg = {}}, {__index = _G})
	env.io = {
		open = function(path)
			if path == "/proc/uptime" then return stream(tostring(state.time)) end
			if state.files[path] == nil then return nil end
			return stream(state.files[path])
		end,
		popen = function(command)
			local data = ""
			if command:find("uci ", 1, true) then
				data = state.uci[command:match("get ([%w%._]+)")] or ""
			elseif command:find("ip -4 -o addr show br-lan", 1, true) then data = state.ip
			elseif command:find("bridge fdb show", 1, true) then data = state.fdb
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
				return {
					call = function(_, object, method, args)
						state.calls[#state.calls + 1] = object .. " " .. method
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
			[client_mac] = {assoc = true, authorized = true, signal = -62, rate = {rx = 1201000, tx = 866700}},
			[a_mac] = {assoc = false, authorized = false},
			[b_mac] = {assoc = true, authorized = false},
			[c_mac] = {assoc = 0, authorized = 1}
		}}
	}
	state.ubus.iwinfo = {assoclist = function(args)
		assert(args.device == "phy0-ap0")
		return {results = {{mac = client_mac, inactive = 250}}}
	end}
	local node = instantiate(state).methods.get_node_info.call()
	assert(#node.clients == 1 and node.downstream.total_count == 1)
	assert(node.clients[1].rate_rx == 1201 and node.clients[1].rate_tx == 866.7)
	assert(node.clients[1].inactive_ms == 250)
	state.ubus["hostapd.phy0-ap0"].get_clients.clients[client_mac].assoc = 1
	state.ubus["hostapd.phy0-ap0"].get_clients.clients[client_mac].authorized = 1
	assert(#instantiate(state).methods.get_node_info.call().clients == 1)
	-- A historical natflow record must not resurrect an unauthorized station.
	state.ubus["luci.natflow"] = {get_mac_users = {result = {{mac = b_mac, access_type = "wireless", ip = {"192.168.1.99"}}}}}
	local topology = instantiate(state).methods.get_topology.call()
	assert(#topology.clients == 1 and topology.clients[1].mac == client_mac)
	assert(topology.clients[1].idle_time == 0)
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
	state.agents["192.168.1.1"] = {role = "controller", mesh_id = "test-mesh"}
	state.agents["192.168.168.1"] = {role = "agent", mesh_id = "test-mesh"}
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
	state.agents["192.168.1.10"] = {role = "controller", mesh_id = "test-mesh"}
	state.agents["192.168.1.11"] = {role = "controller", mesh_id = "other-mesh"}
	state.agents["192.168.1.1"] = {role = "controller", mesh_id = "test-mesh"}
	state.topologies["192.168.1.1"] = {mesh_id = "test-mesh", nodes = {{id = "ac", role = "controller"}}, clients = {}}
	local api = instantiate(state)
	local topology, ip = api.fetch_controller({call = function() return state.ubus.umdns.browse end}, {ip = "192.168.1.2", mesh_id = "test-mesh"})
	assert(topology and ip == "192.168.1.1")
	for _, request in ipairs(state.requests) do
		assert(request.method ~= "get_topology" or request.ip ~= "192.168.1.11")
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
