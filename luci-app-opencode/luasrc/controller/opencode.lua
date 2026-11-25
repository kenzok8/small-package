local http = require "luci.http"
module("luci.controller.opencode", package.seeall)

function index()
	if not nixio.fs.access("/etc/config/opencode") then return end
	local root = entry({"admin", "services", "opencode"}, cbi("opencode"), _("OpenCode"), 96)
	root.dependent = true
	local status = entry({"admin", "services", "opencode", "status"}, call("action_status"))
	status.leaf = true; status.acl_depends = { "luci-app-opencode" }
	local install = entry({"admin", "services", "opencode", "install"}, call("action_install"))
	install.leaf = true; install.acl_depends = { "luci-app-opencode" }
	for _, legacy in ipairs({ "terminal", "agentflow" }) do
		local removed = entry({"admin", "services", "opencode", legacy}, call("action_removed"))
		removed.leaf = true; removed.dependent = false
	end
end

local function write_json(value)
	http.prepare_content("application/json")
	http.write_json(value)
end

function action_removed()
	http.status(404, "Not Found")
	http.prepare_content("text/plain")
	http.write("Not found\n")
end

local function require_post_csrf()
	local dispatcher = require "luci.dispatcher"
	local context = dispatcher.context or {}
	local expected = context.authtoken or context.token
	if (http.getenv("REQUEST_METHOD") or "") ~= "POST" then
		http.status(405, "Method Not Allowed");write_json({ ok = false, error = "method not allowed" });return false
	end
	if not context.authsession or not expected or http.formvalue("token") ~= expected then
		http.status(403, "Forbidden");write_json({ ok = false, error = "invalid csrf token" });return false
	end
	local access = require("luci.util").ubus("session", "access", {
		ubus_rpc_session = context.authsession, scope = "access-group",
		object = "luci-app-opencode", ["function"] = "write"
	})
	if not access or access.access ~= true then
		http.status(403, "Forbidden");write_json({ ok = false, error = "write permission required" });return false
	end
	return true
end

local function task_running(id)
	local raw = require("luci.sys").exec("/etc/init.d/tasks task_status " .. id .. " 2>/dev/null")
	local state = require("luci.jsonc").parse(raw or "") or {}
	return state.running == true or state.running == 1 or state.running == "1" or state.running == "true"
end

function action_status()
	local fs = require "nixio.fs"
	local sys = require "luci.sys"
	local jsonc = require "luci.jsonc"
	local output = sys.exec("/usr/libexec/opencode-runtime status 2>/dev/null")
	local state = jsonc.parse(output or "") or { configured = false, installed = false, runtime = { ready = false } }
	state.service_running = sys.call("ubus -S call service list '{\"name\":\"opencode\"}' 2>/dev/null | jsonfilter -e '@.opencode.instances.terminal.running' | grep -qx true") == 0
	state.install_running = fs.access("/etc/init.d/tasks") and task_running("opencode-install") or false
	state.agentflow = {
		installed = fs.access("/usr/sbin/agentflow", "x") and fs.access("/etc/config/agentflow"),
		running = sys.call("pidof agentflow >/dev/null 2>&1") == 0
	}
	write_json(state)
end

function action_install()
	local fs = require "nixio.fs"
	local sys = require "luci.sys"
	local util = require "luci.util"
	local task_id = "opencode-install"
	if not require_post_csrf() then return end
	if not fs.access("/etc/init.d/tasks") then write_json({ ok = false, error = "taskd is not available" });return end
	if task_running(task_id) then write_json({ ok = true, busy = true, task_id = task_id });return end
	local base = require("luci.model.uci").cursor():get("opencode", "main", "data_dir") or ""
	local operation = http.formvalue("operation") or "install"
	if operation == "recover" then
		local rc = sys.call("/usr/libexec/opencode-runtime recover " .. util.shellquote(base) .. " >/dev/null 2>&1")
		write_json({ ok = rc == 0, error = rc ~= 0 and "Cannot recover a running or unknown install" or nil });return
	end
	if operation ~= "install" then write_json({ ok = false, error = "unsupported operation" });return end
	if sys.call("/usr/libexec/opencode-runtime prepare " .. util.shellquote(base) .. " >/dev/null 2>&1") ~= 0 then
		write_json({ ok = false, error = "Configure persistent OpenCode and runtime directories first" });return
	end
	local script = base .. "/.runtime/work/install-opencode-" .. require("nixio").getpid() .. ".sh"
	if fs.lstat(script) then write_json({ ok = false, error = "install task file already exists" });return end
	local body = table.concat({
		"set -eu",
		"trap 'rm -f \"$0\"' 0 HUP INT TERM",
		"/usr/libexec/opencode-runtime install " .. util.shellquote(base),
		"/etc/init.d/opencode restart || true"
	}, "\n") .. "\n"
	if not fs.writefile(script, body) or sys.call("chmod 0600 " .. util.shellquote(script)) ~= 0 then
		fs.unlink(script);write_json({ ok = false, error = "failed to create install task" });return
	end
	local command = "/bin/sh " .. util.shellquote(script)
	if sys.call("/etc/init.d/tasks task_add " .. task_id .. " " .. util.shellquote(command) .. " >/dev/null 2>&1") ~= 0 then
		fs.unlink(script);write_json({ ok = false, error = "failed to start install task" });return
	end
	write_json({ ok = true, task_id = task_id })
end
