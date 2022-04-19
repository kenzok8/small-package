-- Copyright 2014-2021 Sandor Balazsi <sandor.balazsi@gmail.com>
-- Licensed to the public under the GNU General Public License.

local rtorrent = require "rtorrent"
local build_url = require "luci.dispatcher".build_url
local common = require "luci.model.cbi.rtorrent.common"
local array = require "luci.model.cbi.rtorrent.array"
require "luci.model.cbi.rtorrent.string"

local compute, format, hash, sort, page = {}, {}, unpack(arg)
common.set_cookie("rtorrent-trackers", { hash, sort, page })
common.remove_cookie("rtorrent-notifications")

sort = sort or "status-asc"
page = page and tonumber(page) or 1
local sort_column, sort_order = unpack(sort:split("-"))

function compute_total(tracker, index, trackers, total)
	total:increment("count")
	total:increment("latest_new_peers", tracker:get("latest_new_peers"))
	total:increment("latest_sum_peers", tracker:get("latest_sum_peers"))
	total:increment("seeds", tracker:get("seeds"))
	total:increment("leeches", tracker:get("leeches"))
	total:increment("downloaded", tracker:get("downloaded"))
	total:get("urls"):insert(tracker:get("url"))
	if trackers:last(index) then
		format_values(total:set(".total_row", true)
			:set("url", "TOTAL: %d pcs." % total:get("count"))
			:set("peers", compute.peers))
	end
end

function compute_values(tracker, index, trackers, ...)
	for _, key in ipairs({ "index", "icon", "status", "peers",
			"seeds", "leeches", "downloaded", "updated", "enabled" }) do
		tracker:set(key, compute[key], index, trackers, ...)
	end
end

function compute.index(key, tracker, index) return index - 1 end
function compute.seeds(key, tracker) return tracker:get("scrape_complete") end
function compute.leeches(key, tracker) return tracker:get("scrape_incomplete") end
function compute.downloaded(key, tracker) return tracker:get("scrape_downloaded") end
function compute.updated(key, tracker) return tracker:get("scrape_time_last") end
function compute.enabled(key, tracker) return tracker:get("is_enabled") end

function compute.icon(key, tracker)
	return common.tracker_icon(array({ tracker:get("url") }))
end

function compute.status(key, tracker, index, trackers, torrent)
	-- 1: working, 2: updating, 3: faulty, 4: stopped, 5: inactive
	local status = 3
	if torrent:get("state") == 0 then status = 4
	elseif tracker:get("is_enabled") == 0 then status = 5
	elseif tracker:get("failed_counter") == 0
		and tracker:get("success_counter") == 0 then status = 2
	elseif tracker:get("failed_counter") == 0 then status = 1 end
	return status
end

function compute.peers(key, tracker)
	return tracker:get("latest_new_peers") + tracker:get("latest_sum_peers") * 1e9
end

function format_values(tracker, index, trackers, ...)
	for key, value in tracker:pairs() do
		tracker:set(key, format[key]
		and format[key](value, key, tracker, index, trackers, ...) or value)
	end
	return tracker
end

function format.icon(value) return '<img src="%s" width="16" height="16"/>' % value end
function format.seeds(value) return tostring(value) end
function format.leeches(value) return tostring(value) end
function format.downloaded(value) return tostring(value) end
function format.updated(value) return common.human_time(os.time() - value) end
function format.enabled(value) return tostring(value) end

function format.status(value, key, tracker)
	local last_success = tracker:get("success_time_last") ~= 0
		and os.date("!%Y-%m-%d %H:%M:%S", tracker:get("success_time_last")) or "never succeeded"
	local last_failed = tracker:get("failed_time_last") ~= 0
		and os.date("!%Y-%m-%d %H:%M:%S", tracker:get("failed_time_last")) or "never failed"
	local text, color = "", ""
	if value == 1 then text, color = "working", "green"
	elseif value == 2 then text, color = "updating", "blue"
	elseif value == 3 then text, color = "faulty", "red"
	elseif value == 4 then text = "stopped"
	elseif value == 5 then text = "inactive" end
	return '<div title="Last succeeded request: %s&#13;Last failed request: %s" class="%s">%s</div>' % {
		last_success, last_failed, color, text
	}
end

function format.peers(value)
	local latest_new_peers, latest_sum_peers = value % 1e9, math.floor(value / 1e9)
	return '<div title="New peers / Peers obtained with last announce">%d/%d</div>' % {
		latest_new_peers, latest_sum_peers
	}
end

local total = array():set("count", 0):set("urls", array())
local torrent = array(rtorrent.batchcall("d.", hash, "name", "state", "is_active"))
local trackers = array(rtorrent.multicall("t.", hash, "",
	"is_enabled", "url", "latest_new_peers", "latest_sum_peers",
	"failed_counter", "success_counter", "success_time_last", "failed_time_last",
	"scrape_complete", "scrape_incomplete", "scrape_downloaded", "scrape_time_last"))
	:foreach(compute_values, torrent)
	:foreach(compute_total, total)
	:sort(sort_column, sort_order)
	:limit(10, (page - 1) * 10)
	:foreach(format_values)
	:insert(total:get("count") > 1 and total or nil)

