-- Run on iStoreOS: lua tests/catalog_test.lua luasrc/controller/dockergo.lua
-- Filesystem and network calls are mocked; no device files are changed.
local jsonc = require "luci.jsonc"
require "luci.util"
local stale_path = "/var/run/dockergo/apps.json"
local files, directories = {[stale_path] = "old cached data"}, {}
local downloads, sequence, next_body, next_status = 0, 0, nil, 0
local valid_body = '{"schemaVersion":1,"apps":[],"tags":["Web"]}'

package.loaded["nixio.fs"] = {
	readfile = function(path, limit)
		assert(path ~= stale_path, "persistent cache must never be read")
		return files[path] and files[path]:sub(1, limit)
	end,
	mkdir = function(path, mode)
		assert(path:match("^/tmp/dockergo%-catalog%-%d+$") and mode == "700")
		assert(not directories[path])
		directories[path] = true
		return true
	end,
	unlink = function(path) files[path] = nil return true end,
	rmdir = function(path) directories[path] = nil return true end,
}
package.loaded["luci.sys"] = {
	uniqueid = function() sequence = sequence + 1 return tostring(sequence) end,
	call = function(command)
		downloads = downloads + 1
		assert(command:find("--max-time 20", 1, true))
		assert(command:find("--max-filesize 1048576", 1, true))
		assert(command:find("--proto-redir '=https'", 1, true))
		assert(command:find("Cache-Control: no-cache, no-store", 1, true))
		assert(command:find("https://github.com/Carseason/dockergo/releases/download/apps/apps.json", 1, true))
		local output = assert(command:match("%-%-output '([^']+)'"))
		files[output] = next_body
		return next_status
	end,
}
assert(loadfile(assert(arg[1], "pass controller path")))()
local controller = package.loaded["luci.controller.dockergo"]
local load_catalog
for index = 1, 20 do
	local name, value = debug.getupvalue(controller.api_apps, index)
	if not name then break end
	if name == "load_catalog" then load_catalog = value break end
end
assert(load_catalog, "controller catalog loader missing")
local function assert_clean()
	for path in pairs(files) do assert(path == stale_path, "download file leaked") end
	assert(not next(directories), "download directory leaked")
	assert(files[stale_path] == "old cached data")
end

next_body = valid_body
assert(load_catalog().tags[1] == "Web")
assert_clean()
next_body = '{"schemaVersion":1,"apps":[],"tags":["最新标签"]}'
assert(load_catalog().tags[1] == "最新标签")
assert(downloads == 2, "every call must download fresh data")
assert_clean()

for _, bad in ipairs({"invalid JSON", '{"schemaVersion":2}', '{"schemaVersion":1,"apps":[]}', "", string.rep("x", 1048577)}) do
	next_body = bad
	local result, status, code = load_catalog()
	assert(not result and status == 502 and code == "CATALOG_INVALID")
	assert_clean()
end
next_status = 22
local result, status, code = load_catalog()
assert(not result and status == 503 and code == "CATALOG_DOWNLOAD_FAILED")
assert_clean()
print("CDN controller tests passed: fresh download on each call, no persistent cache, validation, size limit, network failure, temporary file cleanup")
