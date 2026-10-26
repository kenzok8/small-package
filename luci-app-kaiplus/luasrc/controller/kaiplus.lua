local http = require "luci.http"

module("luci.controller.kaiplus", package.seeall)

function index()
	entry({"admin", "services", "kaiplus_status"}, call("kaiplus_status"))
	local open = entry({"admin", "services", "kaiplus", "open"}, call("kaiplus_open"))
	open.leaf = true
	open.dependent = false
	open.sysauth = "root"
	open.sysauth_authenticator = "htmlauth"

	if not nixio.fs.access("/etc/config/kaiplus") then return end
	local install_kai = entry({"admin", "services", "kaiplus", "install_kai"}, call("install_kai"))
	install_kai.leaf = true
	entry({"admin", "services", "kaiplus", "update_kai"}, call("update_kai")).leaf = true
	entry({"admin", "services", "kaiplus"}, alias("admin", "services", "kaiplus", "settings"), _("KaiPlus"), 100).dependent = true
	entry({"admin", "services", "kaiplus", "settings"}, cbi("kaiplus"), _("KaiPlus"), 10)
	entry({"admin", "services", "kaiplus", "classic"}, cbi("kaiplus/classic"), _("CLASSIC KAI"), 20)
	entry({"admin", "services", "kaiplus", "classic_status"}, call("classic_status")).leaf = true
end

local function write_json(obj)
	http.prepare_content("application/json")
	http.write_json(obj)
end

local function require_post_csrf()
	local dispatcher = require "luci.dispatcher"
	local context = dispatcher.context or {}
	local expected = context.authtoken or context.token

	if (http.getenv("REQUEST_METHOD") or "") ~= "POST" then
		http.status(405, "Method Not Allowed")
		write_json({ ok = false, error = "method not allowed" })
		return false
	end

	if not context.authsession or not expected or http.formvalue("token") ~= expected then
		http.status(403, "Forbidden")
		write_json({ ok = false, error = "invalid csrf token" })
		return false
	end

	return true
end

local function compat()
	local dispatcher = require "luci.dispatcher"
	return require("luci.model.linkease.apps_compat").new({
		http = require "luci.http",
		resolver = require("luci.model.linkease.apps_openwrt").new(),
		auth_url = dispatcher.build_url("admin", "services", "linkease_auth", "auth")
	})
end

function kaiplus_status()
	local sys = require "luci.sys"
	local uci = require("luci.model.uci").cursor()
	compat():legacy_status("kaiplus", {
		running = sys.call("pidof kaiplus >/dev/null") == 0,
		kai_installed = require("luci.model.kaiplus.classic").installed(),
		port = uci:get_first("kaiplus", "kaiplus", "port") or "8189",
		base_path = "/apps/kaiplus/",
		listen_mode = "tcp",
		external_port_enabled = true,
		lan_ip = uci:get("network", "lan", "ipaddr") or ""
	})
end

function kaiplus_open()
	compat():open("kaiplus")
end

function classic_status()
	write_json(require("luci.model.kaiplus.classic").status())
end

local function classic_package_task(action)
	local fs = require "nixio.fs"
	local jsonc = require "luci.jsonc"
	local sys = require "luci.sys"
	local util = require "luci.util"
	local task_id = "kaiplus-kai-install"

	if not require_post_csrf() then
		return
	end

	local installed = require("luci.model.kaiplus.classic").installed()
	if action == "install" and installed then
		write_json({ ok = true, installed = true })
		return
	end
	if action == "update" and not installed then
		http.status(409, "Conflict")
		write_json({ ok = false, error = "CLASSIC KAI is not installed" })
		return
	end
	if not fs.access("/etc/init.d/tasks") then
		write_json({ ok = false, error = "taskd is not available" })
		return
	end
	if not fs.access("/bin/is-opkg") then
		write_json({ ok = false, error = "iStore package installer is not available" })
		return
	end
	if not fs.access("/usr/libexec/kaiplus-classic", "x") then
		write_json({ ok = false, error = "CLASSIC KAI package helper is not available" })
		return
	end

	local task_status = sys.exec("/etc/init.d/tasks task_status " .. task_id .. " 2>/dev/null")
	local status = jsonc.parse(task_status) or {}
	local running = type(status) == "table" and status.running
	if running == true or running == 1 or running == "1" or running == "true" then
		write_json({ ok = true, busy = true, task_id = task_id })
		return
	end

	local command = "/usr/libexec/kaiplus-classic " .. action
	local rc = sys.call("/etc/init.d/tasks task_add " .. task_id .. " " .. util.shellquote(command) .. " >/dev/null 2>&1")
	if rc ~= 0 then
		write_json({ ok = false, error = "failed to start CLASSIC KAI package task", task_id = task_id })
		return
	end

	write_json({ ok = true, task_id = task_id })
end

function install_kai()
	classic_package_task("install")
end

function update_kai()
	classic_package_task("update")
end
