local http = require "luci.http"

module("luci.controller.agentflow", package.seeall)

local AGENTS = {
	{ id = "codexcli", package = "@openai/codex", command = "codex" },
	{ id = "claude-code", package = "@anthropic-ai/claude-code", command = "claude" },
	{ id = "opencode", package = "opencode-ai", command = "opencode" },
	{ id = "kimi", package = "@moonshot-ai/kimi-code", command = "kimi" },
	{ id = "reasonix", package = "reasonix", command = "reasonix" }
}

function index()
	local status = entry({"admin", "services", "agentflow_status"}, call("agentflow_status"))
	status.acl_depends = { "luci-app-agentflow" }
	local open = entry({"admin", "services", "agentflow", "open"}, call("agentflow_open"))
	open.leaf = true
	open.dependent = false
	open.sysauth = false

	if not nixio.fs.access("/etc/config/agentflow") then return end

	local install = entry({"admin", "services", "agentflow", "agent_install"}, call("agentflow_agent_install"))
	install.leaf = true
	install.acl_depends = { "luci-app-agentflow" }

	entry({"admin", "services", "agentflow"}, cbi("agentflow"), _("AgentFlow"), 100).dependent = true
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
	local access = require("luci.util").ubus("session", "access", {
		ubus_rpc_session = context.authsession, scope = "access-group",
		object = "luci-app-agentflow", ["function"] = "write"
	})
	if not access or access.access ~= true then
		http.status(403, "Forbidden")
		write_json({ ok = false, error = "write permission required" })
		return false
	end

	return true
end

local function compat()
	local dispatcher = require "luci.dispatcher"
	return require("luci.model.linkease.apps_compat").new({
		http = http,
		resolver = require("luci.model.linkease.apps_openwrt").new(),
		auth_url = dispatcher.build_url("admin", "services", "linkease_auth", "auth")
	})
end

local function runtime_status()
 local output = require("luci.sys").exec("/usr/libexec/agentflow-runtime status 2>/dev/null")
 local state = require("luci.jsonc").parse(output or "")
 return type(state) == "table" and state or { agents = {}, agents_available = false,
  runtime = { ready = false, error = "Shared runtime is not available" } }
end

function agentflow_status()
	local sys = require "luci.sys"
	local uci = require "luci.model.uci".cursor()
	local state = runtime_status()
	compat():legacy_status("agentflow", {
		running = sys.call("pidof agentflow >/dev/null") == 0,
		port = uci:get_first("agentflow", "agentflow", "port") or "9000",
		base_path = uci:get_first("agentflow", "agentflow", "base_path") or "/apps/agentflow/",
		agents_available = state.agents_available,
		agents = state.agents,
		runtime = state.runtime
	})
end

function agentflow_agent_install()
	local fs = require "nixio.fs"
	local jsonc = require "luci.jsonc"
	local sys = require "luci.sys"
	local util = require "luci.util"
	local task_id = "agentflow-agent-install"
	local supported_agents = {}
	for _, supported_agent in ipairs(AGENTS) do
		supported_agents[supported_agent.id] = true
	end

	if not require_post_csrf() then
		return
	end
	if http.formvalue("operation") == "recover" then
		local base = require("luci.model.uci").cursor():get_first("agentflow", "agentflow", "data_dir", "")
		local rc = sys.call("/usr/libexec/agentflow-runtime recover " .. util.shellquote(base) .. " >/dev/null 2>&1")
		write_json({ ok = rc == 0, error = rc ~= 0 and "Cannot recover a running or unknown install task" or nil })
		return
	end

	local agent = http.formvalue("agent") or ""
	if not supported_agents[agent] then
		write_json({ ok = false, error = "unsupported agent" })
		return
	end
	if not fs.access("/etc/init.d/tasks") then
		write_json({ ok = false, error = "taskd is not available" })
		return
	end
	if not fs.access("/usr/libexec/agentflow-runtime", "x") then
		write_json({ ok = false, error = "shared runtime integration is not available" })
		return
	end

	local task_status = sys.exec("/etc/init.d/tasks task_status " .. task_id .. " 2>/dev/null")
	local status = jsonc.parse(task_status) or {}
	local running = type(status) == "table" and status.running
	if running == true or running == 1 or running == "1" or running == "true" then
		write_json({ ok = true, busy = true, task_id = task_id })
		return
	end

 local base = require("luci.model.uci").cursor():get_first("agentflow", "agentflow", "data_dir", "")
 if sys.call("/usr/libexec/agentflow-runtime prepare " .. util.shellquote(base) .. " >/dev/null 2>&1") ~= 0 then
  write_json({ ok = false, error = "Configure persistent AgentFlow and shared runtime directories first" })
  return
 end
 local task_script = base .. "/.runtime/work/install-agent-" .. require("nixio").getpid() .. ".sh"
 if fs.lstat(task_script) then
  write_json({ ok = false, error = "An install task file already exists; inspect the previous task" })
  return
 end
 local install_script = table.concat({
  "set -eu",
  "trap 'rm -f \"$0\"' 0 HUP INT TERM",
  "/usr/libexec/agentflow-runtime install " .. util.shellquote(base) .. " " .. util.shellquote(agent)
 }, "\n")
	if not fs.writefile(task_script, install_script .. "\n") then
		write_json({ ok = false, error = "failed to create install task", task_id = task_id })
		return
	end
	if sys.call("chmod 0600 " .. util.shellquote(task_script)) ~= 0 then
		fs.unlink(task_script)
		write_json({ ok = false, error = "failed to secure install task", task_id = task_id })
		return
	end

	local command = "/bin/sh " .. util.shellquote(task_script)
	local rc = sys.call("/etc/init.d/tasks task_add " .. task_id .. " " .. util.shellquote(command) .. " >/dev/null 2>&1")
	if rc ~= 0 then
		fs.unlink(task_script)
		write_json({ ok = false, error = "failed to start install task", task_id = task_id })
		return
	end

	write_json({ ok = true, task_id = task_id })
end

function agentflow_open()
	compat():open("agentflow")
end
