#!/usr/bin/lua
-- Copyright 2014-2021 Sandor Balazsi <sandor.balazsi@gmail.com>
-- Licensed to the public under the GNU General Public License.

local nixio = require "nixio"
local xml = require "lxp.lom"
local bencode = require "bencode"
local date = require "luci.http.date"
local uci = require "luci.model.uci".cursor()
local logger = require "luci.model.cbi.rtorrent.logger"
local common = require "luci.model.cbi.rtorrent.common"
local array = require "luci.model.cbi.rtorrent.array"
require "luci.model.cbi.rtorrent.string"

local log
local aria2_timeout_seconds = 60

function next_tag(xml, tag, index)
	index = index or 1
	if not xml then return nil, index end
	while xml[index] do
		if type(xml[index]) == "table" and xml[index].tag == tag then
			return xml[index], index
		end
		index = index + 1
	end
end

function prev_tag(xml, tag, index)
	if not xml then return nil, index end
	index = index or #xml
	while xml[index] do
		if type(xml[index]) == "table" and xml[index].tag == tag then
			return xml[index], index
		end
		index = index - 1
	end
end

function fix_date(date)
	return date:gsub("(%a+%s+)(%d%d)(%s+%d+)", function(month, year, hour)
		return month .. "20" .. year .. hour
	end)
end

function rss_feeds()
	return common.uci_sections("rtorrent", "rss-feed")
		:filter(function(feed) return feed:get("enabled") == "1" end)
end

function rss_rules()
	return common.uci_sections("rtorrent", "rss-rule")
		:filter(function(rule) return rule:get("enabled") == "1" end)
end

function fetch_feed(url)
	local content, err = common.download(url)
	if not content then log:error('Failed to download RSS feed "%s": %s' % { url, err })
	else
		local rss, err = xml.parse(content)
		if not rss then log:error('Failed to parse RSS feed "%s": %s' % { url, err })
		else return rss end
	end
end

function rss_item_url(item)
	local enclosure, url = next_tag(item, "enclosure")
	if enclosure and enclosure.attr.url then return enclosure.attr.url end
	local link = next_tag(item, "link")
	if link and link[1] then return link[1] end
	log:error("Failed to obtain download link of RSS item")
	return nil
end

function torrent_size(url)
	local content, code, err
	if "file://" == url:sub(1, 7) then content, code, err = nixio.fs.readfile(url:sub(8))
	else content, err = common.download(url) end
	if not content then return log:error('Failed to download torrent "%s": %s' % { url, err }) end
	local torrent, err = bencode.decode(content)
	if not torrent or not torrent.info then
		return log:error('Failed to parse torrent "%s": %s' % { url, err })
	end
	local size = 0
	array(torrent.info):traverse(function(value, key)
		if key == "length" then size = size + value end
	end)
	if size == 0 then
		local sha1_size = 20
		local piece_length = torrent.info["piece length"]
		local piece_count = torrent.info.pieces:len() / sha1_size
		-- note: when the last piece is shorter (not a full piece length)
		-- then the calculated size is bigger (with piece length - last piece length)
		size = piece_length * piece_count
	end
	if size > 0 then return size / 1024 / 1024 end
end

function magnet_size(uri)
	uri = uri:gsub("&amp;", "&"):gsub("^<![CDATA[", ""):gsub("]]$", "")
	local magnet, err = common.parse_magnet(uri)
	if not magnet then return log:error('Failed to parse magnet uri "%s": %s', { uri, err }) end
	local size = 0
	if magnet:keys():contains("xl") then
		magnet:get("xl"):foreach(function(value) size = size + tonumber(value) end)
		size = size / 1024 / 1024
	end
	if size == 0 and nixio.fs.stat("/usr/bin/aria2c", "type") ~= "reg" then
		log:trace("Feed items contain magnet links without length parameter, install aria2 utility")
	else
		log:trace("Feed items contain magnet links without length parameter, "
			.. "trying to obtain the torrent file with aria2 (max %d seconds)" % aria2_timeout_seconds)
		local exit_code = os.execute("/usr/bin/aria2c --dir=/tmp --quiet=true --bt-metadata-only=true "
			.. '--bt-save-metadata=true --bt-stop-timeout=%d "%s"' % { aria2_timeout_seconds, uri })
		log:trace("Obtain torrent file from magnet uri by aria2: %s" % tostring(exit_code == 0))
		if exit_code == 0 then
			magnet:get("xt"):foreach(function(value)
				local torrent_file = "/tmp/%s.torrent" % value:gsub("^urn:btih:", "")
				size = size + torrent_size("file://%s" % torrent_file)
				nixio.fs.remove(torrent_file)
			end)
		end
	end
	if size > 0 then return size end
end

function filter_by_feed(rule, feed)
	local match_feed = array(rule:get("feed"):split("|")):contains(feed:get("name")) and true
	log:trace('Matching by feed "%s": %s' % { rule:get("feed"), tostring(match_feed) })
	return match_feed
end

function filter_by_title(rule, title)
	local match_title = title:lower():find(rule:get("match"):lower_pattern()) and true
	log:trace('Matching by title "%s": %s' % { rule:get("match"), tostring(match_title) })
	local match_exclude = not rule:get("exclude") or not title:lower():find(rule:get("exclude"):lower_pattern())
	log:trace('Matching by exclude "%s": %s' % { tostring(rule:get("exclude")), tostring(match_exclude) })
	return match_title and match_exclude
end

