module("luci.controller.timewol", package.seeall)

local x = luci.model.uci.cursor()

function index()
    if not nixio.fs.access("/etc/config/timewol") then return end

    entry({"admin", "control"}, firstchild(), "Control", 44).dependent = false
    local page = entry({"admin", "control", "timewol"}, cbi("timewol"), _("Timed WOL"))
	page.order = 95
	page.dependent = true
	page.acl_depends = { "luci-app-timewol" }
    entry({"admin", "control", "timewol", "status"}, call("status")).leaf = true
    entry( {"admin", "control", "timewol", "awake"}, call("awake") ).leaf = true
end

function status()
    local e = {}
    e.status = luci.sys.call("cat /etc/crontabs/root |grep etherwake >/dev/null") == 0
    luci.http.prepare_content("application/json")
    luci.http.write_json(e)
end

function awake(sections)
	lan = x:get("timewol",sections,"maceth")
	mac = x:get("timewol",sections,"macaddr")
    local e = {}
    cmd = "/usr/bin/etherwake -D -i " .. lan .. " -b " .. mac .. " 2>&1"
	local p = io.popen(cmd)
	local msg = ""
	if p then
		while true do
			local l = p:read("*l")
			if l then
				if #l > 100 then l = l:sub(1, 100) .. "..." end
				msg = msg .. l
			else
				break
			end
		end
		p:close()
	end
	e["data"] = msg
    luci.http.prepare_content("application/json")
    luci.http.write_json(e)
end
