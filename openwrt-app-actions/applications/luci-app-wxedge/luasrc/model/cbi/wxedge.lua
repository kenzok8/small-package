--[[
LuCI - Lua Configuration Interface
]]--

local taskd = require "luci.model.tasks"
local m, s, o

local function blocks()
	local util  = require "luci.util"
	local jsonc = require "luci.jsonc"
	local text = util.trim(util.exec("lsblk -s -f -b -o NAME,FSSIZE,MOUNTPOINT --json"))
	local vals = {}
	if text and text ~= "" then
		local obj = jsonc.parse(text)
		for _, val in pairs(obj["blockdevices"]) do
			local fsize = val["fssize"]
			if fsize ~= nil and string.len(fsize) > 10 and val["mountpoint"] then
				-- fsize > 1G
				vals[#vals+1] = val["mountpoint"]
			end
		end
	end
	return vals
end

m = taskd.docker_map("wxedge", "wxedge", "/usr/libexec/istorec/wxedge.sh",
	translate("Onething Edge"),
	"「网心云-容器魔方」由网心云推出的一款 docker 容器镜像软件，通过在简单安装后即可快速加入网心云共享计算生态网络，用户可根据每日的贡献量获得相应的现金收益回报。了解更多，请登录「<a href=\"https://www.onethingcloud.com/\" target=\"_blank\" >网心云官网</a>」")

s = m:section(SimpleSection, translate("Service Status"), translate("Onething Edge status:"), "注意网心云会以超级权限运行！")
s:append(Template("wxedge/status"))

s = m:section(TypedSection, "wxedge", translate("Setup"), translate("The following parameters will only take effect during installation or upgrade:"))
s.addremove=false
s.anonymous=true

local blks = blocks()
local dir
o = s:option(Value, "cache_path", translate("Cache path").."<b>*</b>", "请选择合适的存储位置进行安装，安装位置容量越大，收益越高。安装后请勿轻易改动")
o.rmempty = false
o.datatype = "string"
for _, dir in pairs(blks) do
	dir = dir .. "/wxedge1"
	o:value(dir, dir)
end
if #blks > 0 then
    o.default = blks[1] .. "/wxedge1"
end

return m