local form, list, icon, url, status, peers, seeds, leeches, downloaded, updated, enabled, add

_G.redirect = build_url("admin", "rtorrent", "main", unpack(common.get_cookie("rtorrent-main", {})))
form = SimpleForm("rtorrent", torrent:get("name"))
form.template = "rtorrent/simpleform"
form.notifications = common.get_cookie("rtorrent-notifications", {})
form.all_tabs = array():append("info", "files", "trackers", "peers", "chunks"):get()
form.tab_url_postfix = function(tab)
	local filters = (tab == "trackers") and array(arg) or array(common.get_cookie("rtorrent-" .. tab, {}))
	return filters:get(1) == hash and filters:join("/") or hash
end
form.handle = function(self, state, data)
	if state == FORM_VALID then
		common.set_cookie("rtorrent-notifications", form.notifications)
		luci.http.redirect(nixio.getenv("REQUEST_URI"))
	end
	return true
end
form.cancel = "Trigger tracker scrape"
form.on_cancel = function()
	rtorrent.batchcall("d.", hash, "tracker.send_scrape=0", "save_resume")
	luci.http.redirect(nixio.getenv("REQUEST_URI"))
end

list = form:section(Table, trackers:get())
list.template = "rtorrent/tblsection"
list.name = "rtorrent-trackers"
list.pages = common.pagination(total:get("count") or trackers:size(), page, common.pagination_link,
	build_url("admin", "rtorrent", "torrent", "trackers", hash, sort)):join()
list.column = function(self, class, option, title, tooltip, sort_by)
	return self:option(class, option, '<a href="%s" title="%s"%s>%s</a>' % {
		build_url("admin", "rtorrent", "torrent", "trackers", hash, sort_by),
		tooltip, sort == sort_by and ' class="active"' or "", title
	})
end

icon = list:option(DummyValue, "icon")
icon.rawhtml = true
icon.width = "1%"
icon.classes = { "nowrap" }

url = list:column(DummyValue, "url", "Url", "Sort by url", "url-asc")
url.classes = { "wrap" }

status = list:column(DummyValue, "status", "Status", "Sort by tracker status", "status-asc")
status.rawhtml = true
status.width = "1%"
status.classes = { "nowrap", "center" }

peers = list:column(DummyValue, "peers", "Peers", "Sort by peers", "peers-desc")
peers.rawhtml = true
peers.width = "1%"
peers.classes = { "nowrap", "center" }

seeds = list:column(DummyValue, "seeds", "Seeds", "Sort by complete peers", "seeds-desc")
seeds.classes = { "nowrap", "center" }

leeches = list:column(DummyValue, "leeches", "Leeches", "Sort by incomplete peers", "leeches-desc")
leeches.width = "1%"
leeches.classes = { "nowrap", "center" }

downloaded = list:column(DummyValue, "downloaded", "Downloaded",
	"Sort by number of downloads", "downloaded-desc")
downloaded.width = "1%"
downloaded.classes = { "nowrap", "center" }

updated = list:column(DummyValue, "updated", "Updated", "Sort by last scrape time", "updated-desc")
updated.rawhtml = true
updated.width = "1%"
updated.classes = { "nowrap", "center" }

enabled = list:column(Flag, "enabled", "Enabled", "Sort by enabled state", "enabled-desc")
enabled.width = "1%"
enabled.classes = { "nowrap", "center" }
enabled.rmempty = false
enabled.write = function(self, section, value)
	if trackers:get(section):get("index") and value ~= trackers:get(section):get("is_enabled") then
		rtorrent.call("t.is_enabled.set",
			hash .. ":t" .. trackers:get(section):get("index"), tonumber(value))
	end
end

add = form:field(TextValue, "add_tracker", "Add tracker(s)", "All tracker URL should be in a separate line.")
add.rows = 2
add.validate = function(self, value, section)
	local errors = array()
	for _, line in ipairs(value:split("\r\n")) do
		if not line:trim():lower():match("^%w+://[%w_-]+%.[%w_-]+") then
			errors:insert("Invalid URL: %s" % line:trim())
		elseif total:get("urls"):contains(line:trim()) then
			table.insert(form.notifications, "Skipped existing tracker <i>%s</i>" % line:trim())
		else
			table.insert(form.notifications, "Added tracker <i>%s</i>" % line:trim())
		end
	end
	if not errors:empty() then
		form.notifications = {}
		for i, err in errors:pairs() do
			if not errors:last(i) then self:add_error(section, err) end
		end
		return nil, errors:last()
	end
	return value
end
add.write = function(self, section, value)
	local tracker_group = trackers:filter(function(value) return value:get("index") end):size()
	local tracker_added = false
	for _, line in ipairs(value:split("\r\n")) do
		if not total:get("urls"):contains(line:trim()) then
			rtorrent.call("d.tracker.insert", hash, tracker_group, line:trim())
			tracker_group, tracker_added = (tracker_group + 1) % 33, true
		end
	end
	if tracker_added and torrent:get("state") > 0 then
		if torrent:get("is_active") == 0 then
			rtorrent.batchcall("d.", hash, "stop", "close", "start", "pause")
		else
			rtorrent.batchcall("d.", hash, "stop", "close", "start")
		end
	end
end

return form
