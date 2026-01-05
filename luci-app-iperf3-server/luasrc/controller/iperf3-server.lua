module("luci.controller.iperf3-server", package.seeall)

function index()
	local fs = require "nixio.fs"

	if not fs.access("/etc/config/iperf3-server") then
		return
	end

	local page

	page = entry({"admin", "services", "iperf3-server"}, cbi("iperf3-server"), _("iPerf3 Server"), 99)
	page.acl_depends = { "luci-app-iperf3-server" }

	page = entry({"admin", "services", "iperf3-server", "status"},  call("act_status"))
	page.leaf = true
	page.acl_depends = { "luci-app-iperf3-server" }

	page = entry({"admin", "services", "iperf3-server", "start"},   call("act_start"))
	page.leaf = true
	page.acl_depends = { "luci-app-iperf3-server" }

	page = entry({"admin", "services", "iperf3-server", "stop"},    call("act_stop"))
	page.leaf = true
	page.acl_depends = { "luci-app-iperf3-server" }

	page = entry({"admin", "services", "iperf3-server", "restart"}, call("act_restart"))
	page.leaf = true
	page.acl_depends = { "luci-app-iperf3-server" }
end


local function json_ok(extra)
	local e = extra or {}
	luci.http.prepare_content("application/json")
	luci.http.write_json(e)
end

function act_status()
	local uci = require("luci.model.uci").cursor()
	local sys = require("luci.sys")

	local result = {
		running = false,     -- 是否任意一个 server 正常运行
		servers = {}         -- 每个端口的详细状态
	}

	-- 解析 /proc/net/tcp & /proc/net/tcp6，判断端口是否 LISTEN
	local function is_listening_in_proc(path, port)
		local f = io.open(path, "r")
		if not f then return false end

		local hex = string.format("%04X", port) -- 端口 16 进制，大写，固定 4 位
		-- /proc/net/tcp 列格式: sl local_address rem_address st ...
		-- local_address: AAAAAAAA:PPPP
		-- st = 0A 表示 LISTEN
		for line in f:lines() do
			-- 跳过表头
			if not line:match("^%s*sl%s+") then
				local st = line:match("^%s*%d+:%s+%x+:" .. hex .. "%s+%x+:%x+%s+(%x+)")
				if st == "0A" then
					f:close()
					return true
				end
			end
		end

		f:close()
		return false
	end

	local function is_listening(port)
		-- IPv4 LISTEN
		if is_listening_in_proc("/proc/net/tcp", port) then
			return true
		end
		-- IPv6 LISTEN（有的系统会只在 tcp6 里出现）
		if is_listening_in_proc("/proc/net/tcp6", port) then
			return true
		end
		return false
	end

	-- 用 ps 判断：是否存在 iperf3 server / delay 阶段 sleep+iperf3
	local ps = sys.exec("ps w 2>/dev/null") or ""

	local function has_iperf3_server_proc(port)
		local p = tostring(port)

		for line in ps:gmatch("[^\r\n]+") do
			-- 只要这行同时包含：
			-- 1) iperf3
			-- 2) -s（server）
			-- 3) -p 端口（支持 "-p 5201" 或 "-p5201"）
			if line:find("iperf3", 1, true) then
				local hasS = line:match("%-s") ~= nil
				local hasP = (line:match("%-p%s*" .. p .. "%f[^%d]") ~= nil) or (line:match("%-p" .. p .. "%f[^%d]") ~= nil)
				if hasS and hasP then
					return true
				end
			end
		end

		return false
	end


	local function has_delay_pending_proc(port)
		local p = tostring(port)
		for line in ps:gmatch("[^\r\n]+") do
			-- 匹配 sh -c "sleep N; exec iperf3 -s -p <port> ..."
			if (line:find("/bin/sh", 1, true) or line:find("sh -c", 1, true))
				and line:find("sleep", 1, true)
				and line:find("iperf3", 1, true)
				and (line:match("%-p%s*" .. p .. "%f[^%d]") or line:match("%-p" .. p .. "%f[^%d]"))
			then
				return true
			end
		end
		return false
	end


	uci:foreach("iperf3-server", "servers", function(s)
		local port = tonumber(s.port)
		local enabled = (s.enable_server == "1")

		if not port then
			return
		end

		local listen = is_listening(port)
		local iperf3_proc = has_iperf3_server_proc(port)
		local delay_pending = has_delay_pending_proc(port)

		local state, detail
		if not enabled then
			state = "disabled"
			detail = "detail_disabled"
		else
			if delay_pending and not listen then
				state = "delay"
				detail = "detail_delay"
			elseif listen and iperf3_proc then
				state = "running"
				detail = "detail_running"
				result.running = true
			elseif listen and not iperf3_proc then
				state = "conflict"
				detail = "detail_conflict"
			else
				state = "stopped"
				detail = "detail_stopped"
			end
		end

		result.servers[#result.servers + 1] = {
			port = port,
			enable = enabled,
			listen = listen,
			state = state,
			detail = detail
		}
	end)

	luci.http.prepare_content("application/json")
	luci.http.write_json(result)
end



function act_start()
	local rc = luci.sys.call("/etc/init.d/iperf3-server start >/dev/null 2>&1")
	json_ok({ ok = (rc == 0) })
end

function act_stop()
	local rc = luci.sys.call("/etc/init.d/iperf3-server stop >/dev/null 2>&1")
	json_ok({ ok = (rc == 0) })
end

function act_restart()
	local rc = luci.sys.call("/etc/init.d/iperf3-server restart >/dev/null 2>&1")
	json_ok({ ok = (rc == 0) })
end
