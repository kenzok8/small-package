local source_root = assert(os.getenv("LINKEASE_APPS_SOURCE_ROOT"), "LINKEASE_APPS_SOURCE_ROOT is required")
package.path = source_root .. "/?.lua;" .. package.path

local apps = require "luci.model.linkease.apps"

local function equal(actual, expected, message)
	if actual ~= expected then
		error((message or "values differ") .. ": got " .. tostring(actual) .. ", want " .. tostring(expected), 2)
	end
end

local function engine(options)
	options = options or {}
	local registrations = options.registrations or {
		dockermanager = { id = "dockermanager", url = "/apps/dockermanager/" }
	}
	return apps.new({
		lookup = function(id)
			return registrations[id]
		end,
		entry_status = function()
			return options.entry or {
				available = true,
				worker = "gateway",
				proxy_supported = true,
				proxy_enabled = true
			}
		end,
		external_status = function(app)
			if options.external then
				return options.external[app.id]
			end
			return nil
		end
	})
end

local invalid = engine():resolve("../dockermanager")
equal(invalid.reason, "invalid_id")
equal(invalid.registered, false)
equal(invalid.available, false)

local missing = engine():resolve("unknown")
equal(missing.reason, "not_registered")
equal(missing.registered, false)

local routed = engine():resolve("dockermanager")
equal(routed.mode, "apps")
equal(routed.url, "/apps/dockermanager/")
equal(routed.worker, "gateway")
equal(routed.available, true)
equal(routed.proxy.supported, true)
equal(routed.proxy.enabled, true)

local full = engine({ entry = {
	available = true,
	worker = "linkeasefull",
	proxy_supported = true,
	proxy_enabled = true
} }):status("dockermanager")
equal(full.mode, "apps")
equal(full.worker, "linkeasefull")

local builtin = engine({
	registrations = {
		["openwrt-luci"] = {
			id = "openwrt-luci", url = "/apps/openwrt-luci/", entry_supported = false
		}
	}
}):status("openwrt-luci")
equal(builtin.registered, true)
equal(builtin.available, false)
equal(builtin.mode, "unavailable")
equal(builtin.reason, "entry_unsupported_and_external_unavailable")

local external = engine({
	entry = { available = false, worker = "stopped", proxy_supported = false, proxy_enabled = false },
	external = { dockermanager = { available = true, url = "http://192.168.30.7:8192/apps/dockermanager/" } }
}):resolve("dockermanager")
equal(external.mode, "external")
equal(external.available, true)
equal(external.url, "http://192.168.30.7:8192/apps/dockermanager/")
equal(external.reason, "external_available")

local unavailable = engine({
	entry = { available = false, worker = "stopped", proxy_supported = true, proxy_enabled = true },
	external = { dockermanager = { available = false, reason = "external_disabled" } }
}):resolve("dockermanager")
equal(unavailable.mode, "unavailable")
equal(unavailable.available, false)
equal(unavailable.registered, true)
equal(unavailable.reason, "entry_unavailable_and_external_disabled")

print("linkease apps decision tests passed")
