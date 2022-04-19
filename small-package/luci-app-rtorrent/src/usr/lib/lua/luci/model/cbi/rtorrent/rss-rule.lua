-- Copyright 2014-2021 Sandor Balazsi <sandor.balazsi@gmail.com>
-- Licensed to the public under the GNU General Public License.

local rtorrent = require "rtorrent"
local util = require "luci.util"
local build_url = require "luci.dispatcher".build_url
local common = require "luci.model.cbi.rtorrent.common"
require "luci.model.cbi.rtorrent.string"

local section = arg[1]

local map, rss_rule, enabled, name, match, exclude, minsize, maxsize, feed, tags, destdir, autostart

map = Map("rtorrent", "RSS Downloader Rule", common.rss_downloader_status())
map.template = "rtorrent/map"
map.redirect = build_url("admin", "rtorrent", "rss")
map.on_parse = function(self, ...)
	if util.instanceof(feed, DummyValue) then
		feed:add_error(section, "invalid", "No feed found! Please add one.")
		self.save = false
	elseif not feed:formvalue(section) then
		feed:add_error(section, "invalid", "At least one feed must be selected!")
		self.save = false
	end
end

if not map:get(section) then luci.http.redirect(map.redirect) end

rss_rule = map:section(NamedSection, section, map:get(section)[".type"])
rss_rule.anonymous = true

enabled = rss_rule:option(Flag, "enabled", "Enabled")
enabled.rmempty = false

name = rss_rule:option(Value, "name", "Name")
name.rmempty = false

match = rss_rule:option(TextValue, "match", "Match",
	'The torrent name must match this (case-insensitive) lua <a href="%s" target="_blank">pattern</a>. '
	% "https://www.lua.org/pil/20.2.html" .. "Use <code>.*</code> to download everything from the feed." )
match.template = "rtorrent/tvalue"
match.rmempty = false
match.rows = 1

exclude = rss_rule:option(TextValue, "exclude", "Exclude",
	'Exclude torrents that names match this (case-insensitive) lua <a href="%s" target="_blank">pattern</a>.'
	% "https://www.lua.org/pil/20.2.html")
exclude.rows = 1

minsize = rss_rule:option(Value, "minsize", "Min size (MiB):")

maxsize = rss_rule:option(Value, "maxsize", "Max size (MiB):")

local feeds = common.uci_sections(map.config, "rss-feed")
if feeds:empty() then
	feed = rss_rule:option(DummyValue, "feed", "Feed")
	feed.template = "rtorrent/dvalue"
	feed.rawhtml = true
	feed.value = '<div class="cbi-dummy">RSS feeds not yet added. You can do it <a href="%s">here</a>.</div>'
		% build_url("admin", "rtorrent", "settings", "rss")
else
	feed = rss_rule:option(DropDown, "feed", "Feed", 'You can manage RSS feeds <a href="%s">here</a>.'
		% build_url("admin", "rtorrent", "settings", "rss"))
	-- TODO: warning on disabled feed
	feed.template = "rtorrent/dropdown"
	feed.multiple = true
	feed.display = 3
	feed.delimiter = "|"
	feed.cfgvalue = function(self, section)
		local value = AbstractValue.cfgvalue(self, section)
		return type(value) == "string" and value:split(feed.delimiter) or value
	end
	feeds:foreach(function(f) feed:value(f:get("name"), f:get("name")
		.. (f:get("enabled") == "0" and " (disabled)" or "")) end)
end

tags = rss_rule:option(Value, "tags", "Add tags")
-- tags.default = ""

destdir = rss_rule:option(Value, "destdir", "Download directory")
destdir.default = rtorrent.call("directory.default")
-- destdir.datatype = "directory"
destdir.rmempty = false

autostart = rss_rule:option(Flag, "autostart", "Start download")
autostart.default = "1"
autostart.rmempty = false

return map
