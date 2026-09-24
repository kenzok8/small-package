-- Cloudreve LuCI API: disk detection, Configs dir management, download
local fs = require "nixio.fs"
local sys = require "luci.sys"
local util = require "luci.util"

module("luci.model.cbi.cloudreve.api", package.seeall)

-- 重要：module() 会把本文件的环境换成新表（__index 指向 _G），
-- LuCI（ucode 运行时）注入的全局 translate 在这里取不到，直接当全局调用会 500。
-- 真机实测：api.lua:51 attempt to call global 'translate' (a nil value)。
-- 本项目文案是中文硬编码、没有实际翻译需求，这里给一个本地兜底实现。
local function translate(s)
	return s
end

-- 同理，nixio 不依赖「别的模块已经把它变成全局」，显式 require 更稳
local ok_nixio, nixio = pcall(require, "nixio")

local appname = "cloudreve"
local api_url = "https://api.github.com/repos/cloudreve/cloudreve/releases/latest"

-- Configs folder convention: <mountpoint>/Configs/cloudreve/
local CONFIGS_DIR = "Configs"
local APP_SUBDIR = "cloudreve"

-- Detect mounted disks (block devices with real filesystems)
function get_disks()
	local disks = {}
	-- Delegate to the iStoreOS-official detection script so behaviour matches
	local out = sys.exec("sh /usr/libexec/cloudreve/detect_base.sh --list 2>/dev/null")
	for line in out:gmatch("[^\r\n]+") do
		local mp, availkb, fstype = line:match("^(%S+)%s+(%S+)%s*(%S*)")
		if mp and availkb then
			local kb = tonumber(availkb) or 0
			local avail_h = util.trim(sys.exec(
				"awk -v k=" .. availkb .. " 'BEGIN{printf \"%.1fG\", k/1048576}'"))
			disks[#disks + 1] = {
				mount = mp,
				avail_kb = kb,
				avail = avail_h,
				fstype = fstype or ""
			}
		end
	end
	return disks
end

-- Auto-pick best base path using official strategy
-- (largest writable mount under /mnt|/media|/opt with >= 1GiB free)
function get_auto_base()
	local p = util.trim(sys.exec(
		"sh /usr/libexec/cloudreve/detect_base.sh 2>/dev/null"))
	if p ~= "" then return p end
	return nil
end

-- Verify a chosen path is writable and has enough room
function check_path(p)
	if not p or p == "" then return false, translate('路径为空') end
	local ret = sys.call("sh /usr/libexec/cloudreve/detect_base.sh --check " ..
			     "'" .. p .. "' >/dev/null 2>&1")
	if ret == 0 then return true, translate('可用') end
	return false, translate('目录不可写，或者剩余空间不足 1GiB')
end

-- Get a UCI option value
function uci_get(opt, default)
	local uci = require "luci.model.uci".cursor()
	local v = uci:get_first(appname, appname, opt)
	if v == nil or v == "" then return default end
	return v
end

-- Get the user-selected root path (where binary, config, and database live)
-- Falls back to auto-detection if not configured
function get_root_path()
	local root = uci_get("root_path", nil)
	if root and root ~= "" then return root end
	-- 没配置就按官方策略自动挑盘；挑不到返回空串，由调用方提示用户选盘
	return get_auto_base() or ""
end

-- Build the Configs directory path: <root>/Configs/cloudreve
function get_app_dir()
	local root = get_root_path()
	if root == "" then return "" end
	return root .. "/" .. CONFIGS_DIR .. "/" .. APP_SUBDIR
end

-- Config file path: <root>/Configs/cloudreve/cloudreve.ini
-- 配置与程序、数据放在同一个用户目录下，跟盘走
function get_conf_path()
	local app_dir = get_app_dir()
	if app_dir == "" then return "" end
	return app_dir .. "/cloudreve.ini"
end

-- Ensure <root>/Configs/cloudreve exists; create if missing
function ensure_app_dir()
	local root = get_root_path()
	if root == "" then return nil end
	local app_dir = get_app_dir()

	-- Create root if needed
	if not fs.access(root) then
		sys.call("mkdir -p " .. root .. " 2>/dev/null")
	end

	-- Create Configs dir if needed
	local configs_dir = root .. "/" .. CONFIGS_DIR
	if not fs.access(configs_dir) then
		sys.call("mkdir -p " .. configs_dir .. " 2>/dev/null")
	end

	-- Create cloudreve subdir if needed
	if not fs.access(app_dir) then
		sys.call("mkdir -p " .. app_dir .. " 2>/dev/null")
	end

	if fs.access(app_dir) then
		return app_dir
	end
	return nil
