--[[
LuCI - Lua Configuration Interface
]]--

local taskd = require "luci.model.tasks"
local plex_model = require "luci.model.plex"
local m, s, o

m = taskd.docker_map("plex", "plex", "/usr/libexec/istorec/plex.sh",
	translate("Plex"),
	translate("Plex is an streaming media service and a client–server media player platform, made by Plex, Inc.")
		.. translate("Official website:") .. ' <a href=\"https://www.plex.tv/\" target=\"_blank\">https://www.plex.tv/</a>')

s = m:section(SimpleSection, translate("Service Status"), translate("Plex status:"))
s:append(Template("plex/status"))

s = m:section(TypedSection, "main", translate("Setup"), translate("The following parameters will only take effect during installation or upgrade:"))
s.addremove=false
s.anonymous=true

o = s:option(Flag, "hostnet", translate("Host network"), translate("Plex running in host network, for DLNA application, port is always 32400 if enabled"))
o.default = 0
o.rmempty = false

o = s:option(Value, "claim_token", translate("Plex Claim"))
o.datatype = "string"

o = s:option(Value, "port", translate("Port").."<b>*</b>")
o.default = "32400"
o.datatype = "port"
o:depends("hostnet", 0)

o = s:option(Value, "image_name", translate("Image").."<b>*</b>")
o.rmempty = false
o.datatype = "string"
o:value("plexinc/pms-docker:latest", "plexinc/pms-docker:latest")
o:value("plexinc/pms-docker:1.29.1.6316-f4cdfea9c", "plexinc/pms-docker:1.29.1.6316-f4cdfea9c")
o.default = "plexinc/pms-docker:latest"

local blocks = plex_model.blocks()
local home = plex_model.home()

o = s:option(Value, "config_path", translate("Config path").."<b>*</b>")
o.rmempty = false
o.datatype = "string"

local paths, default_path = plex_model.find_paths(blocks, home, "Configs")
for _, val in pairs(paths) do
  o:value(val, val)
end
o.default = default_path

o = s:option(Value, "media_path", translate("Media path"), translate("Not required, all disk is mounted in") .. " <a href='/cgi-bin/luci/admin/services/linkease/file/?path=/root/mnt' target='_blank'>/mnt</a>")
o.datatype = "string"

o = s:option(Value, "cache_path", translate("Transcode cache path"), translate("Default use 'transcodes' in 'config path' if not set, please make sure there has enough space"))
o.datatype = "string"
local paths, default_path = plex_model.find_paths(blocks, home, "Caches")
for _, val in pairs(paths) do
  o:value(val, val)
end
o.default = default_path

return m
