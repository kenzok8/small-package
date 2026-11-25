local M = {}

local function valid_descriptor(value)
	if type(value) ~= "table" or value.schemaVersion ~= 1 or value.kind ~= "cli" then
		return false
	end
	if type(value.id) ~= "string" or not value.id:match("^[a-z0-9][a-z0-9%-]*$") then
		return false
	end
	if type(value.name) ~= "string" or value.name == "" then
		return false
	end
	if type(value.command) ~= "string" or not value.command:match("^/usr/bin/[a-z0-9][a-z0-9%-]*$") then
		return false
	end
	if type(value.statusCommand) ~= "table" or #value.statusCommand ~= 2 then
		return false
	end
	if type(value.statusCommand[1]) ~= "string"
		or not value.statusCommand[1]:match("^/usr/libexec/[a-z0-9][a-z0-9%-]*%-runtime$")
		or value.statusCommand[2] ~= "provider-status" then
		return false
	end
	if value.manageUrl ~= nil and (type(value.manageUrl) ~= "string"
		or not value.manageUrl:match("^/cgi%-bin/luci/admin/services/[a-z0-9_%-]+$")) then
		return false
	end
	return true
end

function M.new(deps)
	deps = deps or {}
	local fs = deps.fs or require "nixio.fs"
	local jsonc = deps.jsonc or require "luci.jsonc"
	local sys = deps.sys or require "luci.sys"
	local util = deps.util or require "luci.util"
	local directory = deps.directory or "/usr/share/coding-agents.d"

	return {
		list = function()
			local providers = {}
			local iterator = fs.dir(directory)
			if not iterator then
				return providers
			end

			for filename in iterator do
				if filename:match("%.json$") then
					local descriptor = jsonc.parse(fs.readfile(directory .. "/" .. filename) or "")
					if valid_descriptor(descriptor) then
						local helper = descriptor.statusCommand[1]
						local command_available = fs.access(descriptor.command, "x") == true
						local helper_available = fs.access(helper, "x") == true
						local state
						if command_available and helper_available then
							state = jsonc.parse(sys.exec(util.shellquote(helper) .. " provider-status 2>/dev/null") or "")
						end
						state = type(state) == "table" and state or {}
						providers[#providers + 1] = {
							id = descriptor.id,
							name = descriptor.name,
							owner_package = descriptor.ownerPackage,
							manage_url = descriptor.manageUrl,
							available = command_available and helper_available,
							configured = state.configured == true,
							installed = state.installed == true,
							authenticated = state.authenticated == true,
							version = type(state.version) == "string" and state.version or nil
						}
					end
				end
			end

			table.sort(providers, function(left, right)
				return left.name:lower() < right.name:lower()
			end)
			return providers
		end
	}
end

return M
