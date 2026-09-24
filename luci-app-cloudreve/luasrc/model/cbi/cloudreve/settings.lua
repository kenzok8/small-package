-- Cloudreve LuCI 设置页（全中文）
local fs = require "nixio.fs"
local sys = require "luci.sys"
local ok, api = pcall(require, "luci.model.cbi.cloudreve.api")

m = Map("cloudreve", translate('Cloudreve 云盘'),
	translate('自建网盘 / 文件分享系统。程序本体、配置文件、数据库都存放在您所选磁盘的 Configs/cloudreve/ 目录里，不占用路由器自身闪存。'))

-- 关键：LuCI 的「保存并应用」默认只给 procd 发 reload，
-- 而服务从来没起来过时 reload 不会把它拉起来 —— 必须显式 restart。
m.on_after_commit = function(self)
	sys.call("/etc/init.d/cloudreve enable >/dev/null 2>&1")
	sys.call("(sleep 1; /etc/init.d/cloudreve restart) >/dev/null 2>&1 &")
end

-- 防御：模块缺失时只提示，不让整页 500
if not ok then
	local es = m:section(TypedSection, "cloudreve", translate('模块异常'))
	es.anonymous = true
	es.addremove = false
	es:option(DummyValue, "_err", translate('状态')).value =
		translate('未找到 luci.model.cbi.cloudreve.api 模块，请重新安装 luci-app-cloudreve 后重试。')
	return m
end

-- 只有模板文件真实存在时才挂载，避免「Failed to load template」
local function tpl(name)
	if fs.access("/usr/lib/lua/luci/view/cloudreve/" .. name .. ".htm") then
		m:append(Template("cloudreve/" .. name))
	end
end

-- ────────────── 运行状态 ──────────────
tpl("status")

-- ────────────── 程序与存储 ──────────────
local s = m:section(TypedSection, "cloudreve", translate('程序与存储'))
s.anonymous = true
s.addremove = false

-- 自动检测磁盘下拉
local storage_opts = {}
local disks = api.get_disks()
if disks and #disks > 0 then
	for _, d in ipairs(disks) do
		local label = d.mount
		local extra = {}
		if d.fstype and d.fstype ~= "" then
			extra[#extra + 1] = d.fstype
		end
		if d.avail and d.avail ~= "" then
			extra[#extra + 1] = translate('可用 ') .. d.avail
		end
		if #extra > 0 then
			label = label .. "（" .. table.concat(extra, "，") .. "）"
		end
		storage_opts[#storage_opts + 1] = { d.mount, label }
	end
end

-- 没有检测到外置硬盘时给出明确指引
if #storage_opts == 0 then
	s:option(DummyValue, "_nodisk", translate('未检测到外置硬盘')).value =
		translate('没有找到符合要求的挂载点（需位于 /mnt 或 /media 下、并且可写）。') ..
		translate('程序、配置、数据都不会放到路由器闪存里，请先把硬盘插好、在「系统 → 挂载点」里挂载成功后再回来操作。')
end

-- 自动推荐磁盘
local auto_base = api.get_auto_base()
if auto_base then
	s:option(DummyValue, "_autobase", translate('自动推荐磁盘')).value =
		auto_base .. translate('（按 iStoreOS 规则自动挑选：可写且剩余空间最大的外置挂载点）')
end

-- 只显示挂载点，不额外添加 /Configs/cloudreve 子路径（避免重复）
local storage = s:option(Value, "root_path", translate('程序根目录'),
	translate('程序、配置和数据库都放在这块盘的 Configs/cloudreve/ 目录里。常见路径：/mnt/sda1、/mmcblk0p1 等。'))

for _, opt in ipairs(storage_opts) do
	storage:value(opt[1], opt[2])
end
storage.default = api.get_root_path()
storage.rmempty = true

local app_dir = api.get_app_dir()
local dir_state
if fs.access(app_dir) then
	dir_state = translate('已存在')
else
	dir_state = translate('尚未创建（保存后会自动创建）')
end
s:option(DummyValue, "_appdir", translate('程序存放目录')).value =
	app_dir .. "　【" .. dir_state .. "】"

-- 创建 Cloudreve 目录按钮（放在程序存放目录下方）
local o = s:option(Button, "_initdir", translate('创建 Cloudreve 目录'))
o.inputstyle = "apply"
o.btnclick = "initDirClick(this);"
o.id = "initdir_btn"
if fs.access("/usr/lib/lua/luci/view/cloudreve/initdir.htm") then
	o.template = "cloudreve/initdir"
end

-- ────────────── 服务设置 ──────────────
local s2 = m:section(TypedSection, "cloudreve", translate('服务设置'))
s2.anonymous = true
s2.addremove = false

o = s2:option(Value, "listen_port", translate('监听端口'),
	translate('默认 5212。如果提示端口被占用，改成别的空闲端口即可（例如 5213）。') ..
	translate('改完端口后，用「http://路由器IP:端口」访问网盘。'))
o.datatype = "port"
o.default = "5212"
o.rmempty = false

-- ────────────── 操作按钮 ──────────────
o = s2:option(Button, "_download", translate('下载最新二进制'))
o.inputstyle = "apply"
o.btnclick = "downloadClick(this);"
o.id = "download_btn"
if fs.access("/usr/lib/lua/luci/view/cloudreve/download.htm") then
	o.template = "cloudreve/download"
end

-- ────────────── 运行日志 ──────────────
tpl("log")

return m
