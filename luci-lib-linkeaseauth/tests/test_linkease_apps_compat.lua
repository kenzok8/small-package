local source_root = assert(os.getenv("LINKEASE_APPS_SOURCE_ROOT"), "LINKEASE_APPS_SOURCE_ROOT is required")
package.path = source_root .. "/?.lua;" .. package.path

local compat_module = require "luci.model.linkease.apps_compat"
local output = {}
local decision = {
	schemaVersion = 1, id = "dockermanager", registered = true, available = true,
	mode = "apps", url = "/apps/dockermanager/", worker = "gateway",
	proxy = { supported = true, enabled = true }, reason = "entry_available"
}
local http = {
	status = function(code) output.status = code end,
	prepare_content = function(value) output.content_type = value end,
	write_json = function(value) output.body = value end,
	redirect = function(value) output.redirect = value end,
	urlencode = function(value) return (value:gsub("/", "%%2F")) end
}
local compat = compat_module.new({
	http = http,
	resolver = { resolve = function() return decision end, status = function() return decision end },
	auth_url = "/auth"
})

compat:open("dockermanager")
assert(output.redirect == "/auth?return=%2Fapps%2Fdockermanager%2F")

compat:legacy_status("dockermanager", { running = true, external_port_enabled = false })
assert(output.status == 200)
assert(output.body.running == true)
assert(output.body.entry_url == "/apps/dockermanager/")
assert(output.body.proxy_prefix_supported == true)
assert(output.body.proxy_prefix_enabled == true)
assert(output.body.app_entry_running == true)
assert(output.body.access == decision)

print("linkease apps compatibility tests passed")
