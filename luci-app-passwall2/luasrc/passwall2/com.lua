local _M = {}

local function gh_release_url(self)
	--return "https://api.github.com/repos/" .. self.repo .. "/releases/latest"
	return "https://github.com/xiaorouji/openwrt-passwall-packages/releases/download/api-cache/" .. string.lower(self.name) .. "-release-api.json"
end

local function gh_pre_release_url(self)
	--return "https://api.github.com/repos/" .. self.repo .. "/releases?per_page=1"
	return "https://github.com/xiaorouji/openwrt-passwall-packages/releases/download/api-cache/" .. string.lower(self.name) .. "-pre-release-api.json"
end

_M.hysteria = {
	name = "Hysteria",
	repo = "HyNetwork/hysteria",
	get_url = gh_release_url,
	cmd_version = "version | awk '/^Version:/ {print $2}'",
	remote_version_str_replace = "app/",
	zipped = false,
	default_path = "/usr/bin/hysteria",
	match_fmt_str = "linux%%-%s$",
	file_tree = {
		armv6 = "arm",
		armv7 = "arm"
	}
}

_M["sing-box"] = {
	name = "Sing-Box",
	repo = "SagerNet/sing-box",
	get_url = gh_release_url,
	cmd_version = "version | awk '{print $3}' | sed -n 1P",
	zipped = true,
	zipped_suffix = "tar.gz",
	default_path = "/usr/bin/sing-box",
	match_fmt_str = "linux%%-%s",
	file_tree = {
		x86_64 = "amd64",
		mips64el = "mips64le"
	}
}

_M.xray = {
	name = "Xray",
	repo = "XTLS/Xray-core",
	get_url = gh_pre_release_url,
	cmd_version = "version | awk '{print $2}' | sed -n 1P",
	zipped = true,
	default_path = "/usr/bin/xray",
	match_fmt_str = "linux%%-%s",
	file_tree = {
		x86_64 = "64",
		x86    = "32",
		mips   = "mips32",
		mipsel = "mips32le",
		mips64el = "mips64le"
	}
}

return _M