end

-- Get binary path
function get_binary_path()
	local app_dir = get_app_dir()
	return app_dir .. "/" .. appname
end

-- ─── Architecture detection ───
function auto_get_arch()
	local arch = ""
	if ok_nixio and nixio and nixio.uname then
		arch = nixio.uname().machine or ""
	end
	local target = "amd64"

	if arch == "x86_64" then
		target = "amd64"
	elseif arch == "aarch64" or arch == "arm64" then
		target = "arm64"
	elseif arch:match("^i[%d]86$") then
		target = "386"
	elseif arch:match("^armv[5-8]") or arch:match("^arm") then
		-- Cloudreve provides armv5/6/7 variants; detect version
		local ver = arch:match("^armv([5-8])")
		local is_hf = false
		local hwcap = "/proc/cpuinfo"
		if fs.access(hwcap) then
			local cpuinfo = sys.exec("grep -i -m1 'Features' /proc/cpuinfo 2>/dev/null")
			if cpuinfo and cpuinfo:match("half") then is_hf = true end
		end
		-- Default to armv7 for modern OpenWrt arm boards
		local sub = ver or "7"
		target = "armv" .. sub
	elseif arch == "mips" then
		-- Detect little-endian mips (mipsle) common on ramips
		local cpuinfo = sys.exec("grep -i -m1 'cpu model' /proc/cpuinfo 2>/dev/null") or ""
		local LEDE_BOARD = ""
		local DISTRIB_TARGET = ""
		if fs.access("/usr/lib/os-release") then
			LEDE_BOARD = sys.exec("grep 'LEDE_BOARD' /usr/lib/os-release 2>/dev/null | awk -F '[\\042\\047]' '{print $2}'")
		end
		if fs.access("/etc/openwrt_release") then
			DISTRIB_TARGET = sys.exec("grep 'DISTRIB_TARGET' /etc/openwrt_release 2>/dev/null | awk -F '[\\042\\047]' '{print $2}'")
		end
		-- ramips/mtk = mips little-endian (mipsle)
		if LEDE_BOARD and (LEDE_BOARD:match("ramips") or LEDE_BOARD:match("mediatek")) then
			target = "mipsle"
		elseif DISTRIB_TARGET and (DISTRIB_TARGET:match("ramips") or DISTRIB_TARGET:match("mediatek")) then
			target = "mipsle"
		else
			target = "mipsle"
		end
	elseif arch == "mips64" then
		target = "mips64"
	elseif arch == "mips64el" then
		target = "mips64le"
	elseif arch == "loong64" or arch == "loongarch64" then
		target = "loong64"
	end

	return util.trim(arch), target
end

-- Map to Cloudreve release asset name pattern
function get_release_pattern(target)
	-- Cloudreve assets: cloudreve_<tag>_linux_<arch>.tar.gz
	return "linux_" .. target .. "%.tar%.gz"
end

