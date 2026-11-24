module("luci.controller.dockergo", package.seeall)

local http = require "luci.http"
local jsonc = require "luci.jsonc"
local sys = require "luci.sys"
local fs = require "nixio.fs"

local LIST_COMMAND = "docker ps --all --no-trunc --format '{{json .}}'"
local EXIT_MARKER = "__DOCKERGO_EXIT__"
local INSTALL_TASK_DIR = "/var/run/dockergo"
local INSTALL_TASK_ID = "dockergo"
local INSTALL_RUNNER = "/usr/libexec/dockergo-install"
local CATALOG_SOURCE = "https://github.com/Carseason/dockergo/releases/download/apps/apps.json"
local CATALOG_MAX_BYTES = 1024 * 1024

local function valid_restart(value)
	return value == "no" or value == "always" or value == "unless-stopped" or value == "on-failure"
end

function index()
	local page = entry({"admin", "dockergo"}, view("dockergo/index"), _("DockerGo"), 70)
	page.depends = {fs = {["/usr/bin/docker"] = "executable"}}
	entry({"admin", "dockergo", "installed"}, view("dockergo/index"))
	entry({"admin", "dockergo", "market"}, view("dockergo/index")).leaf = true

	-- Hidden compatibility pages; existing API paths remain unchanged.
	entry({"admin", "services", "dockergo"}, view("dockergo/index")).depends = page.depends
	entry({"admin", "services", "dockergo", "installed"}, view("dockergo/index"))
	entry({"admin", "services", "dockergo", "market"}, view("dockergo/index")).leaf = true

	entry({"admin", "services", "dockergo", "api", "apps.json"}, call("api_apps")).leaf = true
	entry({"admin", "services", "dockergo", "api", "files"}, call("api_list_files")).leaf = true
	entry({"admin", "services", "dockergo", "api", "install"}, post("api_install_app")).leaf = true
	entry({"admin", "services", "dockergo", "api", "containers"}, call("api_list_containers")).leaf = true
	entry({"admin", "services", "dockergo", "api", "inspect"}, call("api_inspect_container")).leaf = true
	entry({"admin", "services", "dockergo", "api", "logs"}, call("api_container_logs")).leaf = true
	entry({"admin", "services", "dockergo", "api", "control"}, post("api_control_container")).leaf = true
	entry({"admin", "services", "dockergo", "api", "remove"}, post("api_remove_container")).leaf = true
end

local function valid_directory_path(path)
	if path == "/mnt" then
		return true
	end

	if type(path) ~= "string" or #path > 240 or path:sub(1, 5) ~= "/mnt/" or
		path:sub(-1) == "/" or path:find("//", 1, true) ~= nil then
		return false
	end

	for segment in path:sub(6):gmatch("[^/]+") do
		if segment:match("^[A-Za-z0-9][A-Za-z0-9._-]*$") == nil then
			return false
		end
	end

	return true
end

local function directory_exists_without_links(path)
	if fs.lstat("/mnt", "type") ~= "dir" then
		return false
	end

	local current = "/mnt"
	for segment in path:sub(6):gmatch("[^/]+") do
		current = current .. "/" .. segment
		if fs.lstat(current, "type") ~= "dir" then
			return false
		end
	end

	return true
end

