module("luci.controller.fastnet", package.seeall)

function index()
 for _,action in ipairs({"summary","run","task","cancel"}) do
  entry({"admin","services","fastnet","card",action},call("action_card_"..action)).leaf=true
 end
	if not nixio.fs.access("/etc/config/fastnet") then return end

	entry({"admin", "services", "fastnet"}, cbi("fastnet"), _("FastNet"), 50).dependent = true
	entry({"admin", "services", "fastnet", "status"}, call("action_status")).leaf = true
	entry({"admin", "services", "fastnet", "browser-origin"}, call("action_browser_origin")).leaf = true
	entry({"admin", "services", "fastnet", "embed"}, call("action_embed")).leaf = true
	local open = entry({"admin", "services", "fastnet", "open"}, call("action_open"))
	open.leaf = true
	open.dependent = false
	open.sysauth = false
end

local function compat()
	local dispatcher = require "luci.dispatcher"
	return require("luci.model.linkease.apps_compat").new({
		http = require "luci.http",
		resolver = require("luci.model.linkease.apps_openwrt").new(),
		auth_url = dispatcher.build_url("admin", "services", "linkease_auth", "auth")
	})
end

function action_status()
	local sys = require "luci.sys"
	local uci = require "luci.model.uci".cursor()
	compat():legacy_status("fastnet", {
		running = sys.call("pidof FastNet >/dev/null") == 0,
		port = uci:get_first("fastnet", "fastnet", "port") or "3200"
	})
end

function action_open()
	local dispatcher = require "luci.dispatcher"
	require("luci.http").redirect(dispatcher.build_url("admin", "services", "fastnet", "embed") .. "?standalone=1")
end

-- Only the launch metadata passes through LuCI. The iframe and all test data
-- connect to the configured FastNet service port in the browser.
function action_embed()
 local http = require "luci.http"
 local ctx = require("luci.dispatcher").context
 if http.getenv("REQUEST_METHOD") ~= "GET" then http.status(405); return end
 if not ctx.authsession or ctx.authuser ~= "root" then http.status(403); return end
 local authority = http.getenv("HTTP_HOST") or ""
 local host = authority:match("^(%[[%x:%.]+%]):?%d*$") or authority:match("^([%w%.%-]+):?%d*$")
 local uci = require("luci.model.uci").cursor()
 local port = tonumber(uci:get_first("fastnet", "fastnet", "port") or "3200")
 if uci:get_first("fastnet", "fastnet", "enabled") == "0" or not host or not port or port % 1 ~= 0 or port < 1 or port > 65535 then
  http.status(503); return
 end
 local url = "http://" .. host .. ":" .. tostring(port) .. "/webui/"
 local query = {}
 if http.formvalue("standalone") ~= "1" then
  query[#query+1] = "embed=quickstart"
  query[#query+1] = "theme=" .. (http.formvalue("theme") == "dark" and "dark" or "light")
 end
 if http.formvalue("view") == "history" then query[#query+1] = "view=history" end
 local token = uci:get_first("fastnet", "fastnet", "token") or ""
 if token ~= "" then query[#query+1] = "token=" .. http.urlencode(token) end
 if #query > 0 then url = url .. "?" .. table.concat(query, "&") end
 http.header("Cache-Control", "no-store")
 http.header("Referrer-Policy", "no-referrer")
 if http.formvalue("format") == "json" then
  http.prepare_content("application/json"); http.write_json({url=url})
 else
  http.redirect(url)
 end
end

function action_card_summary() require("luci.model.fastnet.card").new():handle("summary") end
function action_card_run() require("luci.model.fastnet.card").new():handle("run") end
function action_card_task() require("luci.model.fastnet.card").new():handle("task") end
function action_card_cancel() require("luci.model.fastnet.card").new():handle("cancel") end

-- uHTTPd owns REMOTE_ADDR. The app proxy's loopback peer and browser-provided
-- forwarded headers cannot stand in for the real browser in LAN capability UI.
function action_browser_origin()
 local http = require "luci.http"
 local ctx = require("luci.dispatcher").context
 if not ctx.authsession or ctx.authuser ~= "root" then http.status(403); return end
 if http.getenv("REQUEST_METHOD") ~= "GET" then http.status(405); return end
 local address = http.getenv("REMOTE_ADDR")
 if type(address) ~= "string" or address == "" or #address > 64 or not address:match("^[%x:%.]+$") then http.status(503); return end
 local loopback = address == "::1" or address:match("^127%.") ~= nil or address:match("^::ffff:127%.") ~= nil
 local local_address = loopback
 for _, entry in ipairs(require("nixio").getifaddrs() or {}) do
  if entry.addr == address then local_address = true; break end
 end
 http.prepare_content("application/json")
 http.header("Cache-Control", "no-store")
 http.header("X-Content-Type-Options", "nosniff")
 http.write_json({isLoopback=loopback,isLocal=local_address,isLocalInterface=local_address})
end
