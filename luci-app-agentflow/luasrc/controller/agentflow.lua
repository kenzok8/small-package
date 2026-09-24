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
	entry({"admin", "services", "agentflow_status"}, call("agentflow_status"))
	local open = entry({"admin", "services", "agentflow", "open"}, call("agentflow_open"))
	open.leaf = true
	open.dependent = false
	open.sysauth = false

	if not nixio.fs.access("/etc/config/agentflow") then return end

	local install = entry({"admin", "services", "agentflow", "agent_install"}, call("agentflow_agent_install"))
	install.leaf = true

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

local function node_modules_root()
	local sys = require "luci.sys"
	local util = require "luci.util"
	local script = table.concat({
		'. /lib/functions/mise.sh 2>/dev/null || exit 1',
		'istore_runtime_env >/dev/null 2>&1 || exit 1',
		'mise_bin="$(command -v mise-istore || command -v mise)"',
		'[ -n "$mise_bin" ] || exit 1',
		'node_dir="$("$mise_bin" where node@lts 2>/dev/null)"',
		'[ -n "$node_dir" ] || exit 1',
		'printf "%s/lib/node_modules" "$node_dir"'
	}, "; ")
	local root = sys.exec("/bin/sh -c " .. util.shellquote(script)) or ""
	root = root:match("^%s*(.-)%s*$")
	if root == "" or root:sub(1, 1) ~= "/" then
		return nil
	end
	return root
end

local function agent_commands_ready()
	local sys = require "luci.sys"
	local script = {
		'. /lib/functions/mise.sh 2>/dev/null || exit 1',
		'istore_runtime_env >/dev/null 2>&1 || exit 1',
		'probe_prefix="/tmp/agentflow-agent-probe.$$"',
		'cleanup_agentflow_probe() { rm -f "$probe_prefix".*; }',
		'trap cleanup_agentflow_probe 0 HUP INT TERM',
		'check_agent_version() {',
		'\tshim="$1"',
		'\toutput="$2"',
		'\t"$shim" --version >"$output" 2>/dev/null &',
		'\tchild_pid=$!',
		'\t(',
		'\t\ttimer_pid=""',
		'\t\tstop_timer() {',
		'\t\t\t[ -z "$timer_pid" ] || kill "$timer_pid" 2>/dev/null',
		'\t\t\texit 0',
		'\t\t}',
		'\t\ttrap stop_timer TERM INT',
		'\t\tsleep 5 &',
		'\t\ttimer_pid=$!',
		'\t\twait "$timer_pid" 2>/dev/null || exit 0',
		'\t\tkill "$child_pid" 2>/dev/null',
		'\t) &',
		'\twatchdog_pid=$!',
		'\twait "$child_pid"',
		'\trc=$?',
		'\tkill "$watchdog_pid" 2>/dev/null',
		'\twait "$watchdog_pid" 2>/dev/null',
		'\t[ "$rc" -eq 0 ] && [ -s "$output" ]',
		'}'
	}

	for _, agent in ipairs(AGENTS) do
		script[#script + 1] = 'shim="$HOME/.local/share/mise/shims/' .. agent.command .. '"'
		script[#script + 1] = 'if [ -x "$shim" ] && check_agent_version "$shim" "$probe_prefix.' .. agent.id .. '"; then printf "ready:%s\\n" "' .. agent.id .. '"; fi'
	end

	local output = sys.exec(table.concat(script, "\n")) or ""
	local ready = {}
	for id in output:gmatch("ready:([%w%-]+)") do
		ready[id] = true
	end
	return ready
end

local function agent_statuses()
	local fs = require "nixio.fs"
	local jsonc = require "luci.jsonc"
	local root = node_modules_root()
	local command_ready = root and agent_commands_ready() or {}
	local statuses = {}

	for _, agent in ipairs(AGENTS) do
		local status = { id = agent.id, installed = false }
		if root then
			local package_file = root .. "/" .. agent.package .. "/package.json"
			local package_data = fs.readfile(package_file)
			local package_json = package_data and jsonc.parse(package_data) or nil
			local package_valid = type(package_json) == "table"
				and type(package_json.version) == "string"
				and package_json.version ~= ""
			if package_valid and command_ready[agent.id] == true then
				status.installed = true
				status.version = package_json.version
			end
		end
		statuses[#statuses + 1] = status
	end

	return statuses, root ~= nil
end

function agentflow_status()
	local sys = require "luci.sys"
	local uci = require "luci.model.uci".cursor()
	local agents, agents_available = agent_statuses()
	compat():legacy_status("agentflow", {
		running = sys.call("pidof agentflow >/dev/null") == 0,
		port = uci:get_first("agentflow", "agentflow", "port") or "9000",
		base_path = uci:get_first("agentflow", "agentflow", "base_path") or "/apps/agentflow/",
		agents_available = agents_available,
		agents = agents
	})
end

function agentflow_agent_install()
	local fs = require "nixio.fs"
	local jsonc = require "luci.jsonc"
	local sys = require "luci.sys"
	local util = require "luci.util"
	local task_id = "agentflow-agent-install"
	local task_script = "/tmp/agentflow-agent-install.sh"
	local installer_url = "https://fw.koolcenter.com/binary/geili/agentflow/releases/installapp/installapp-mise.sh"
	local supported_agents = {}
	for _, supported_agent in ipairs(AGENTS) do
		supported_agents[supported_agent.id] = true
	end

	if not require_post_csrf() then
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
	if not fs.access("/lib/functions/mise.sh") then
		write_json({ ok = false, error = "mise environment helper is not available" })
		return
	end

	local task_status = sys.exec("/etc/init.d/tasks task_status " .. task_id .. " 2>/dev/null")
	local status = jsonc.parse(task_status) or {}
	local running = type(status) == "table" and status.running
	if running == true or running == 1 or running == "1" or running == "true" then
		write_json({ ok = true, busy = true, task_id = task_id })
		return
	end

	local install_script = table.concat({
		"set -e",
		"agent=" .. util.shellquote(agent),
		"installer_url=" .. util.shellquote(installer_url),
		'installer="/tmp/agentflow-installapp-mise.$$"',
		'cleanup() { rm -f "$installer" "$0"; }',
		"trap cleanup 0 HUP INT TERM",
		'. /lib/functions/mise.sh',
		'if ! istore_runtime_env; then echo "[agentflow] Failed to initialize the shared runtime environment" >&2; exit 1; fi',
		"set -u",
		"export MISE_YES=1",
		'echo "[agentflow] Downloading installer: $installer_url"',
		'if command -v wget >/dev/null 2>&1; then',
		'\twget -O "$installer" "$installer_url"',
		'elif command -v curl >/dev/null 2>&1; then',
		'\tcurl -fL -o "$installer" "$installer_url"',
		'elif command -v uclient-fetch >/dev/null 2>&1; then',
		'\tuclient-fetch -O "$installer" "$installer_url"',
		"else",
		'\techo "[agentflow] No HTTPS download tool is available" >&2',
		"\texit 1",
		"fi",
		'if [ ! -s "$installer" ]; then echo "[agentflow] Failed to download the agent installer" >&2; exit 1; fi',
		'chmod 0700 "$installer"',
		'echo "[agentflow] Running installapp-mise.sh for $agent in $HOME"',
		'/bin/sh "$installer" "$agent"'
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
