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
	["kspeeder.json"] = {
		id = "kspeeder",
		standalone = {
			basePath = "/apps/kspeeder/",
			externalOpen = { enabled = true, path = "/" }
		},
		desktop = { mode = "module", entry = "desktop-entry.js" },
		backend = {
			type = "http", portFromUci = "istoreenhance.@istoreenhance[0].adminport",
			defaultPort = 5003
		}
	},
	["kai.json"] = {
		id = "kai",
		standalone = {
			basePath = "/apps/kai/",
			externalOpen = { enabled = true }
		},
		desktop = {
			mode = "iframe",
			target = {
				scheme = "http", hostMode = "request-host", path = "/apps/kai/",
				port = { default = 8197, keys = { uci = "kai.@kai[0].port" } }
			}
		},
		backend = { type = "app-base", basePath = "/apps/kai/" }
	},
	["dockermanager.json"] = {
		id = "dockermanager",
		standalone = { basePath = "/apps/dockermanager/" },
		desktop = { mode = "module", entry = "desktop-entry.js" },
		backend = {
			type = "http",
			values = {
				externalPortEnabled = {
					default = false,
					keys = { uci = "dockermanager.@dockermanager[0].external_port_enabled" }
				},
				port = {
					default = 8192,
					keys = { uci = "dockermanager.@dockermanager[0].port" }
				}
			}
		}
	},
	["openwrt.json"] = {
		id = "openwrt-luci",
		standalone = { url = "/cgi-bin/luci/" },
		desktop = { mode = "builtin", component = "LuciContainer" }
	}
}

local function dependencies(filename, entry_available, uci_values)
	uci_values = uci_values or {}
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
		read_uci = function(key)
			if key == "fastnet.@fastnet[0].port" then return "3201" end
			return uci_values[key]
		end,
		uci = {
			get_list = function() return entry_available and { "/apps=http://127.0.0.1:19290" } or {} end,
			get = function(_, config, section, option)
				if config == "linkease_app_entry" and section == "main" and option == "state_file" then return "/state.json" end
			end,
			get_first = function(_, config, section_type, option)
				return uci_values[config .. ".@" .. section_type .. "[0]." .. option]
			end
		}
	}
end

package.loaded["luci.model.linkease.apps_openwrt"] = nil
local apps_openwrt = require "luci.model.linkease.apps_openwrt"

local fastnet = apps_openwrt.new(dependencies("fastnet.json", false)):resolve("fastnet")
equal(fastnet.available, true)
equal(fastnet.mode, "external")
equal(fastnet.url, "http://192.168.30.7:3201/")

local kspeeder = apps_openwrt.new(dependencies("kspeeder.json", false, {
	["istoreenhance.@istoreenhance[0].adminport"] = "5004"
})):resolve("kspeeder")
equal(kspeeder.available, true)
equal(kspeeder.mode, "external")
equal(kspeeder.url, "http://192.168.30.7:5004/", "standalone external path must win")

local kai = apps_openwrt.new(dependencies("kai.json", false, {
	["kai.@kai[0].port"] = "8198"
})):resolve("kai")
equal(kai.available, true)
equal(kai.mode, "external")
equal(kai.url, "http://192.168.30.7:8198/apps/kai/", "app-base external path must be preserved")

local kai_proxy = apps_openwrt.new(dependencies("kai.json", true)):resolve("kai")
equal(kai_proxy.available, true)
equal(kai_proxy.mode, "apps")
equal(kai_proxy.url, "/apps/kai/", "shared entry must keep the public KAI root")

local docker_disabled = apps_openwrt.new(dependencies("dockermanager.json", false)):resolve("dockermanager")
equal(docker_disabled.available, false)
equal(docker_disabled.reason, "entry_unavailable_and_external_disabled")

local docker_enabled = apps_openwrt.new(dependencies("dockermanager.json", false, {
	["dockermanager.@dockermanager[0].external_port_enabled"] = "1",
	["dockermanager.@dockermanager[0].port"] = "8193"
})):resolve("dockermanager")
equal(docker_enabled.available, true)
equal(docker_enabled.url, "http://192.168.30.7:8193/apps/dockermanager/")

local builtin = apps_openwrt.new(dependencies("openwrt.json", true)):resolve("openwrt-luci")
equal(builtin.registered, true)
equal(builtin.available, false)
equal(builtin.reason, "entry_unsupported_and_external_disabled")

print("linkease apps OpenWrt adapter tests passed")
