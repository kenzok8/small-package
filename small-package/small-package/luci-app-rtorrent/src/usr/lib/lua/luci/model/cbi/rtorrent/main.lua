-- Copyright 2014-2021 Sandor Balazsi <sandor.balazsi@gmail.com>
-- Licensed to the public under the GNU General Public License.

-- Custom fields:
-- d.custom1:		tags (space delimited)
-- d.custom5:		when "1": delete files from disk on erase
-- d.custom.icon:	tracker favicon url
-- d.custom.url:	url of torrent (if applicable)
-- d.custom.comment:	torrent comment (urlencoded)

local nixio = require "nixio"
local rtorrent = require "rtorrent"
local common = require "luci.model.cbi.rtorrent.common"
local array = require "luci.model.cbi.rtorrent.array"
local build_url = require "luci.dispatcher".build_url
require "luci.model.cbi.rtorrent.string"

local compute, format, action, tab, sort, page = {}, {}, {}, unpack(arg)
common.set_cookie("rtorrent-main", { tab, sort, page })

tab = tab or "all"
local default_sort = "name-asc"
sort = sort or default_sort
page = page and tonumber(page) or 1
local sort_column, sort_order = unpack(sort:split("-"))

function compute_values(torrent, index, torrents, ...)
	for _, key in ipairs({ "icon", "size", "total_wanted_chunks", "done", "status",
			"seeder", "leecher", "down_speed", "up_speed", "eta", "tags" }) do
		torrent:set(key, compute[key], index, torrents, ...)
	end
	return torrent
end

function compute.icon(key, torrent) return torrent:get("custom_icon") end
function compute.size(key, torrent) return torrent:get("size_bytes") end
function compute.seeder(key, torrent) return torrent:get("peers_complete") end
function compute.leecher(key, torrent) return torrent:get("peers_accounted") end
function compute.down_speed(key, torrent) return torrent:get("down_rate") end
function compute.up_speed(key, torrent) return torrent:get("up_rate") end

function compute.total_wanted_chunks(key, torrent)
	return torrent:get("wanted_chunks") + torrent:get("completed_chunks")
end

function compute.done(key, torrent)
	if torrent:get("total_wanted_chunks") == torrent:get("size_chunks") then
		return 100.0 * torrent:get("bytes_done") / torrent:get("size_bytes")
	else
		return math.min(100.0 * torrent:get("completed_chunks") / torrent:get("total_wanted_chunks"), 100)
	end
end

function compute.status(key, torrent)
	-- 1: down, 2: stop, 3: pause, 4: hash, 5: seed, 6: unknown
	if torrent:get("hashing") > 0 then return 4
	elseif torrent:get("state") == 0 then return 2
	elseif torrent:get("state") > 0 then
		if torrent:get("is_active") == 0 then return 3
		elseif torrent:get("wanted_chunks") > 0 then return 1
		else return 5 end
	else return 6 end
end

function compute.eta(key, torrent)
	-- 0: already done, math.huge: infinite
	if torrent:get("wanted_chunks") == 0 then return 0
	elseif torrent:get("down_rate") > 0 then
		if torrent:get("total_wanted_chunks") == torrent:get("size_chunks") then
			return (torrent:get("size_bytes") - torrent:get("bytes_done")) / torrent:get("down_rate")
		else
			return torrent:get("wanted_chunks") * torrent:get("chunk_size") / torrent:get("down_rate")
		end
	else return math.huge end
end

function compute.tags(key, torrent)
	local tags = array(torrent:get("custom1"):split()):insert("all")
	if torrent:get("wanted_chunks") > 0 then tags:insert("incomplete") end
	return tags:unique():join(" ")
end

function compute_tabs(torrent, index, torrents, tabs, tab)
	if index == 1 then
		local torrent_tags = array(torrents:map(function(torrent)
			return torrent:get("tags") end):join(" "):split()):unique():sort()
		if torrent_tags:contains("incomplete") then tabs:insert("incomplete") end
		torrent_tags:foreach(function(tag) tabs:insert(tag) end)
		tabs:insert(tab)
	end
end

function compute_total(torrent, index, torrents, total)
	total:increment("count")
	total:increment("size", torrent:get("size"))
	total:increment("down_speed", torrent:get("down_speed"))
	total:increment("up_speed", torrent:get("up_speed"))
	if torrents:last(index) then
		format_values(total:set(".total_row", true)
			:set("name", "TOTAL: %d pcs." % total:get("count")))
	end
