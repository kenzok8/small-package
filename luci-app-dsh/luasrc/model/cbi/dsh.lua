local taskd = require "luci.model.tasks"
local dsh_model = require "luci.model.dsh"
local fs = require "nixio.fs"

local m = taskd.docker_map(
	"dsh",
	"dsh",
	"/usr/libexec/istorec/dsh.sh",
	translate("DSH"),
	translate("Run the DeepSeek Harness Web workbench in a protected container. Configure access and storage here; models, sessions and tools remain in DSH.")
)

local status = m:section(SimpleSection, translate("Service status"))
status:append(Template("dsh/status"))

local section = m:section(TypedSection, "main", translate("Deployment settings"),
	translate("Changes take effect after Install/Upgrade or Restart. DSH data and workspaces are preserved."))
section.addremove = false
section.anonymous = true
section:tab("access", translate("Access & security"))
section:tab("storage", translate("Storage"))
section:tab("runtime", translate("Runtime"))

local profile = section:taboption("runtime", ListValue, "image_profile", translate("Runtime profile"))
profile.rmempty = false
profile:value("standard", translate("Standard — DSH Web workbench"))
profile:value("advanced", translate("Browser enhanced — Chromium & Browser Use (Experimental)"))
profile.default = "standard"
profile.description = translate("Standard is smaller and remains recommended. Browser enhanced adds visible Chromium, protected noVNC and Playwright Browser Use; its image requires several gigabytes of Docker storage and more memory. Profiles keep separate DSH settings and sessions, while sharing the selected workspace.")

local port = section:taboption("access", Value, "port", translate("Web port"))
port.rmempty = false
port.default = "13080"
port.description = translate("DSH listens on this port on all interfaces. Firewall access remains under user control.")
function port.validate(self, value)
	local number = tonumber(value)
	if not number or number % 1 ~= 0 or number < 1024 or number > 65535 then
		return nil, translate("Use a port between 1024 and 65535.")
	end
	return tostring(number)
end

local administrator_username = section:taboption("access", DummyValue, "_administrator_username", translate("Administrator username"))
administrator_username:depends("image_profile", "advanced")
administrator_username.description = translate("Fixed sign-in username for the browser-enhanced gateway.")
function administrator_username.cfgvalue()
	return "dsh"
end

local administrator_key = section:taboption("access", Value, "_administrator_key", translate("Administrator key"))
administrator_key.password = true
administrator_key.rmempty = true
administrator_key.description = translate("Leave blank to keep the current key. Sign in as dsh with this key. A new key takes effect after Install/Upgrade or Restart and will not be displayed again.")
function administrator_key.cfgvalue()
	return ""
end
function administrator_key.validate(self, value)
	if value == nil or value == "" then return "" end
	if #value < 12 or #value > 256 or value:find("[%c%s]") then
		return nil, translate("Use 12 to 256 characters without spaces or control characters.")
	end
	return value
end
function administrator_key.write(self, sid, value)
	if value == nil or value == "" then return end
	local directory = "/etc/dsh"
	local path = directory .. "/admin.key"
	local pending = path .. ".new"
	if not fs.stat(directory) and not fs.mkdir(directory, "700") then
		error("could not create the DSH key directory")
	end
	if not fs.chmod(directory, "700") or not fs.writefile(pending, value)
		or not fs.chmod(pending, "600") or not fs.rename(pending, path) then
		fs.unlink(pending)
		error("could not store the DSH administrator key")
	end
end
function administrator_key.remove()
	-- An empty form field means "keep the current key".
end

local data_paths, workspace_paths, data_default, workspace_default = dsh_model.paths(dsh_model.blocks())

local function validate_storage_path(self, value)
	value = (value or ""):match("^%s*(.-)%s*$")
	if value == "" or not value:match("^/mnt/[^/]+/.+") or value:find("//", 1, true)
		or value:match("/%.%.?/") or value:match("/%.%.?$") or value:find(":", 1, true)
		or value:find(",", 1, true) then
		return nil, translate("Select a dedicated directory on a mounted disk.")
	end
	return value:gsub("/+$", "")
end

local data_path = section:taboption("storage", Value, "data_path", translate("DSH data directory") .. "<b>*</b>")
data_path.rmempty = false
data_path.validate = validate_storage_path
data_path.description = translate("Standard stores its credentials, settings and sessions here. Browser enhanced uses an isolated sibling directory ending in -advanced. Uninstalling the application deletes neither directory.")
for _, path in ipairs(data_paths) do data_path:value(path, path) end
data_path.default = data_default

local workspace_path = section:taboption("storage", Value, "workspace_path", translate("Workspace directory") .. "<b>*</b>")
workspace_path.rmempty = false
workspace_path.validate = validate_storage_path
workspace_path.description = translate("The Agent can read and modify everything in this directory. Use a dedicated directory and do not select the disk root or a system directory.")
for _, path in ipairs(workspace_paths) do workspace_path:value(path, path) end
workspace_path.default = workspace_default

local trusted_hosts = section:taboption("access", Value, "extra_trusted_hosts", translate("Trusted access hosts"))
trusted_hosts.rmempty = true
trusted_hosts.default = "*"
trusted_hosts:value("*", translate("Automatic — device addresses and router hostname"))
trusted_hosts.combobox_manual = translate("Enter custom hosts")
trusted_hosts.description = translate("Recommended: keep * to trust the device's current IP addresses and router hostname. For a custom DNS name, replace * with exact comma-separated hostnames or IP addresses. Authentication remains enabled in both runtime profiles.")
function trusted_hosts.validate(self, value)
	value = (value or ""):match("^%s*(.-)%s*$")
	if value ~= "" and value ~= "*" and not value:match("^[%w%.,:_%%%-]+$") then
		return nil, translate("Use only hostnames, IP addresses and optional ports separated by commas.")
	end
	return value
end

return m
