-- Copyright 2014-2021 Sandor Balazsi <sandor.balazsi@gmail.com>
-- Licensed to the public under the GNU General Public License.

local nixio = require "nixio"
local rtorrent = require "rtorrent"
local build_url = require "luci.dispatcher".build_url
local common = require "luci.model.cbi.rtorrent.common"
local array = require "luci.model.cbi.rtorrent.array"
require "luci.model.cbi.rtorrent.string"

local hash = unpack(arg)
local form, infohash, url, started, finished, status, tags, comment

local torrent = array(rtorrent.batchcall("d.", hash,
	"name", "timestamp.started", "timestamp.finished", "message",
	"custom1", "custom=icon", "custom=url", "custom=comment"))

_G.redirect = build_url("admin", "rtorrent", "main", unpack(common.get_cookie("rtorrent-main", {})))
form = SimpleForm("rtorrent", torrent:get("name"))
form.template = "rtorrent/simpleform"
form.all_tabs = array():append("info", "files", "trackers", "peers", "chunks"):get()
form.tab_url_postfix = function(tab)
	local filters = array(common.get_cookie("rtorrent-" .. tab, {}))
	return filters:get(1) == hash and filters:join("/") or hash
end
form.handle = function(self, state, data)
	if state == FORM_VALID then
		luci.http.redirect(nixio.getenv("REQUEST_URI"))
	end
	return true
end

infohash = form:field(DummyValue, "hash", "Hash")
infohash.template = "rtorrent/dvalue"
infohash.rawhtml = true
infohash.value = '<div class="cbi-dummy">%s</div>' % hash

local torrent_url = torrent:get("custom_url"):urldecode()
url = form:field(DummyValue, "url", "Torrent URL")
url.template = "rtorrent/dvalue"
url.rawhtml = true
url.value = '<div class="cbi-dummy">%s</div>' % (torrent_url:blank()
	and 'Unknown, added by an uploaded torrent file or magnet URI.'
	or '<a href="%s" target="_blank">%s</a>' % { torrent_url , torrent_url })

started = form:field(DummyValue, "started", "Download started")
started.template = "rtorrent/dvalue"
started.rawhtml = true
started.value = '<div class="cbi-dummy">%s</div>' % (torrent:get("timestamp_started") == 0
	and "not yet started"
	or os.date("!%Y-%m-%d %H:%M:%S", torrent:get("timestamp_started")))

finished = form:field(DummyValue, "finished", "Download finished")
finished.template = "rtorrent/dvalue"
finished.rawhtml = true
finished.value = '<div class="cbi-dummy">%s</div>' % (torrent:get("timestamp_finished") == 0
	and "not yet finished"
	or os.date("!%Y-%m-%d %H:%M:%S", torrent:get("timestamp_finished")))

status = form:field(DummyValue, "status", "Status")
status.template = "rtorrent/dvalue"
status.rawhtml = true
status.value = '<div class="cbi-dummy">%s</div>' % torrent:get("message")

tags = form:field(Value, "tags", "Tags")
tags.cfgvalue = function(self, section) return torrent:get("custom1") end
tags.write = function(self, section, value)
	rtorrent.call("d.custom1.set", hash, value)
end
tags.remove = function(self, section)
	if self:cfgvalue(section) ~= "" then
		self:write(section, "")
	end
end

comment = form:field(TextValue, "comment", "Comment")
comment.rows = 5
comment.cfgvalue = function(self, section)
	return torrent:get("custom_comment"):urldecode()
end
comment.write = function(self, section, value)
	rtorrent.call("d.custom.set", hash, "comment", value:urlencode())
end
comment.remove = function(self, section)
	if self:cfgvalue(section) ~= "" then
		self:write(section, "")
	end
end

return form