end

function format_values(torrent, index, torrents, ...)
	for key, value in torrent:pairs() do
		torrent:set(key, format[key]
		and format[key](value, key, torrent, index, torrents, ...) or value)
	end
	return torrent
end

function format.done(value) return "%.1f%%" % value end
function format.seeder(value) return tostring(value) end
function format.leecher(value) return tostring(value) end
function format.down_speed(value) return "%.2f" % (value / 1000) end
function format.up_speed(value) return "%.2f" % (value / 1000) end

function format.icon(value)
	return '<img src="%s" width="16" height="16" title="%s"/>' % {
		value, common.get_domain(value)
	}
end

function format.name(value, key, torrent)
	if torrent:get("hash") then
		local url = build_url("admin", "rtorrent", "torrent", "info", torrent:get("hash"))
		return '<a href="%s">%s</a>' % { url, value }
	else
		return value
	end
end

function format.size(value)
	return '<div title="%s B">%s</div>' % { value, common.human_size(value) }
end

function format.status(value)
	local text, color = "", ""
	if value == 1 then text, color = "down", ' class="green"'
	elseif value == 2 then text, color = "stop", ' class="red"'
	elseif value == 3 then text, color = "pause", ' class="orange"'
	elseif value == 4 then text, color = "hash", ' class="green"'
	elseif value == 5 then text, color = "seed", ' class="blue"'
	elseif value == 6 then text, color = "unknown", "" end
	return '<div%s>%s</div>' % { color, text }
end

function format.ratio(value, key, torrent)
	return '<div title="Total uploaded: %s" class="%s">%.2f</div>' % {
		common.human_size(torrent:get("up_total")),
		value < 1000 and "red" or "green",
		value / 1000
	}
end

function format.eta(value, key, torrent)
	local download_started = tonumber(torrent:get("timestamp_started")) ~= 0
		and os.date("!%Y-%m-%d %H:%M:%S", torrent:get("timestamp_started"))
		or "not yet started"
	local download_finished = tonumber(torrent:get("timestamp_finished")) ~= 0
		and os.date("!%Y-%m-%d %H:%M:%S", torrent:get("timestamp_finished"))
		or "not yet finished"
	local text, color = "", ""
	if value == 0 then text, color = "--", ""
	elseif value == math.huge then text, color = "&#8734;", ' class="red"'
	else text, color = common.human_time(value), "" end
	return '<div title="Download started: %s&#13;Download finished: %s"%s>%s</div>' % {
		download_started, download_finished, color, text
	}
end

function action.start(hash)
	local status = rtorrent.batchcall("d.", hash, "state", "is_active")
	if status.state == 0 then rtorrent.call("d.start", hash)
	elseif status.is_active == 0 then rtorrent.call("d.resume", hash) end
end

function action.pause(hash) rtorrent.batchcall("d.", hash, "start", "pause") end
function action.stop(hash) rtorrent.batchcall("d.", hash, "stop", "close") end
function action.hash(hash) rtorrent.call("d.check_hash", hash) end
function action.remove(hash) rtorrent.batchcall("d.", hash, "close", "erase") end
function action.purge(hash) rtorrent.batchcall("d.", hash, "custom5.set=1", "close", "erase") end

function filter_by_tab(torrent, index, torrents, tab)
	return string.find(" " .. torrent:get("tags") .. " ", " " .. tab .. " ")
end

local tabs, checked, total = array({ "all" }), array(), array():set("count", 0)
local torrents = array(rtorrent.multicall("d.", "", "default",
	"hash", "name", "hashing", "state", "is_active", "complete",
	"size_bytes", "bytes_done", "size_chunks", "wanted_chunks", "completed_chunks", "chunk_size",
	"peers_accounted", "peers_complete", "down.rate", "up.rate", "ratio", "up.total",
	"timestamp.started", "timestamp.finished", "custom1", "custom=icon"))
	:foreach(compute_values)
	:foreach(compute_tabs, tabs, tab)
	:filter(filter_by_tab, tab)
	:foreach(compute_total, total)
	:sort(sort_column, sort_order)
	:limit(10, (page - 1) * 10)
	:foreach(format_values)
	:insert(total:get("count") > 1 and total or nil)

