-- Copyright 2014-2021 Sandor Balazsi <sandor.balazsi@gmail.com>
-- Licensed to the public under the GNU General Public License.

local rtorrent = require "rtorrent"
local json = require "luci.jsonc"
local build_url = require "luci.dispatcher".build_url
local common = require "luci.model.cbi.rtorrent.common"
local array = require "luci.model.cbi.rtorrent.array"
require "luci.model.cbi.rtorrent.string"

local compute, format, hash, sort, page = {}, {}, unpack(arg)
common.set_cookie("rtorrent-peers", { hash, sort, page })

local ip_location, country_flag, map = {}, {}, {}
sort = sort or "down_speed-desc"
page = page and tonumber(page) or 1
local sort_column, sort_order = unpack(sort:split("-"))

local ip_location_provider = "geoplugin_net"
local country_flag_provider = "hltv_org"
local map_provider = "googlemap"

function ip_location.geoplugin_net(address)
	return array({
		url = "http://www.geoplugin.net/json.gp?ip=%s" % address,
		fields = array({
			country_code = "geoplugin_countryCode", country = "geoplugin_countryName",
			region = "geoplugin_region", city = "geoplugin_city",
			latitude = "geoplugin_latitude", longitude = "geoplugin_longitude"
		})
	})
end

function country_flag.prgmea_org(country_code)
	return array({ url = "http://prgmea.org/assets/falcon/images/flags/16x16/%s.png" % country_code })
end

function country_flag.ip2location_com(country_code)
	return array({ url = "https://cdn.ip2location.com/assets/img/flags/%s.png" % country_code })
end

function country_flag.hltv_org(country_code)
	return array({ url = "http://static.hltv.org/images/flag/%s.gif" % country_code })
end

function map.googlemap(latitude, longitude, zoom)
	return array({
		url = "https://google.com/maps/place/%s,%s/@%s,%s,%sz" % {
			latitude, longitude, latitude, longitude, zoom
		}
	})
end

function map.openstreetmap(latitude, longitude, zoom)
	return array({
		url = "http://www.openstreetmap.org/?mlat=%s&mlon=%s#map=%s/%s/%s/m" % {
			latitude, longitude, zoom, latitude, longitude
		}
	})
end

function compute_total(peer, index, peers, total)
	total:increment("count")
	total:increment("down_speed", peer:get("down_speed"))
	total:increment("up_speed", peer:get("up_speed"))
	if peers:last(index) then
		format_values(total:set(".total_row", true)
			:set("location", "TOTAL: %d pcs." % total:get("count")))
	end
end

function compute_values(peer, index, peers, ...)
	for _, key in ipairs({ "client", "flags", "done", "down_speed", "up_speed", "downloaded", "uploaded" }) do
		peer:set(key, compute[key], index, peers, ...)
	end
end

function compute.client(key, peer) return peer:get("client_version") end
function compute.done(key, peer) return peer:get("completed_percent") end
function compute.down_speed(key, peer) return peer:get("down_rate") end
function compute.up_speed(key, peer) return peer:get("up_rate") end
function compute.downloaded(key, peer) return peer:get("down_total") end
function compute.uploaded(key, peer) return peer:get("up_total") end

function compute.flags(key, peer)
	local flags = ""
	if peer:get("banned") == 1 then flags = flags .. "B" end
	if peer:get("is_incoming") == 1 then flags = flags .. "I" end
	if peer:get("is_encrypted") == 1 then flags = flags .. "E"
	elseif peer:get("is_obfuscated") == 1 then flags = flags .. "e" end
	if peer:get("is_snubbed") == 1 then flags = flags .. "S" end
	if peer:get("is_preferred") == 1 then flags = flags .. "F"
	elseif peer:get("is_unwanted") == 1 then flags = flags .. "f" end
	return flags
end

function compute_geolocation(peer, index, peers, ...)
	for _, key in ipairs({ "location", "icon" }) do
		peer:set(key, compute[key], index, peers, ...)
	end
end

function compute.icon(key, peer)
	return peer:get("country_code"):blank() and ""
		or country_flag[country_flag_provider](peer:get("country_code"):lower()):get("url")
end

function compute.location(key, peer)
	local location_provider = ip_location[ip_location_provider](peer:get("address"))
	local response, err, headers, code, status = common.download(location_provider:get("url"))
	local location = array(json.parse(response or ""))
	location_provider:get("fields"):foreach(function(field, key)
		peer:set(key, location:get(field) or "")
	end)
	if code == 429 then peer:set("country", "Location service rate limit reached!")
	elseif peer:get("country"):blank() then peer:set("country", "Unknown") end
	return array({ "country", "region", "city" })
		:map(function(field) return peer:get(field):unicode_to_html() end)
		:filter(string.not_blank)
		:join(" / ")
end

function format_values(peer, index, peers, ...)
	for key, value in peer:pairs() do
		peer:set(key, format[key]
		and format[key](value, key, peer, index, peers, ...) or value)
	end
	return peer
end

function format.icon(value) return value and '<img src="%s" />' % value or "" end
function format.done(value) return "%.1f%%" % value end
function format.down_speed(value) return "%.2f" % (value / 1000) end
function format.up_speed(value) return "%.2f" % (value / 1000) end
function format.uploaded(value) return format.downloaded(value) end

