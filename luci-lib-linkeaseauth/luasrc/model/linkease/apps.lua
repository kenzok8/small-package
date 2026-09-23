local M = {}
local Engine = {}
Engine.__index = Engine

local function valid_id(id)
	return type(id) == "string"
		and id:match("^[a-z0-9][a-z0-9_-]*$") ~= nil
		and #id <= 64
end

local function safe_apps_url(value, id)
	if type(value) ~= "string" then
		return "/apps/" .. id .. "/"
	end
	local expected = "/apps/" .. id
	if value == expected or value:sub(1, #expected + 1) == expected .. "/" then
		return value
	end
	return "/apps/" .. id .. "/"
end

local function safe_external_url(value)
	return type(value) == "string"
		and #value <= 2048
		and value:match("^https?://[^/@]+%f[/]") ~= nil
		and value:find("[%c]") == nil
end

local function base_result(id, entry)
	entry = type(entry) == "table" and entry or {}
	return {
		schemaVersion = 1,
		id = id,
		registered = false,
		available = false,
		mode = "unavailable",
		worker = entry.worker or "unknown",
		proxy = {
			supported = entry.proxy_supported == true,
			enabled = entry.proxy_enabled == true
		}
	}
end

local function adapter_call(adapter, name, ...)
	local fn = adapter[name]
	if type(fn) ~= "function" then
		return nil
	end
	local ok, value = pcall(fn, ...)
	if not ok then
		return nil
	end
	return value
end

function M.new(adapter)
	assert(type(adapter) == "table", "apps decision adapter is required")
	return setmetatable({ adapter = adapter }, Engine)
end

function Engine:resolve(id)
	if not valid_id(id) then
		local result = base_result(type(id) == "string" and id or "", nil)
		result.reason = "invalid_id"
		return result
	end

	local app = adapter_call(self.adapter, "lookup", id)
	if type(app) ~= "table" then
		local result = base_result(id, nil)
		result.reason = "not_registered"
		return result
	end

	local entry = adapter_call(self.adapter, "entry_status")
	local result = base_result(id, entry)
	result.registered = true
	if type(entry) == "table"
		and app.entry_supported ~= false
		and entry.available == true
		and entry.proxy_supported == true
		and entry.proxy_enabled == true
		and (entry.worker == "gateway" or entry.worker == "linkeasefull") then
		result.available = true
		result.mode = "apps"
		result.url = safe_apps_url(app.url, id)
		result.reason = "entry_available"
		return result
	end

	local external = adapter_call(self.adapter, "external_status", app)
	if type(external) == "table" and external.available == true and safe_external_url(external.url) then
		result.available = true
		result.mode = "external"
		result.url = external.url
		result.reason = "external_available"
		return result
	end

	local entry_reason = app.entry_supported == false and "entry_unsupported" or "entry_unavailable"
	local external_reason = type(external) == "table" and external.reason or "external_unavailable"
	result.reason = entry_reason .. "_and_" .. tostring(external_reason)
	return result
end

function Engine:status(id)
	return self:resolve(id)
end

M.valid_id = valid_id

return M