local function valid_catalog(catalog)
	if type(catalog) ~= "table" or catalog.schemaVersion ~= 1 or type(catalog.apps) ~= "table" then
		return false, "应用目录根结构无效"
	end
	if type(catalog.tags) ~= "table" then
		return false, "应用目录顶层标签无效"
	end
	for _, tag in ipairs(catalog.tags) do
		if type(tag) ~= "string" or tag:match("%S") == nil then
			return false, "应用目录顶层标签无效"
		end
	end

	local ids = {}
	for index, app in ipairs(catalog.apps) do
		if type(app) ~= "table" or type(app.id) ~= "string" or app.id == "" or
			type(app.title) ~= "string" or app.title == "" or
			type(app.version) ~= "string" or #app.version > 64 or
			app.version:match("^[A-Za-z0-9][A-Za-z0-9._-]*$") == nil or
			type(app.description) ~= "string" or type(app.image) ~= "string" or app.image == "" or
			type(app.tags) ~= "table" then
			return false, string.format("第 %d 个应用的数据结构无效", index)
		end

		if ids[app.id] then
			return false, string.format("应用 ID %s 重复", app.id)
		end
		ids[app.id] = true

		if app.mode ~= nil or app.autoStart ~= nil then
			return false, string.format("应用 %s 请使用 d、rm、restart 代替 mode、autoStart", app.id)
		end
		if (app.d ~= nil and type(app.d) ~= "boolean") or
			(app.rm ~= nil and type(app.rm) ~= "boolean") or
			(app.restart ~= nil and type(app.restart) ~= "string") or
			not valid_restart(app.restart or "no") or
			(app.rm == true and (app.restart or "no") ~= "no") then
			return false, string.format("应用 %s 的运行或重启配置无效", app.id)
		end

		if app.ports ~= nil and type(app.ports) ~= "table" then
			return false, string.format("应用 %s 的端口配置无效", app.id)
		end
		if app.volumes ~= nil and type(app.volumes) ~= "table" then
			return false, string.format("应用 %s 的存储配置无效", app.id)
		end
		local port_targets = {}
		for _, port in ipairs(app.ports or {}) do
			if type(port) ~= "table" or type(port.target) ~= "number" or
				port.target % 1 ~= 0 or port.target < 1 or port.target > 65535 or
				type(port.port) ~= "number" or port.port % 1 ~= 0 or
				port.port < 1 or port.port > 65535 or type(port.desc) ~= "string" or
				port.desc == "" or port_targets[port.target] then
				return false, string.format("应用 %s 的端口配置无效", app.id)
			end
			port_targets[port.target] = true
		end
		local volume_targets = {}
		for _, volume in ipairs(app.volumes or {}) do
			if type(volume) ~= "table" or type(volume.target) ~= "string" or
				volume.target:sub(1, 1) ~= "/" or type(volume.desc) ~= "string" or
				volume.desc == "" or volume_targets[volume.target] or
				(volume.type ~= "dir" and volume.type ~= "file") or
				(volume.required ~= nil and type(volume.required) ~= "boolean") then
				return false, string.format("应用 %s 的存储配置无效", app.id)
			end
			volume_targets[volume.target] = true
		end
		if app.environment ~= nil and type(app.environment) ~= "table" then
			return false, string.format("应用 %s 的环境变量配置无效", app.id)
		end
		if app.command ~= nil and type(app.command) ~= "table" then
			return false, string.format("应用 %s 的启动命令无效", app.id)
		end
		if app.inputs ~= nil and type(app.inputs) ~= "table" then
			return false, string.format("应用 %s 的运行参数无效", app.id)
		end
		local input_ids = {}
		for _, input in ipairs(app.inputs or {}) do
			if type(input) ~= "table" or type(input.id) ~= "string" or
				#input.id > 64 or input.id:match("^[a-z][a-z0-9_-]*$") == nil or
				type(input.title) ~= "string" or input.title == "" or
				(input.required ~= nil and type(input.required) ~= "boolean") or
				(input.placeholder ~= nil and type(input.placeholder) ~= "string") or
				input_ids[input.id] then
				return false, string.format("应用 %s 的运行参数无效", app.id)
			end
			input_ids[input.id] = true
		end
		local used_inputs = {}
		for _, argument in ipairs(app.command or {}) do
			if type(argument) ~= "string" then
				return false, string.format("应用 %s 的启动命令无效", app.id)
			end
			local input_id = argument:match("^{{([a-z][a-z0-9_-]*)}}$")
			if input_id then
				if not input_ids[input_id] then
					return false, string.format("应用 %s 的命令引用了未知参数", app.id)
				end
				used_inputs[input_id] = true
			elseif argument:find("{{", 1, true) or argument:find("}}", 1, true) then
				return false, string.format("应用 %s 的命令占位符无效", app.id)
			end
		end
		for input_id in pairs(input_ids) do
			if not used_inputs[input_id] then
				return false, string.format("应用 %s 存在未使用的运行参数", app.id)
			end
		end
	end

	return true
