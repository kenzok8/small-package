module("luci.controller.fastnet", package.seeall)

function index()
	local fs = require "nixio.fs"
	if not fs.access("/etc/config/fastnet") then
		return
	end

	entry({"admin", "services", "fastnet"}, cbi("fastnet"), _("FastNet"), 50).dependent = true
	entry({"admin", "services", "fastnet", "status"}, call("action_status")).leaf = true
end

function action_status()
	local sys = require "luci.sys"
	local uci = require "luci.model.uci".cursor()
	local http = require "luci.http"

	local function get_host()
		local host = http.getenv("HTTP_HOST") or http.getenv("SERVER_NAME") or ""
		host = host:gsub(":%d+$", "")
		if host == "_redirect2ssl" or host == "redirect2ssl" or host == "" then
			host = http.getenv("SERVER_ADDR") or "localhost"
		end
		return host
	end

	local running = (sys.call("pidof FastNet >/dev/null") == 0)
	local host = get_host()
	local port = uci:get_first("fastnet", "fastnet", "port") or "3200"
	local token = uci:get_first("fastnet", "fastnet", "token") or ""

	local url = "http://" .. host .. ":" .. port .. "/"
	if token ~= "" then
		url = url .. "?token=" .. token
	end

	http.prepare_content("application/json")
	http.write_json({
		running = running,
		host = host,
		port = port,
		url = url
	})
end
