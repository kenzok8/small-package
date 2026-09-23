local source_root = assert(os.getenv("LINKEASE_APPS_SOURCE_ROOT"), "LINKEASE_APPS_SOURCE_ROOT is required")
package.path = source_root .. "/?.lua;" .. package.path

local apps_http = require "luci.model.linkease.apps_http"

local function equal(actual, expected, message)
	if actual ~= expected then
		error((message or "values differ") .. ": got " .. tostring(actual) .. ", want " .. tostring(expected), 2)
	end
end

local function invoke(decision, action, id)
	local output = { id = id }
	local http = {
		formvalue = function(name) if name == "id" then return output.id end end,
		status = function(code) output.status = code end,
		prepare_content = function(value) output.content_type = value end,
		write_json = function(value) output.body = value end,
		redirect = function(value) output.redirect = value end,
		urlencode = function(value)
			return (value:gsub("([^A-Za-z0-9._~-])", function(char)
				return string.format("%%%02X", char:byte())
			end))
		end
	}
	local resolver = {
		status = function() return decision end,
		resolve = function() return decision end
	}
	local handler = apps_http.new({
		http = http,
		resolver = resolver,
		auth_url = "/cgi-bin/luci/admin/services/linkease_auth/auth"
	})
	handler[action](handler)
	return output
end

local valid = {
	schemaVersion = 1, id = "dockermanager", registered = true, available = true,
	mode = "apps", url = "/apps/dockermanager/", worker = "gateway",
	reason = "entry_available", proxy = { supported = true, enabled = true }
}

local response = invoke(valid, "status", "dockermanager")
equal(response.status, 200)
equal(response.content_type, "application/json")
equal(response.body.schemaVersion, 1)

response = invoke(valid, "open", "dockermanager")
equal(response.status, nil)
equal(response.redirect, "/cgi-bin/luci/admin/services/linkease_auth/auth?return=%2Fapps%2Fdockermanager%2F")

response = invoke({ reason = "invalid_id", registered = false, available = false }, "status", "../bad")
equal(response.status, 400)

response = invoke({ reason = "not_registered", registered = false, available = false }, "status", "missing")
equal(response.status, 404)

response = invoke({ reason = "entry_unavailable_and_external_disabled", registered = true, available = false }, "open", "dockermanager")
equal(response.status, 503)
equal(response.body.available, false)

print("linkease apps HTTP boundary tests passed")
