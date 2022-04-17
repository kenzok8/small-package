-- Copyright 2014-2021 Sandor Balazsi <sandor.balazsi@gmail.com>
-- Licensed to the public under the GNU General Public License.

local nixio = require "nixio"
local common = require "luci.model.cbi.rtorrent.common"
local array = require "luci.model.cbi.rtorrent.array"
require "luci.model.cbi.rtorrent.string"

local map, feeds, name, url, enabled, logging, rss_logging, rss_logfile, rss_loglevel

map = Map("rtorrent", "RSS Downloader Settings", common.rss_downloader_status())
map.template = "rtorrent/map"
map.redirect = (nixio.getenv("HTTP_REFERER") or ""):match("/admin/rtorrent/rss/cfg")
	and nixio.getenv("HTTP_REFERER") or luci.http.formvalue("redirect")
map:section(SimpleSection).hidden = { redirect = map.redirect }
map.on_parse = function(self, ...)
	local names = array()
	for _, section_id in ipairs(feeds:cfgsections()) do
		if names:get(name:formvalue(section_id)) then
			names:get(name:formvalue(section_id)):insert(section_id)
		else names:set(name:formvalue(section_id), { section_id }) end
	end
	for _, sections in names:pairs() do
		if sections:size() > 1 then
			for _, section_id in sections:pairs() do
				name:add_error(section_id, "invalid", "Same name defined more than once!")
			end
			self.save = false
		end
	end
end

feeds = map:section(TypedSection, "rss-feed", "Feeds")
feeds.template = "rtorrent/tblsection"
feeds.addremove = true
feeds.anonymous = true
feeds.sortable = true

name = feeds:option(Value, "name", "Name")
name.rmempty = false
name.width = "35%"
name.validate = function(self, value, section)
	if not value or value:blank() then return nil, "Missing RSS feed name!"
	elseif value:match("|") then return nil, "The name cannot contain pipe characters!" end
	return value
end

url = feeds:option(Value, "url", "RSS Feed URL")
url.rmempty = false
url.width = "64%"
url.validate = function(self, value, section)
	local content, err = common.download(value:trim())
	if not content then
		return nil, "Not able to download RSS feed: " .. err .. "!"
	end
	return value
end

enabled = feeds:option(Flag, "enabled", "Enabled")
enabled.rmempty = false
enabled.width = "1%"
enabled.classes = { "center" }

logging = map:section(NamedSection, "logging", "rss", "Logging")

rss_logging = logging:option(Flag, "rss_logging", "Enable RSS logging")

rss_logfile = logging:option(Value, "rss_logfile", "RSS Downloader logfile")
rss_logfile:depends("rss_logging", 1)
rss_logfile.validate = function(self, value, section)
	if not value or value:blank() then return nil, "Missing RSS Downloader logfile!" end
	local parent_folder = nixio.fs.dirname(value)
	if parent_folder == "." or nixio.fs.stat(parent_folder, "type") ~= "dir" then
		return nil, "Wrong filename, please use absolute path!"
	end
	return value
end

rss_loglevel = logging:option(ListValue, "rss_loglevel", "RSS Downloader loglevel")
rss_loglevel:depends("rss_logging", 1)
rss_loglevel.default = "INFO"
rss_loglevel:value("TRACE")
rss_loglevel:value("DEBUG")
rss_loglevel:value("INFO")
rss_loglevel:value("WARN")
rss_loglevel:value("ERROR")
rss_loglevel:value("FATAL")

return map
