-- Copyright 2014-2021 Sandor Balazsi <sandor.balazsi@gmail.com>
-- Licensed to the public under the GNU General Public License.

local build_url = require "luci.dispatcher".build_url
local common = require "luci.model.cbi.rtorrent.common"

local map, rss_rule, name, match, enabled

map = Map("rtorrent", "RSS Downloader", common.rss_downloader_status())
map.template = "rtorrent/map"

rss_rule = map:section(TypedSection, "rss-rule")
rss_rule.template = "rtorrent/tblsection"
rss_rule.addremove = true
rss_rule.anonymous = true
rss_rule.sortable = true
rss_rule.extedit = build_url("admin", "rtorrent", "rss", "%s")
rss_rule.create = function(self, section)
	local rule = TypedSection.create(self, section)
	self.map:set(rule, "name", "Unnamed rule")
	luci.http.redirect(build_url("admin", "rtorrent", "rss", rule))
end

name = rss_rule:option(DummyValue, "name", "Name")
name.width = "45%"
name.classes = { "wrap" }

match = rss_rule:option(DummyValue, "match", "Match")
match.width = "54%"
match.classes = { "wrap" }

enabled = rss_rule:option(Flag, "enabled", "Enabled")
enabled.rmempty = false
enabled.width = "1%"
enabled.classes = { "nowrap", "center" }

return map
