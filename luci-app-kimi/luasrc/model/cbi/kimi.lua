local m = Map("kimi", translate("Kimi Code"), translate("Run the Moonshot AI Kimi Code CLI with a fixed mise runtime. Terminal access is protected by the iStoreOS application gateway."))
m:section(SimpleSection).template = "kimi/status"

local s = m:section(NamedSection, "main", "kimi", translate("运行设置"))
s.addremove = false

local enabled = s:option(Flag, "enabled", translate("启用 Kimi Code 命令行"))
enabled.rmempty = false

local model = require "luci.model.kimi"
local paths, default_path = model.find_paths()
local data_dir = s:option(Value, "data_dir", translate("数据目录"))
data_dir.rmempty = false
data_dir.default = default_path
data_dir.description = translate("保存固定版本、运行文件和登录凭据。请选择持久磁盘，至少预留 500 MB。")
for _, path in ipairs(paths) do data_dir:value(path, path) end
function data_dir.validate(self, value)
	value = (value or ""):match("^%s*(.-)%s*$"):gsub("/+$", "")
	if not value:match("^/mnt/[^/]+/.+") or value:find("[%c:]") or value:find("//", 1, true) then
		return nil, translate("Select a normalized directory on a persistent disk.")
	end
	return value
end

local workspace = s:option(Value, "workspace_dir", translate("默认工作区"))
workspace.rmempty = true
workspace.description = translate("留空时使用 <数据目录>/workspace；使用其他目录前，请确保专用 kimi 用户具有读写权限。")
function workspace.validate(self, value)
	value = (value or ""):match("^%s*(.-)%s*$"):gsub("/+$", "")
	if value == "" then return value end
	if not value:match("^/mnt/[^/]+/.+") or value:find("[%c:]") or value:find("//", 1, true) then
		return nil, translate("Workspace must be a normalized /mnt path.")
	end
	return value
end

function m.on_after_commit()
	require("luci.sys").call("/etc/init.d/kimi restart >/dev/null 2>&1")
end

return m