function filter_by_size(rule, item)
	local match_min_size, match_max_size = true, true
	if rule:get("minsize") or rule:get("maxsize") then
		local enclosure, size = next_tag(item, "enclosure")
		if enclosure then
			size = enclosure.attr and enclosure.attr.length
				and tonumber(enclosure.attr.length) / 1024 / 1024
			if size then log:trace("Size from enclosure length: %.2f" % size) end
		end
		if not size then
			local url = rss_item_url(item)
			if url and url:match("magnet:?") then size = magnet_size(url)
			elseif url then size = torrent_size(url) end
			if size then log:trace("Size from torrent/magnet parse: %.2f" % size) end
		end
		if not size then
			log:error("Failed to detect size of RSS item")	-- TODO: print item xml as string
			if rule:get("minsize") then match_min_size = false end
			if rule:get("maxsize") then match_max_size = false end
		else
			if rule:get("minsize") then match_min_size = size >= tonumber(rule:get("minsize")) end
			if rule:get("maxsize") then match_max_size = size <= tonumber(rule:get("maxsize")) end
		end
	end
	log:trace('Matching by min size ">= %s": %s' % { tostring(rule:get("minsize")), tostring(match_min_size) })
	log:trace('Matching by max size "<= %s": %s' % { tostring(rule:get("maxsize")), tostring(match_max_size) })
	return match_min_size and match_max_size
end

function add_to_rtorrent(rule, item, title)
	log:info('Matched RSS rule "%s" by title "%s", adding to rtorrent' % { rule:get("name"), title })
	local url = rss_item_url(item)
	if not url then
		log:error("Failed to detect link of RSS item") -- TODO: print item xml as string
	else
		log:debug("Link of matched item: %s" % url)
		local data, err, icon
		if url:match("magnet:?") then
			data, err = bencode.encode({ ["magnet-uri"] = url })
			if not data then
				return log:error('Failed to encode torrent with magnet uri "%s": %s' % { url, err })
			end
			local magnet, err = common.parse_magnet(url)
			if not magnet then
				return log:error('Failed to parse magnet uri "%s": %s', { url, err })
			end
			icon = common.tracker_icon(common.extract_urls(magnet))
		else
			data, err = common.download(url)
			if not data then
				return log:error('Failed to download torrent "%s": %s' % { url, err })
			end
			local torrent, err = bencode.decode(data)
			if not torrent then
				return log:error('Failed to parse torrent "%s": %s' % { url, err })
			end
			icon = common.tracker_icon(array({ url, unpack(common.extract_urls(array(torrent)):get()) }))
		end
		common.add_to_rtorrent(array()
			:set("data", nixio.bin.b64encode(data))
			:set("start", rule:get("autostart"))
			:set("directory", rule:get("destdir"))
			:set("tags", rule:get("tags"))
			:set("icon", icon)
			:set("url", not url:match("magnet:?") and url))
	end
end

function process_item(rules, feed, item)
	local title = next_tag(item, "title")[1]
	log:debug("Title: %s " % title)
	for _, rule in rules:pairs() do
		log:trace("Rule: %s" % rule:get("name"))
		if filter_by_feed(rule, feed)
		and filter_by_title(rule, title)
		and filter_by_size(rule, item) then
			add_to_rtorrent(rule, item, title)
		end
	end
end

--[[ M A I N ]]--
if #arg == 0 then
	io.stderr:write("Usage:\n  %s [options]\n\nOptions:\n" % arg[0]
		.. "  -l, --level <TRACE|DEBUG|INFO|WARN|ERROR|FATAL>   Log level\n"
		.. "  -o, --output <target>                             Log file. Default: /dev/tty\n"
		.. "  -u, --uci                                         Read log level and log file from UCI\n")
	os.exit(1)
end

local level, target, i = "INFO", "/dev/tty", 1
while i <= #arg do
	if arg[i] == "-l" or arg[i] == "--level" then level, i = arg[i + 1], i + 1
	elseif arg[i] == "-o" or arg[i] == "--output" then target, i = arg[i + 1], i + 1
	elseif arg[i] == "-u" or arg[i] == "--uci" then
		level = uci:get("rtorrent", "logging", "rss_loglevel") or "OFF"
		target = uci:get("rtorrent", "logging", "rss_logfile") or "/dev/null"
	else
		io.stderr:write("Error: invalid option: %s\n" % arg[i])
		os.exit(1)
	end
	i = i + 1
end
log = logger(level, target)

local rules = rss_rules()
for _, feed in rss_feeds():pairs() do
	log:debug('Processing RSS feed: %s' % feed:get("name"))
	local lasthash, lastupdate = 0, 0
	if feed:get("lastupdate") then
		lasthash, lastupdate = unpack(array(feed:get("lastupdate"):split("@"))
			:map(function(value) return tonumber(value) end):get())
	end
	local rss = fetch_feed(feed:get("url"))
	if rss then
		local channel = next_tag(rss, "channel")
		local item, index = prev_tag(channel, "item")
		while item do
			local pubdate = date.to_unix(fix_date(next_tag(item, "pubDate")[1]))
			if pubdate >= lastupdate then
				local hash = math.abs(nixio.bin.crc32(next_tag(item, "title")[1]))
				if hash ~= lasthash then
					process_item(rules, feed, item)
					lasthash, lastupdate = hash, pubdate
					uci:set("rtorrent", feed:get(".name"), "lastupdate", hash .. "@" .. pubdate)
					uci:save("rtorrent")
					uci:commit("rtorrent")
				end
			end
			item, index = prev_tag(channel, "item", index - 1)
		end
	end
end
