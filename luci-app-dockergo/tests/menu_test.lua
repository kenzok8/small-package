-- Run on iStoreOS: lua tests/menu_test.lua luasrc/controller/dockergo.lua
-- Capture declarations only; no HTTP requests or Docker operations are executed.
assert(loadfile(assert(arg[1], "pass controller path")))()
local controller = package.loaded["luci.controller.dockergo"]
local entries = {}
setfenv(controller.index, {
	entry = function(path, action, title, order)
		local route = table.concat(path, "/")
		assert(not entries[route], "duplicate route: " .. route)
		local node = { action = action, title = title, order = order }
		entries[route] = node
		return node
	end,
	view = function(path) return { type = "view", path = path } end,
	call = function(name) return { type = "call", name = name } end,
	post = function(name) return { type = "post", name = name } end,
	_ = function(text) assert(text == "DockerGo") return "容器GO" end,
})
controller.index()
local root = assert(entries["admin/dockergo"])
assert(root.title == "容器GO" and root.order == 70)
assert(root.depends.fs["/usr/bin/docker"] == "executable")
assert(not root.leaf, "root must not absorb API or page routes")
for _, base in ipairs({"admin/dockergo", "admin/services/dockergo"}) do
	for _, suffix in ipairs({"", "/installed", "/market"}) do
		local node = assert(entries[base .. suffix])
		assert(node.action.type == "view" and node.action.path == "dockergo/index")
		if base ~= "admin/dockergo" or suffix ~= "" then
			assert(not node.title, "page aliases must not add menu items")
		end
	end
	assert(entries[base .. "/market"].leaf, "old market subpaths need wildcard routing")
end
for _, route in ipairs({"apps.json", "files", "install", "containers", "inspect", "logs", "control", "remove"}) do
	local node = assert(entries["admin/services/dockergo/api/" .. route])
	assert(node.leaf)
	local mutation = route == "install" or route == "control" or route == "remove"
	assert(node.action.type == (mutation and "post" or "call"))
end
print("Controller menu tests passed: root menu, Docker dependency, hidden views, market wildcard, API and POST routes")
