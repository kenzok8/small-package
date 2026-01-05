module("luci.controller.shutdown", package.seeall)

local http  = require "luci.http"
local sys   = require "luci.sys"
local jsonc = require "luci.jsonc"
local fs    = require "nixio.fs"

local function json_ok(tbl)
	http.prepare_content("application/json")
	http.write_json(tbl or { ok = true })
end

local function json_err(msg, code)
	http.status(code or 500, "Error")
	http.prepare_content("application/json")
	http.write_json({ ok = false, error = msg or "unknown error" })
end

local function poweroff_supported()
	-- OpenWrt 常见：/sbin/poweroff（procd）
	if fs.access("/sbin/poweroff") then
		return true, "found /sbin/poweroff"
	end

	-- BusyBox applet 兜底（有些系统没有独立 /sbin/poweroff）
	local ret = sys.call("/bin/busybox poweroff -h >/dev/null 2>&1")
	if ret == 0 then
		return true, "busybox poweroff applet"
	end

	return false, "poweroff command not found"
end

local function get_board()
	local out = sys.exec("ubus call system board 2>/dev/null")
	local obj = (out and #out > 0) and jsonc.parse(out) or nil
	return obj or {}
end

function index()
	local page = entry({"admin", "system", "shutdown"}, cbi("shutdown"), _("Shutdown / Reboot"), 90)
	page.dependent = true
	page.acl_depends = { "luci-app-shutdown" }

	-- JSON endpoints
	entry({"admin", "system", "shutdown", "status"}, call("action_status")).leaf = true
	entry({"admin", "system", "shutdown", "reboot"}, post("action_reboot")).leaf = true
	entry({"admin", "system", "shutdown", "poweroff"}, post("action_poweroff")).leaf = true
end

function action_status()
	local supported, reason = poweroff_supported()
	local board = get_board()

	json_ok({
		ok = true,
		poweroff_supported = supported,
		poweroff_reason = reason,
		board = {
			model = board.model,
			system = board.system,
			release = board.release,
			kernel = board.kernel,
			hostname = board.hostname
		}
	})
end

function action_reboot()
	-- 后台执行，先返回 JSON
	sys.call("(sleep 1; sync; reboot) >/dev/null 2>&1 &")
	json_ok({ ok = true })
end

function action_poweroff()
	local supported, reason = poweroff_supported()
	if not supported then
		return json_err("Poweroff not supported: " .. (reason or ""), 400)
	end

	sys.call("(sleep 1; sync; poweroff) >/dev/null 2>&1 &")
	json_ok({ ok = true })
end