end

local function string_value(value)
	if value == nil then
		return ""
	end

	return tostring(value)
end

local function valid_container_id(container_id)
	return container_id ~= nil and container_id:match("^[a-f0-9][a-f0-9]+$") ~= nil and
		#container_id >= 12 and #container_id <= 64
end

local function write_json(status, payload)
	http.status(status)
	http.header("Cache-Control", "no-store")
	http.prepare_content("application/json")
	http.write(jsonc.stringify(payload))
end

local function write_error(status, code, message, extra)
	local payload = extra or {}
	payload.success = false
	payload.error = {
		code = code,
		message = message,
	}
	write_json(status, payload)
end

local function run(command)
	local output = sys.exec(command .. " 2>&1; printf '\\n" .. EXIT_MARKER .. "%s' $?") or ""
	local status = tonumber(output:match("\n" .. EXIT_MARKER .. "(%d+)$")) or 255
	output = output:gsub("\n" .. EXIT_MARKER .. "%d+$", "")
	return status, output
end

local function load_catalog()
	local id = sys.uniqueid(16)
	local temporary_dir = id and ("/tmp/dockergo-catalog-" .. id)
	if not temporary_dir or not fs.mkdir(temporary_dir, "700") then
		return nil, 500, "CATALOG_DOWNLOAD_FAILED", "无法创建下载临时目录"
	end
	local temporary_path = temporary_dir .. "/apps.json"
	local function cleanup()
		fs.unlink(temporary_path)
		fs.rmdir(temporary_dir)
	end
	local command = "curl --fail --silent --show-error --location --max-redirs 5 " ..
		"--proto '=https' --proto-redir '=https' --connect-timeout 5 --max-time 20 " ..
		"--max-filesize 1048576 --header 'Cache-Control: no-cache, no-store' --output " ..
		require("luci.util").shellquote(temporary_path) .. " " ..
		require("luci.util").shellquote(CATALOG_SOURCE) .. " >/dev/null 2>&1"
	if sys.call(command) ~= 0 then
		cleanup()
		return nil, 503, "CATALOG_DOWNLOAD_FAILED", "无法从 CDN 获取应用目录，请检查设备网络或稍后刷新"
	end
	local contents = fs.readfile(temporary_path, CATALOG_MAX_BYTES + 1)
	cleanup()
	if not contents or #contents == 0 or #contents > CATALOG_MAX_BYTES then
		return nil, 502, "CATALOG_INVALID", "应用目录为空或超过 1 MiB"
	end
	local catalog = jsonc.parse(contents)
	local valid, message = valid_catalog(catalog)
	if not valid then
		return nil, 502, "CATALOG_INVALID", message
	end
	return catalog
end

function api_apps()
	local catalog, status, code, message = load_catalog()
	if not catalog then
		write_error(status, code, message)
		return
	end

	write_json(200, catalog)
end

function api_list_files()
	local path = http.formvalue("path") or "/mnt"
	if not valid_directory_path(path) then
		write_error(400, "INVALID_DIRECTORY_PATH", "只能浏览 /mnt 下的目录")
		return
	end

	if not directory_exists_without_links(path) then
		write_error(404, "DIRECTORY_NOT_FOUND", "目录不存在或不可访问")
		return
	end

	local iterator = fs.dir(path)
	if not iterator then
		write_error(403, "DIRECTORY_UNREADABLE", "无法读取该目录")
		return
	end

	local entries = {}
	for name in iterator do
		if name:match("^[A-Za-z0-9][A-Za-z0-9._-]*$") then
			local child_path = path .. "/" .. name
			local entry_type = fs.lstat(child_path, "type")
			if entry_type == "dir" or entry_type == "reg" then
				entries[#entries + 1] = {
					name = name,
					path = child_path,
					type = entry_type == "dir" and "directory" or "file",
				}
			end
		end
	end

	table.sort(entries, function(left, right)
		if left.type ~= right.type then
			return left.type == "directory"
		end
		return left.name:lower() < right.name:lower()
	end)

	local parent
	if path ~= "/mnt" then
		parent = path:match("^(.*)/[^/]+$") or "/mnt"
		if parent:sub(1, 4) ~= "/mnt" then
			parent = "/mnt"
		end
	end

	write_json(200, {
		success = true,
		path = path,
		parent = parent,
		entries = entries,
	})