-- ─── Version check ───
function check_version()
	local json = require "luci.jsonc"
	local raw_arch, target = auto_get_arch()
	local app_dir = ensure_app_dir()
	local bin_path = get_binary_path()

	local result = {
		code = 0,
		arch = raw_arch,
		target = target,
		app_dir = app_dir or "",
		bin_path = bin_path
	}

	-- Local version: run binary with --version or version
	if fs.access(bin_path) then
		local out = sys.exec(bin_path .. " --version 2>/dev/null || " ..
				     bin_path .. " version 2>/dev/null")
		local ver = out:match("v?([%d]+%.[%d]+%.[%d]+)") or
			    out:match("([%d]+%.[%d]+%.[%d]+)") or
			    out:match("v?([%d]+%.[%d]+)") or ""
		result.localver = util.trim(ver)
		result.installed = true
	else
		result.localver = ""
		result.installed = false
	end

	-- Remote version from GitHub API
	local json_content = sys.exec(
		"wget --no-check-certificate --timeout=15 -O- " .. api_url .. " 2>/dev/null")
	local data = json.parse(json_content) or {}

	result.remotever = data.tag_name or ""
	result.html_url = data.html_url or ""
	result.download_url = ""

	local pattern = get_release_pattern(target)
	if data.assets then
		for _, asset in ipairs(data.assets) do
			if asset.name and asset.name:match(pattern) then
				result.download_url = asset.browser_download_url or ""
				result.asset_name = asset.name
				break
			end
		end
		-- Fallback: list available assets for debugging
		if result.download_url == "" then
			local avail = {}
			for _, asset in ipairs(data.assets) do
				avail[#avail + 1] = asset.name or "?"
			end
			result.available = avail
		end
	end

	if result.download_url == "" and result.remotever ~= "" then
		result.code = 1
		result.error = translate('没有找到匹配本机架构（') .. target ..
			       translate('）的安装包，官方发布的全部安装包已列在下方。')
	elseif result.download_url == "" then
		result.code = 1
		result.error = translate('连不上 GitHub，拿不到版本信息。请检查路由器能否访问外网后重试。')
	end

	return result
end

-- ─── Download and install into Configs/cloudreve ───
function download_install(url)
	if not url or url == "" then
		return { code = 1, error = translate('下载链接为空，请先点一次按钮完成检测再下载。') }
	end

	local app_dir = ensure_app_dir()
	if not app_dir then
		return { code = 1, error = translate('没有可用的外置存储盘或无法创建目录，请先在「存储与磁盘」里选一块外置硬盘。') }
	end

	local bin_path = get_binary_path()
	local tmp_file = "/tmp/cloudreve_dl.tar.gz"
	local extract_dir = "/tmp/cloudreve_extract"

	-- Clean previous temp
	sys.call("/bin/rm -f " .. tmp_file)
	sys.call("/bin/rm -rf " .. extract_dir)
	sys.call("mkdir -p " .. extract_dir)

	-- Download
	local ret = sys.call(
		"wget --no-check-certificate --timeout=300 -O " .. tmp_file .. " " .. url)
	if ret ~= 0 or not fs.access(tmp_file) then
		return { code = 1, error = translate('下载失败或超时，通常是路由器访问 GitHub 不通。') }
	end

	-- Extract
	sys.call("tar -xzf " .. tmp_file .. " -C " .. extract_dir .. " 2>/dev/null")

	-- Find the cloudreve binary in extracted content
	local found = nil
	local find_out = sys.exec("find " .. extract_dir .. " -type f -name cloudreve 2>/dev/null")
	for line in find_out:gmatch("[^\r\n]+") do
		found = util.trim(line)
		break
	end

	if not found then
		sys.call("/bin/rm -rf " .. extract_dir .. " " .. tmp_file)
		return { code = 1, error = translate('下载下来的压缩包里没有找到 cloudreve 程序文件。') }
	end

	-- Stop service if running before replacing binary
	local running = (sys.call("pgrep -f '" .. appname .. "' >/dev/null") == 0)
	if running then
		sys.call("/etc/init.d/cloudreve stop >/dev/null 2>&1")
	end

	-- Backup existing binary
	if fs.access(bin_path) then
		sys.call("/bin/mv -f " .. bin_path .. " " .. bin_path .. ".bak")
	end

	-- Move new binary into Configs/cloudreve/
	sys.call("/bin/mv -f " .. found .. " " .. bin_path)
	sys.call("/bin/chmod 755 " .. bin_path)

	-- Cleanup
	sys.call("/bin/rm -rf " .. extract_dir .. " " .. tmp_file)

	if not fs.access(bin_path) then
		if fs.access(bin_path .. ".bak") then
			sys.call("/bin/mv -f " .. bin_path .. ".bak " .. bin_path)
		end
		return { code = 1, error = translate('安装失败，已自动还原成原来的版本。') }
	end

	sys.call("/bin/rm -f " .. bin_path .. ".bak")

	if running then
		sys.call("/etc/init.d/cloudreve start >/dev/null 2>&1")
	end

	return {
		code = 0,
		path = bin_path,
		app_dir = app_dir,
		message = translate('安装成功')
	}
end

-- Check if binary is present in Configs/cloudreve
function is_installed()
	local bin_path = get_binary_path()
	return fs.access(bin_path)
end
