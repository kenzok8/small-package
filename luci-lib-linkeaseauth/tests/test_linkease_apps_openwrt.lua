local source_root = assert(os.getenv("LINKEASE_APPS_SOURCE_ROOT"), "LINKEASE_APPS_SOURCE_ROOT is required")
package.path = source_root .. "/?.lua;" .. package.path

local function equal(actual, expected, message)
	if actual ~= expected then
		error((message or "values differ") .. ": got " .. tostring(actual) .. ", want " .. tostring(expected), 2)
	end
end

local manifests = {
	["fastnet.json"] = {
		id = "fastnet",
		standalone = { basePath = "/apps/fastnet/" },
		desktop = {
			mode = "iframe",
			target = {
				scheme = "http", hostMode = "request-host", path = "/",
				port = { default = 3200, keys = { uci = "fastnet.@fastnet[0].port" } }
			}
		}
	},
	["openwrt.json"] = {
		id = "openwrt-luci",
		standalone = { url = "/cgi-bin/luci/" },
		desktop = { mode = "builtin", component = "LuciContainer" }
	}
}

local function dependencies(filename, entry_available)
	return {
		registration_dirs = { "/registrations" },
		fs = {
			dir = function()
				local emitted = false
				return function()
					if emitted then return nil end
					emitted = true
					return filename
				end
			end,
			readfile = function(path)
				if path == "/registrations/" .. filename then return "manifest" end
				if path == "/state.json" then return "state" end
				if path == "/etc/config/uhttpd" then return entry_available and "/apps=http://127.0.0.1:19290" or "" end
			end
		},
		json = { parse = function(raw)
			if raw == "manifest" then return manifests[filename] end
			if raw == "state" then return { active = entry_available and "gateway" or "stopped" } end
		end },
		sys = { call = function() return 0 end },
		http = { getenv = function(name) if name == "HTTP_HOST" then return "192.168.30.7:10000" end end },
		read_uci = function(key) if key == "fastnet.@fastnet[0].port" then return "3201" end end,
		uci = {
			get_list = function() return entry_available and { "/apps=http://127.0.0.1:19290" } or {} end,
			get = function(_, config, section, option)
				if config == "linkease_app_entry" and section == "main" and option == "state_file" then return "/state.json" end
			end,
			get_first = function() return nil end
		}
	}
end

package.loaded["luci.model.linkease.apps_openwrt"] = nil
local apps_openwrt = require "luci.model.linkease.apps_openwrt"

local fastnet = apps_openwrt.new(dependencies("fastnet.json", false)):resolve("fastnet")
equal(fastnet.available, true)
equal(fastnet.mode, "external")
equal(fastnet.url, "http://192.168.30.7:3201/")

local builtin = apps_openwrt.new(dependencies("openwrt.json", true)):resolve("openwrt-luci")
equal(builtin.registered, true)
equal(builtin.available, false)
equal(builtin.reason, "entry_unsupported_and_external_disabled")

print("linkease apps OpenWrt adapter tests passed")