end

local function find_catalog_app(catalog, app_id)
	for _, app in ipairs(catalog.apps) do
		if app.id == app_id then
			return app
		end
	end
end

local function valid_app_id(app_id)
	return type(app_id) == "string" and app_id:match("^[a-z0-9][a-z0-9._-]*$") ~= nil and
		#app_id <= 64
end

local function valid_volume_path(path)
	if type(path) ~= "string" or #path > 240 or
		path:find("..", 1, true) ~= nil or path:find("//", 1, true) ~= nil then
		return false
	end

	local app_data_path = path:match("^/docker/apps/[A-Za-z0-9][A-Za-z0-9._/-]*$") ~= nil
	local mounted_data_path = path:match(
		"^/mnt/[A-Za-z0-9][A-Za-z0-9._-]*/[A-Za-z0-9][A-Za-z0-9._/-]*$") ~= nil
	return app_data_path or mounted_data_path
end

local function form_string_array(name, expected_count)
	local encoded = http.formvalue(name)
	local values = encoded and jsonc.parse(encoded)

	if type(values) ~= "table" then
		return nil
	end

	if #values ~= expected_count then
		return nil
	end
	for index = 1, expected_count do
		if type(values[index]) ~= "string" then
			return nil
		end
	end

	return values
end

local function form_input_values(definitions)
	local encoded = http.formvalue("inputs") or "{}"
	local values = jsonc.parse(encoded)
	if type(values) ~= "table" then
		return nil
	end

	local declared = {}
	for _, definition in ipairs(definitions) do
		declared[definition.id] = definition
	end
	for id, value in pairs(values) do
		if type(id) ~= "string" or not declared[id] or type(value) ~= "string" or
			#value > 2048 or value:find("[%z\1-\31\127]") then
			return nil
		end
	end
	for id, definition in pairs(declared) do
		local value = values[id] or ""
		if definition.required == true and value:match("%S") == nil then
			return nil
		end
		values[id] = value
	end

	return values
end