function format.downloaded(value)
	return "<div title=\"%s B\">%s</div>" % {
		value, value == 0 and "--" or common.human_size(value)
	}
end

function format.location(value, key, peer)
	if peer:get("latitude") and peer:get("latitude"):not_blank() then
		return '<a href="%s" target="_blank">%s</a>' % {
			map[map_provider](peer:get("latitude"), peer:get("longitude"), 12):get("url"),
			value
		}
	else return value end
end

function format.flags(value)
	local title = array()
	if value:match("B") then title:insert("Peer is banned") end
	if value:match("I") then title:insert("Peer is an incoming connection") end
	if value:match("E") then title:insert("Peer is using protocol encryption")
	elseif value:match("e") then title:insert("Peer is using header message obfuscation") end
	if value:match("S") then title:insert("Peer is snubbed") end
	if value:match("F") then title:insert("Peer is marked as preferred")
	elseif value:match("f") then title:insert("Peer is marked as unwanted") end
	return '<div title="%s">%s</div>' % { title:join("&#13;"), value }
end

local total = array():set("count", 0)
local torrent = array(rtorrent.batchcall("d.", hash, "name"))
local peers = array(rtorrent.multicall("p.", hash, "",
	"address", "client_version", "banned",
	"is_incoming", "is_encrypted", "is_obfuscated", "is_snubbed", "is_preferred", "is_unwanted",
	"completed_percent", "down_rate", "up_rate", "up_total", "down_total"))
	:foreach(compute_values)
	:foreach(compute_total, total)
	:sort(sort_column, sort_order)
	:limit(10, (page - 1) * 10)
	:foreach(compute_geolocation)
	:foreach(format_values)
	:insert(total:get("count") > 1 and total or nil)

local form, list, icon, location, address, client, flags, done, down_speed, up_speed, downloaded, uploaded

_G.redirect = build_url("admin", "rtorrent", "main", unpack(common.get_cookie("rtorrent-main", {})))
form = SimpleForm("rtorrent", torrent:get("name"))
form.template = "rtorrent/simpleform"
form.submit = false
form.reset = false
form.all_tabs = array():append("info", "files", "trackers", "peers", "chunks"):get()
form.tab_url_postfix = function(tab)
	local filters = (tab == "peers") and array(arg) or array(common.get_cookie("rtorrent-" .. tab, {}))
	return filters:get(1) == hash and filters:join("/") or hash
end
form.handle = function(self, state, data)
	if state == FORM_VALID then luci.http.redirect(nixio.getenv("REQUEST_URI")) end
	return true
end

list = form:section(Table, peers:get())
list.template = "rtorrent/tblsection"
list.name = "rtorrent-peers"
list.pages = common.pagination(total:get("count") or peers:size(), page, common.pagination_link,
	build_url("admin", "rtorrent", "torrent", "peers", hash, sort)):join()
list.column = function(self, class, option, title, tooltip, sort_by)
	return self:option(class, option, '<a href="%s" title="%s"%s>%s</a>' % {
		build_url("admin", "rtorrent", "torrent", "peers", hash, sort_by),
		tooltip, sort == sort_by and ' class="active"' or "", title
	})
end

icon = list:option(DummyValue, "icon")
icon.rawhtml = true
icon.width = "1%"
icon.classes = { "nowrap" }

location = list:option(DummyValue, "location",
	'<span title="Location: country / region / city">Location</span>')
location.rawhtml = true
location.classes = { "wrap" }

address = list:option(DummyValue, "address", "Address")
address.rawhtml = true
address.width = "1%"
address.classes = { "nowrap", "center" }

client = list:column(DummyValue, "client", "Client", "Sort by client version", "client-asc")
client.width = "1%"
client.classes = { "nowrap", "center" }

flags = list:column(DummyValue, "flags", "Flags", "Sort by peer flags", "flags-asc")
flags.rawhtml = true
flags.width = "1%"
flags.classes = { "nowrap", "center" }

done = list:column(DummyValue, "done", "Done", "Sort by peer completed data percent", "done-desc")
done.width = "1%"
done.classes = { "nowrap", "center" }

down_speed = list:column(DummyValue, "down_speed", "Down<br />Speed",
	"Sort by download speed (kB/s)", "down_speed-desc")
down_speed.width = "1%"
down_speed.classes = { "nowrap", "center" }

up_speed = list:column(DummyValue, "up_speed", "Up<br />Speed",
	"Sort by upload speed (kB/s)", "up_speed-desc")
up_speed.width = "1%"
up_speed.classes = { "nowrap", "center" }

downloaded = list:column(DummyValue, "downloaded", "Down-<br />loaded",
	"Sort by total downloaded from peer", "downloaded-desc")
downloaded.rawhtml = true
downloaded.width = "1%"
downloaded.classes = { "nowrap", "center" }

uploaded = list:column(DummyValue, "uploaded", "Up-<br />loaded",
	"Sort by total uploaded to peer", "uploaded-desc")
uploaded.rawhtml = true
uploaded.width = "1%"
uploaded.classes = { "nowrap", "center" }

return form