local form, list, icon, name, size, done, status, seeder, leecher, down_speed, up_speed, ratio, eta, check

form = SimpleForm("rtorrent", "Torrent List")
form.submit = false
form.reset = false
form.handle = function(self, state, data)
	if state == FORM_VALID then
		checked:foreach(function(hash) action[self:formvalue("cbi.action")](hash) end)
		luci.http.redirect(nixio.getenv("REQUEST_URI"))
	end
	return true
end

list = form:section(Table, torrents:get())
list.template = "rtorrent/tblsection_main"
list.name = "rtorrent-torrents"
list.pages = common.pagination(total:get("count") or torrents:size(), tonumber(page),
	common.pagination_link, build_url("admin", "rtorrent", "main", tab, sort)):join()
list.column = function(self, class, option, title, tooltip, sort_by)
	return self:option(class, option, '<a href="%s" title="%s"%s>%s</a>' % {
		build_url("admin", "rtorrent", "main", tab, sort_by),
		tooltip, sort == sort_by and ' class="active"' or "", title
	})
end
list.action = function(self, key, value, classes)
	self.actions[key] = value
	self.action_classes[key] = "btn cbi-button important " .. classes
	table.insert(self.action_order, key)
end
list.root_path = build_url("admin", "rtorrent", "main")
tabs:unique():foreach(function(tab) list:tab(tab, tab:ucfirst()) end)
list.selected_tab = tabs:contains(tab) and tab or "all"
list.default_sort = default_sort
list.sort = sort
list.actions, list.action_classes, list.action_order = {}, {}, {}
list:action("start", "Start", "cbi-button-save")
list:action("pause", "Pause", "cbi-button-apply")
list:action("stop", "Stop", "cbi-button-apply")
list:action("hash", "Check hash", "cbi-button-apply")
list:action("remove", "Remove", "cbi-button-negative")
list:action("purge", "Remove and delete from disk", "cbi-button-negative")

icon = list:option(DummyValue, "icon")
icon.rawhtml = true
icon.width = "1%"
icon.classes = { "nowrap" }

name = list:column(DummyValue, "name", "Name", "Sort by name", "name-asc")
name.rawhtml = true
name.classes = { "wrap" }

size = list:column(DummyValue, "size", "Size", "Sort by total size", "size-desc")
size.rawhtml = true
size.width = "1%"
size.classes = { "nowrap", "center" }

done = list:column(DummyValue, "done", "Done", "Sort by download done percent", "done-desc")
done.rawhtml = true
done.width = "1%"
done.classes = { "nowrap", "center" }

status = list:column(DummyValue, "status", "Status", "Sort by status", "status-asc")
status.rawhtml = true
status.width = "1%"
status.classes = { "nowrap", "center" }

seeder = list:column(DummyValue, "seeder", "&#9660;", "Sort by seeder count", "seeder-desc")
seeder.rawhtml = true
seeder.width = "1%"
seeder.classes = { "nowrap", "center" }

leecher = list:column(DummyValue, "leecher", "&#9650;", "Sort by leecher count", "leecher-desc")
leecher.rawhtml = true
leecher.width = "1%"
leecher.classes = { "nowrap", "center" }

down_speed = list:column(DummyValue, "down_speed", "Down<br />Speed",
	"Sort by download speed (kB/s)", "down_speed-desc")
down_speed.rawhtml = true
down_speed.width = "1%"
down_speed.classes = { "nowrap", "center" }

up_speed = list:column(DummyValue, "up_speed", "Up<br />Speed",
	"Sort by upload speed (kB/s)", "up_speed-desc")
up_speed.rawhtml = true
up_speed.width = "1%"
up_speed.classes = { "nowrap", "center" }

ratio = list:column(DummyValue, "ratio", "Ratio", "Sort by download/upload ratio", "ratio-desc")
ratio.rawhtml = true
ratio.width = "1%"
ratio.classes = { "nowrap", "center" }

eta = list:column(DummyValue, "eta", "ETA", "Sort by Estimated Time of Arrival", "eta-desc")
eta.rawhtml = true
eta.width = "1%"
eta.classes = { "nowrap", "center" }

check = list:option(Flag, "check")
check.width = "1%"
check.classes = { "nowrap", "center" }
check.write = function(self, section, value)
	if torrents:get(section):get("hash") then
		checked:insert(torrents:get(section):get("hash"))
	end
end

return form