function api_install_app()
	local app_id = http.formvalue("appId")
	if not valid_app_id(app_id) then
		write_error(400, "INVALID_APP_ID", "应用 ID 无效")
		return
	end
	local instance_id = http.formvalue("instanceId")
	if type(instance_id) ~= "string" or #instance_id ~= 8 or
		instance_id:match("^[a-f0-9]+$") == nil then
		write_error(400, "INVALID_INSTANCE_ID", "实例 ID 必须为 8 位小写十六进制字符")
		return
	end
	local start_now = http.formvalue("startNow")
	if start_now ~= nil and start_now ~= "0" and start_now ~= "1" then
		write_error(400, "INVALID_START_OPTION", "立即启动选项必须为 1 或 0")
		return
	end

	local catalog, status, code, message = load_catalog()
	if not catalog then
		write_error(status, code, message)
		return
	end

	local app = find_catalog_app(catalog, app_id)
	if not app then
		write_error(404, "APP_NOT_FOUND", "应用目录中不存在该应用")
		return
	end
	local restart = http.formvalue("restart") or app.restart or "no"
	if not valid_restart(restart) or (app.rm == true and restart ~= "no") then
		write_error(400, "INVALID_RESTART", "重启策略无效，自动清理容器只能使用 no")
		return
	end

	local ports = app.ports or {}
	local volumes = app.volumes or {}
	local requested_ports = form_string_array("ports", #ports)
	if not requested_ports then
		write_error(400, "INVALID_PORTS", "端口配置数量与应用目录不一致")
		return
	end

	local task_ports = {}
	local used_host_ports = {}
	for index, port in ipairs(ports) do
		local host_port = tonumber(requested_ports[index])
		if not host_port or host_port % 1 ~= 0 or host_port < 1 or host_port > 65535 or
			type(port.target) ~= "number" or port.target % 1 ~= 0 or
			port.target < 1 or port.target > 65535 or used_host_ports[host_port] then
			write_error(400, "INVALID_PORT", "端口配置无效")
			return
		end
		used_host_ports[host_port] = true
		task_ports[#task_ports + 1] = {
			port = host_port,
			target = port.target,
		}
	end

	local requested_volumes = form_string_array("volumes", #volumes)
	if not requested_volumes then
		write_error(400, "INVALID_VOLUMES", "存储映射数量与应用目录不一致")
		return
	end

	local task_volumes = {}
	for index, volume in ipairs(volumes) do
		local requested_path = requested_volumes[index]
		if requested_path == "" and volume.required == true then
			write_error(400, "REQUIRED_VOLUME_MISSING", volume.desc .. "必须选择映射路径")
			return
		elseif requested_path ~= "" then
			if not valid_volume_path(requested_path) then
				write_error(400, "INVALID_VOLUME_PATH",
					"映射路径必须位于 /docker/apps/ 或 /mnt/<磁盘>/ 下")
				return
			end
			task_volumes[#task_volumes + 1] = {
				source = requested_path,
				target = volume.target,
				type = volume.type,
			}
		end
	end

	local environment = app.environment or {}
	for key, value in pairs(environment) do
		if type(key) ~= "string" or key:match("^[A-Za-z_][A-Za-z0-9_]*$") == nil or
			type(value) ~= "string" then
			write_error(502, "CATALOG_INVALID", "应用环境变量配置无效")
			return
		end
	end

	local input_values = form_input_values(app.inputs or {})
	if not input_values then
		write_error(400, "INVALID_INPUTS", "运行参数无效或缺少必填项")
		return
	end

	local command = {}
	for _, argument in ipairs(app.command or {}) do
		local input_id = argument:match("^{{([a-z][a-z0-9_-]*)}}$")
		command[#command + 1] = input_id and input_values[input_id] or argument
	end

	local config_id = "dockergo-install-" .. app.id .. "-" .. instance_id
	local task_path = INSTALL_TASK_DIR .. "/" .. config_id .. ".json"
	local task_config = {
		appId = app.id,
		title = app.title,
		version = app.version,
		image = app.image,
		d = app.d ~= false,
		rm = app.rm == true,
		restart = restart,
		instanceId = instance_id,
		startNow = start_now ~= "0",
		containerName = "dgo_" .. app.id .. "_" .. app.version .. "_" .. instance_id,
		environment = environment,
		command = command,
		ports = task_ports,
		volumes = task_volumes,
	}

	local current_task = require("luci.model.tasks").status(INSTALL_TASK_ID)
	if current_task.running then
		write_error(409, "TASK_BUSY", "DockerGo 安装任务正在执行，请等待当前任务完成")
		return
	end
	local list_status, names = run("docker ps --all --format '{{.Names}}'")
	if list_status ~= 0 then
		write_error(503, "DOCKER_UNAVAILABLE", "无法检查容器名称，请确认 Docker 服务正常")
		return
	end
	for name in names:gmatch("[^\r\n]+") do
		if name == task_config.containerName then
			write_error(409, "CONTAINER_NAME_CONFLICT", "容器名称已存在，请关闭弹窗重新创建实例")
			return
		end
	end

	if sys.call("mkdir -p " .. INSTALL_TASK_DIR .. " && chmod 700 " .. INSTALL_TASK_DIR) ~= 0 then
		write_error(500, "TASK_CONFIG_FAILED", "无法创建安装任务目录")
		return
	end

	local file = io.open(task_path, "w")
	if not file then
		write_error(500, "TASK_CONFIG_FAILED", "无法保存安装任务配置")
		return
	end
	file:write(jsonc.stringify(task_config))
	file:close()
	sys.call("chmod 600 " .. task_path)

	local task_command = INSTALL_RUNNER .. " " .. config_id
	local launch_command = string.format("/etc/init.d/tasks task_add %s %s -1 >/dev/null 2>&1",
		INSTALL_TASK_ID, require("luci.util").shellquote(task_command))
	if sys.call(launch_command) ~= 0 then
		os.remove(task_path)
		local task_status = require("luci.model.tasks").status(INSTALL_TASK_ID)
		if task_status.running then
			write_error(409, "TASK_BUSY", "DockerGo 安装任务正在执行，请等待当前任务完成")
		else
			write_error(500, "TASK_START_FAILED", "无法启动安装任务")
		end
		return
	end

	write_json(202, {
		success = true,
		taskId = INSTALL_TASK_ID,
		containerName = task_config.containerName,
	})
end

local function container_identity(name, catalog)
	local body, instance_id = name:match("^dgo_(.+)_([a-f0-9]+)$")
	if not body or #instance_id ~= 8 then
		return false, "", "", ""
	end

	local known_ids = {}
	for _, app in ipairs(catalog and catalog.apps or {}) do
		known_ids[app.id] = true
	end
	local candidates, known_candidates = {}, {}
	for index = 1, #body do
		if body:sub(index, index) == "_" then
			local id, version = body:sub(1, index - 1), body:sub(index + 1)
			if valid_app_id(id) and #version <= 64 and
				version:match("^[A-Za-z0-9][A-Za-z0-9._-]*$") then
				local candidate = { id = id, version = version }
				candidates[#candidates + 1] = candidate
				if known_ids[id] then
					known_candidates[#known_candidates + 1] = candidate
				end
			end
		end
	end
	if #candidates == 0 then
		return false, "", "", ""
	end

	-- A unique catalog ID disambiguates underscores without trusting the current version.
	local identity
	if #known_candidates == 1 then
		identity = known_candidates[1]
	elseif #known_candidates == 0 and #candidates == 1 then
		identity = candidates[1]
	end
	-- Ambiguous names remain visible, but must not be linked to the wrong application.
	return true, identity and identity.id or "", identity and identity.version or "", instance_id
end

local function normalize_container(raw, catalog)
	local name = string_value(raw.Names)
	local managed, app_id, app_version, instance_id = container_identity(name, catalog)
	return {
		id = string_value(raw.ID),
		name = name,
		image = string_value(raw.Image),
		command = string_value(raw.Command),
		createdAt = string_value(raw.CreatedAt),
		runningFor = string_value(raw.RunningFor),
		ports = string_value(raw.Ports),
		state = string_value(raw.State),
		status = string_value(raw.Status),
		networks = string_value(raw.Networks),
		mounts = string_value(raw.Mounts),
		managed = managed,
		appId = app_id,
		appVersion = app_version,
		instanceId = instance_id,
	}
end

function api_list_containers()
	local status, output = run(LIST_COMMAND)
	if status ~= 0 then
		write_error(503, "DOCKER_UNAVAILABLE", output ~= "" and output or
			"Docker 服务不可用或当前用户无法访问 Docker", { containers = {} })
		return
	end

	local catalog = load_catalog()
	local containers = {}
	local malformed = 0
	for line in output:gmatch("[^\r\n]+") do
		local raw = jsonc.parse(line)
		if raw then
			containers[#containers + 1] = normalize_container(raw, catalog)
		else
			malformed = malformed + 1
		end
	end

	if malformed > 0 then
		write_error(502, "DOCKER_OUTPUT_INVALID",
			string.format("有 %d 条 Docker 容器记录无法解析", malformed), { containers = containers })
		return
	end

	write_json(200, {
		containers = containers,
		generatedAt = os.time(),
	})
end

function api_control_container()
	local container_id = http.formvalue("id")
	local action = http.formvalue("action")

	if not valid_container_id(container_id) then
		write_error(400, "INVALID_CONTAINER_ID", "容器 ID 无效")
		return
	end

	if action ~= "start" and action ~= "pause" and action ~= "unpause" then
		write_error(400, "INVALID_ACTION", "不支持的容器操作")
		return
	end

	local status, output = run(string.format("docker %s %s", action, container_id))
	if status ~= 0 then
		write_error(500, "DOCKER_ACTION_FAILED", output ~= "" and output or "Docker 容器操作失败")
		return
	end

	write_json(200, {
		success = true,
		id = container_id,
		action = action,
	})
end

function api_inspect_container()
	local container_id = http.formvalue("id")
	if not valid_container_id(container_id) then
		write_error(400, "INVALID_CONTAINER_ID", "容器 ID 无效")
		return
	end

	local status, output = run(string.format(
		"docker inspect --format '{{json .}}' %s", container_id))
	if status ~= 0 then
		write_error(404, "DOCKER_INSPECT_FAILED", output ~= "" and output or "无法读取容器详情")
		return
	end

	local raw = jsonc.parse(output)
	if not raw then
		write_error(502, "DOCKER_OUTPUT_INVALID", "Docker 返回了无法解析的容器详情")
		return
	end

	write_json(200, {
		success = true,
		container = {
			id = string_value(raw.Id),
			name = string_value(raw.Name),
			image = string_value(raw.Config and raw.Config.Image),
			imageId = string_value(raw.Image),
			createdAt = string_value(raw.Created),
			platform = string_value(raw.Platform),
			driver = string_value(raw.Driver),
			restartPolicy = string_value(raw.HostConfig and raw.HostConfig.RestartPolicy and
				raw.HostConfig.RestartPolicy.Name),
			networkMode = string_value(raw.HostConfig and raw.HostConfig.NetworkMode),
			command = {
				path = string_value(raw.Path),
				args = raw.Args or {},
			},
			state = {
				status = string_value(raw.State and raw.State.Status),
				running = raw.State and raw.State.Running or false,
				paused = raw.State and raw.State.Paused or false,
				restarting = raw.State and raw.State.Restarting or false,
				oomKilled = raw.State and raw.State.OOMKilled or false,
				dead = raw.State and raw.State.Dead or false,
				pid = raw.State and raw.State.Pid or 0,
				exitCode = raw.State and raw.State.ExitCode or 0,
				error = string_value(raw.State and raw.State.Error),
				startedAt = string_value(raw.State and raw.State.StartedAt),
				finishedAt = string_value(raw.State and raw.State.FinishedAt),
				health = string_value(raw.State and raw.State.Health and raw.State.Health.Status),
			},
			ports = raw.NetworkSettings and raw.NetworkSettings.Ports or {},
			networks = raw.NetworkSettings and raw.NetworkSettings.Networks or {},
			mounts = raw.Mounts or {},
		},
	})
end

function api_container_logs()
	local container_id = http.formvalue("id")
	if not valid_container_id(container_id) then
		write_error(400, "INVALID_CONTAINER_ID", "容器 ID 无效")
		return
	end

	local status, output = run(string.format(
		"docker logs --tail 300 --timestamps %s", container_id))
	if status ~= 0 then
		write_error(404, "DOCKER_LOGS_FAILED", output ~= "" and output or "无法读取容器日志")
		return
	end

	local lines = {}
	for line in output:gmatch("[^\r\n]+") do
		lines[#lines + 1] = line
	end

	write_json(200, {
		success = true,
		id = container_id,
		lines = lines,
	})
end

function api_remove_container()
	local container_id = http.formvalue("id")
	if not valid_container_id(container_id) then
		write_error(400, "INVALID_CONTAINER_ID", "容器 ID 无效")
		return
	end

	local status, output = run(string.format(
		"docker rm --force %s", container_id))
	if status ~= 0 then
		write_error(500, "DOCKER_REMOVE_FAILED", output ~= "" and output or "无法卸载容器")
		return
	end

	write_json(200, {
		success = true,
		id = container_id,
	})
end
