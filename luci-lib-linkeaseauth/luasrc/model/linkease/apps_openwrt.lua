local M = {}

local proxy_mapping = "/apps=http://127.0.0.1:19290"
local registration_dirs = {
	"/usr/share/linkease/apps.d",
	"/usr/share/linkeasefull/desktop-apps.d"
}

local function defaults()
	local sys = require "luci.sys"
	return {
		fs = require "nixio.fs",
		http = require "luci.http",
		json = require "luci.jsonc",
		sys = sys,
		read_uci = function(key)
			if type(key) ~= "string" or key:match("^[%w_@%[%].-]+$") == nil then return nil end
			local value = sys.exec("uci -q get " .. string.format("%q", key) .. " 2>/dev/null") or ""
			value = value:match("^%s*(.-)%s*$")
			if value == "" then return nil end
			return value
		end,
		uci = require("luci.model.uci").cursor()
	}
end

local function normalize_path(value, id)
	local path = type(value) == "string" and value or "/apps/" .. id .. "/"
	if path:sub(1, 1) ~= "/" then path = "/" .. path end
	if path:sub(-1) ~= "/" then path = path .. "/" end
	return path
end

local function authority_host(authority)
	if not authority or authority == "" then return "" end
	if authority:sub(1, 1) == "[" then return authority:match("^%[([^%]]+)%]") or "" end
	return authority:match("^([^:]+)") or authority
end

local function url_host(host)
	if host:find(":") and host:sub(1, 1) ~= "[" then return "[" .. host .. "]" end
	return host
end

local function uci_key(cursor, key, read_committed)
	if type(key) ~= "string" then return nil end
	local config, section_type, _, option = key:match("^([%w_-]+)%.@([%w_-]+)%[(%d+)%]%.([%w_-]+)$")
	if config and section_type and option then
		return cursor:get_first(config, section_type, option) or (read_committed and read_committed(key))
	end
	local direct_config, section, direct_option = key:match("^([%w_-]+)%.([%w_-]+)%.([%w_-]+)$")
	if direct_config then return cursor:get(direct_config, section, direct_option) or (read_committed and read_committed(key)) end
	return nil
end

local function configured_value(cursor, specification, read_committed)
	if type(specification) ~= "table" then return nil end
	local keys = specification.keys
	local value = type(keys) == "table" and uci_key(cursor, keys.uci, read_committed) or nil
	if value ~= nil then return value end
	return specification.default
end

local function bool_value(value)
	return value == true or value == 1 or value == "1" or value == "true"
end

function M.new(dependencies)
	local deps = dependencies or defaults()
	local function lookup(id)
		for _, directory in ipairs(deps.registration_dirs or registration_dirs) do
			local iterator = deps.fs.dir(directory)
			if iterator then
				for filename in iterator do
					if filename:match("%.json$") then
						local raw = deps.fs.readfile(directory .. "/" .. filename)
						local manifest = raw and deps.json.parse(raw) or nil
						if type(manifest) == "table" and manifest.id == id then
							local standalone = type(manifest.standalone) == "table" and manifest.standalone or {}
							local desktop = type(manifest.desktop) == "table" and manifest.desktop or {}
							return {
								id = id,
								url = normalize_path(standalone.url or standalone.basePath, id),
								entry_supported = desktop.mode ~= "builtin",
								manifest = manifest
							}
						end
					end
				end
			end
		end
		return nil
	end

	local function entry_status()
		local mappings = deps.uci:get_list("uhttpd", "main", "proxy_prefix") or {}
		local enabled = false
		for _, mapping in ipairs(mappings) do
			if mapping == proxy_mapping then enabled = true end
		end
		-- A synthetic LuCI test session may make the session-aware UCI cursor
		-- hide list values. The committed config remains the source of truth.
		if not enabled then
			local config = deps.fs.readfile("/etc/config/uhttpd") or ""
			enabled = config:find(proxy_mapping, 1, true) ~= nil
		end
		local supported = deps.sys.call("grep -qr 'proxy_prefix' /etc/init.d/uhttpd /lib/functions /usr/share/uhttpd 2>/dev/null") == 0
		local state_path = deps.uci:get("linkease_app_entry", "main", "state_file") or "/var/run/linkease-app-entry/state.json"
		local raw = deps.fs.readfile(state_path)
		local state = raw and deps.json.parse(raw) or {}
		local worker = type(state) == "table" and state.active or "stopped"
		local running = worker == "gateway" or worker == "linkeasefull"
		return {
			available = running and supported and enabled,
			worker = worker,
			proxy_supported = supported,
			proxy_enabled = enabled
		}
	end

	local function external_status(app)
		local desktop = app.manifest.desktop or {}
		local target = type(desktop.target) == "table" and desktop.target or nil
		if desktop.mode == "iframe" and target and target.hostMode == "request-host"
			and (target.scheme == "http" or target.scheme == "https") then
			local port = tonumber(configured_value(deps.uci, target.port, deps.read_uci))
			if not port or port < 1 or port > 65535 or port % 1 ~= 0 then
				return { available = false, reason = "external_invalid" }
			end
			local host = authority_host(deps.http.getenv("HTTP_HOST") or "")
			if host == "" then host = deps.uci:get("network", "lan", "ipaddr") or "127.0.0.1" end
			local external_path = type(target.path) == "string" and target.path or "/"
			if external_path:sub(1, 1) ~= "/" or external_path:sub(1, 2) == "//"
				or external_path:find("[%c]") then
				external_path = "/"
			end
			return {
				available = true,
				url = target.scheme .. "://" .. url_host(host) .. ":" .. tostring(port) .. external_path
			}
		end

		local backend = app.manifest.backend or {}
		local values = type(backend.values) == "table" and backend.values or {}
		local enabled
		local port
		if type(values.externalPortEnabled) == "table" then
			enabled = bool_value(configured_value(deps.uci, values.externalPortEnabled, deps.read_uci))
			port = configured_value(deps.uci, values.port, deps.read_uci)
		else
			enabled = backend.portFromUci ~= nil or backend.defaultPort ~= nil
			port = uci_key(deps.uci, backend.portFromUci, deps.read_uci) or backend.defaultPort
		end
		if not enabled then return { available = false, reason = "external_disabled" } end
		port = tonumber(port)
		if not port or port < 1 or port > 65535 or port % 1 ~= 0 then
			return { available = false, reason = "external_invalid" }
		end
		local host = authority_host(deps.http.getenv("HTTP_HOST") or "")
		if host == "" then host = deps.uci:get("network", "lan", "ipaddr") or "127.0.0.1" end
		local external_path = backend.externalBasePath or app.url
		if type(external_path) ~= "string" or external_path:sub(1, 1) ~= "/"
			or external_path:sub(1, 2) == "//" or external_path:find("[%c]") then
			external_path = app.url
		end
		return {
			available = true,
			url = "http://" .. url_host(host) .. ":" .. tostring(port) .. external_path
		}
	end

	return require("luci.model.linkease.apps").new({
		lookup = lookup,
		entry_status = entry_status,
		external_status = external_status
	})
end

return M
