-- Copyright 2014-2021 Sandor Balazsi <sandor.balazsi@gmail.com>
-- Licensed to the public under the GNU General Public License.

local socket = require "socket"
local url = require "socket.url"
local http = require "socket.http"
local https = require "ssl.https"
local ltn12 = require "ltn12"
local nixio = require "nixio"
local util = require "luci.util"
local lhttp = require "luci.http"
local uci = require "luci.model.uci".cursor()
local build_url = require "luci.dispatcher".build_url
local datatypes = require "luci.cbi.datatypes"
local xmlrpc = require "xmlrpc"
local rtorrent = require "rtorrent"
local array = require "luci.model.cbi.rtorrent.array"
require "luci.model.cbi.rtorrent.string"

local string, table, os, math, unpack = string, table, os, math, unpack
local type, ipairs, tostring, tonumber = type, ipairs, tostring, tonumber
local getmetatable = getmetatable

module "luci.model.cbi.rtorrent.common"

function uci_sections(config, stype, name)
	local sections = array()
	uci:foreach(config, stype, function(section)
		if not name or section[".name"] == name then
			sections:insert(section)
		end
	end)
	return name and sections:get(1) or sections
end

function uci_list_add(config, stype, name, option, value)
	if not uci:get(config, name) then
		uci:set(config, name, stype)
		uci:commit(config)
	end
	local current_values = array(uci:get(config, name, option))
	uci:set(config, name, option, current_values:insert(value):get())
	uci:commit(config)
end

function human_size(bytes)
	local symbol = {[0]="B", "KiB", "MiB", "GiB", "TiB", "PiB", "EiB", "ZiB", "YiB"}
	local exp = bytes > 0 and math.floor(math.log(bytes) / math.log(1024)) or 0
	local value = bytes / math.pow(1024, exp)
	local acc = bytes > 0 and 2 - math.floor(math.log10(value)) or 2
	if acc < 0 then acc = 0 end
	return string.format("%." .. acc .. "f " .. symbol[exp], value)
end

function human_time(sec)
	local t = os.date("!*t", sec)
	if t["day"] > 25 then return "&#8734;"
	elseif t["day"] > 1 then
		return string.format("%dd<br />%dh %dm", t["day"] - 1, t["hour"], t["min"])
	elseif t["hour"] > 0 then
		return string.format("%dh<br />%dm %ds", t["hour"], t["min"], t["sec"])
	elseif t["min"] > 0 then
		return string.format("%dm %ds", t["min"], t["sec"])
	else return string.format("%ds", t["sec"]) end
end

function parse_magnet(uri)
	if not uri:starts("magnet:?") then return nil, "Not a valid magnet URI!" end
	local magnet = array()
	for key, value in uri:sub(9):gmatch("([^&=]+)=([^&=]+)") do
		key = key:gsub("%.%d+$", "")
		if not magnet:get(key) then magnet:set(key, array()) end
		magnet:get(key):insert(value:urldecode())
	end
	if not magnet:keys():contains("xt")
	or not magnet:get("xt"):get(1):starts("urn:btih:") then
		return nil, "Magnet URI's BitTorrent info hash URN missing!"
	end
	return magnet
end

function get_domain(url, sub_domain)
	local domain = url:match("^%w+://([^/:]+)") or ""
	return sub_domain == true or datatypes.ipaddr(domain) and domain or domain:match("(%w+%.%w+)$") or ""
end

function tracker_icon(urls)
	for _, domain in urls:map(get_domain):filter(string.not_blank):unique():pairs() do
		local favicon = "http://" .. domain .. "/favicon.ico"
		if array(uci:get("rtorrent", "icon", "has")):contains(domain) then
			return favicon
		elseif not array(uci:get("rtorrent", "icon", "not")):contains(domain) then
			local icon, err, headers = download(favicon, 2)
			if icon and headers:get("content-type"):starts("image/") and #icon > 0 then
				uci_list_add("rtorrent", "frontend", "icon", "has", domain)
				return favicon
			else
				uci_list_add("rtorrent", "frontend", "icon", "not", domain)
			end
		end
	end
	return "/luci-static/resources/icons/unknown_tracker.svg"
end

function extract_urls(data)
	local urls = array()
	data:traverse(function(value)
		if type(value) == "string" and value:match("^%w+://%w+%.%w+") then
			urls:insert(value)
		end
	end)
	return urls:unique()
end

function add_to_rtorrent(torrent)
	local params = array()
	params:insert(torrent:get("start") == "1" and "load.raw_start" or "load.raw")
	params:insert("") -- target
	params:insert(xmlrpc.newTypedValue(torrent:get("data"), "base64"))
	params:insert('d.directory.set="%s"' % torrent:get("directory"))
	if torrent:get("tags") then params:insert('d.custom1.set="%s"' % torrent:get("tags")) end
	if torrent:get("icon") then params:insert('d.custom.set=icon, "%s"' % torrent:get("icon")) end
	if torrent:get("url") then params:insert('d.custom.set=url, "%s"' % torrent:get("url"):urlencode()) end
	rtorrent.call(unpack(params:get()))
end

function download(url, timeout)
	local proto = url:starts("https://") and https or http
	proto.TIMEOUT = timeout or 5
	local response_chunks = {}
	local request_headers = {
		["Referer"] = "https://www.google.com",
		["User-Agent"] = "unknown"
	}
	local cookie_section = uci_sections("rtorrent", "cookies")
		:filter(function(section) return get_domain(url, true) == section.domain end)
		:first()
	if cookie_section then request_headers["Cookie"] = cookie_section.cookie end
	local body, code, headers, status = proto.request({
		url = url,
		method = "GET",
		headers = request_headers,
		redirect = (proto.PORT == 80) and true or nil,
		sink = ltn12.sink.table(response_chunks)
	})
	if not body then return nil, code, array(headers), code, status end
	if code == 301 or code == 302 then return download(headers["location"])
	elseif code == 200 then
		return table.concat(response_chunks), nil, array(headers), code, status
	else return nil, status, array(headers), code, status end
end

function pagination_link(page, current_page, last_page, root_path)
	local active = (page == current_page) and ' class="active"' or ""
	local text
	if page == "previous" then text, page = "&lt;", math.max(current_page - 1, 1)
	elseif page == "next" then text, page = "&gt;", math.min(current_page + 1, last_page)
	elseif page == "left-ellipsis" then text, page = "&hellip;", math.max(current_page - 10, 1)
	elseif page == "right-ellipsis" then text, page = "&hellip;", math.min(current_page + 10, last_page)
	else text = tostring(page) end
	return '<a href="%s/%s"%s>%s</a>' % { root_path, page, active, text }
end

function pagination(count, current_page, button_builder, ...)
	local pages = array()
	local last_page = math.floor(count / 10) + (count % 10 == 0 and 0 or 1)
	if last_page < 2 then return pages end
	current_page = current_page > last_page and last_page or current_page
	pages:insert(button_builder("previous", current_page, last_page, ...))
	pages:insert(button_builder(1, current_page, last_page, ...))
	pages:insert(last_page > 9 and current_page > 7
		and button_builder("left-ellipsis", current_page, last_page, ...)
		or button_builder(2, current_page, last_page, ...))
	for column = 3, 9 do
		if last_page >= column then
			if last_page < 10 or (column < 8 and current_page < 8) then
				pages:insert(button_builder(column, current_page, last_page, ...))
			elseif column == 8 then
				if current_page < 8 or (last_page > 14 and current_page < last_page - 6) then
					pages:insert(button_builder("right-ellipsis", current_page, last_page, ...))
				else pages:insert(button_builder(last_page - 1, current_page, last_page, ...)) end
			elseif column == 9 then
				pages:insert(button_builder(last_page, current_page, last_page, ...))
			elseif current_page > last_page - 7 then
				pages:insert(button_builder(last_page + column - 9, current_page, last_page, ...))
			else pages:insert(button_builder(current_page + column - 5, current_page, last_page, ...)) end
		end
	end
	pages:insert(button_builder("next", current_page, last_page, ...))
	return pages
end

function system_uptime()
	return nixio.fs.readfile("/proc/uptime"):split()[1]
end

function process_cmdline(pid)
	return array(nixio.fs.readfile("/proc/%d/cmdline" % pid):split("%z"))
end

function process_env(pid)
	local env = array()
	for _, entry in ipairs(nixio.fs.readfile("/proc/%d/environ" % pid):split("%z")) do
		env:set(unpack(entry:split("=", 2)))
	end
	return env
end

-- https://man7.org/linux/man-pages/man5/proc.5.html
function process_stat(pid)
	local stat = nixio.fs.readfile("/proc/%d/stat" % pid)
	local fields, end_index, value = array()
	_, end_index, value = stat:find("(%d+)"); fields:set("pid", tonumber(value))
	_, end_index, fields.table["comm"] = stat:find("%(([^)]+)%)", end_index + 2)
	_, end_index, fields.table["state"] = stat:find("(%a)", end_index + 2)
	for _, key in ipairs({ "ppid", "pgrp", "session", "tty_nr", "tpgid", "flags", "minflt", "cminflt",
			"majflt", "cmajflt", "utime", "stime", "cutime", "cstime", "priority", "nice",
			"num_threads", "itrealvalue", "starttime", "vsize", "rss", "rsslim", "startcode",
			"endcode", "startstack", "kstkesp", "kstkeip", "signal", "blocked", "sigignore",
			"sigcatch", "wchan", "nswap", "cnswap", "exit_signal", "processor", "rt_priority",
			"policy", "delayacct_blkio_ticks", "guest_time", "cguest_time", "start_data",
			"end_data", "start_brk", "arg_start", "arg_end", "env_start", "env_end", "exit_code" }) do
		_, end_index, value = stat:find("([-%d]+)", end_index + 2)
		fields:set(key, tonumber(value))
	end
	return fields
end

function process_start(pid)
	local clk_tck = 100	-- TODO: find out value from sysconf(_SC_CLK_TCK)
	local process_start_time = process_stat(pid):get("starttime") / clk_tck
	local current_time = socket.gettime()
	return math.floor(current_time - system_uptime() + process_start_time)
end

function rtorrent_config(rtorrent_pid)
	rtorrent_pid = rtorrent_pid or rtorrent.call("system.pid")
	local rtorrent_config_file = process_env(rtorrent_pid):get("HOME") .. "/.rtorrent.rc"
	for _, arg in process_cmdline(rtorrent_pid):pairs() do
		if arg:starts("import=") then rtorrent_config_file = arg:sub(8) end
	end
	return array(nixio.fs.stat(rtorrent_config_file, "type") == "reg"
		and nixio.fs.readfile(rtorrent_config_file):split("\n") or {})
end

function rtorrent_schedule_parse(schedule)
	local time = schedule:split(":")
	if #time == 1 then
		return time[1]
	elseif #time == 2 then
		return time[1] * 60 + time[2]
	elseif #time == 3 then
		return time[1] * 60 * 60 + time[2] * 60 + time[3]
	elseif #time == 4 then
		return  time[1] * 24 * 60 * 60 + time[2] * 60 * 60 + time[3] * 60 + time[4]
	end
end

function rtorrent_schedule_start(rtorrent_start, second)
	local time, now = os.date("*t", rtorrent_start), socket.gettime()
	local start = rtorrent_start - time.hour * 60 * 60 - time.min * 60 - time.sec + second
	if now - rtorrent_start < 24 * 60 * 60 and start < rtorrent_start then start = start + 24 * 60 * 60 end
	return start
end

function rss_downloader_status()
	local rtorrent_pid, schedule = rtorrent.call("system.pid")
	for _, line in rtorrent_config(rtorrent_pid):pairs() do
		if line:match("^%s*schedule.*execute.*/usr/lib/lua/rss_downloader.lua") then
			schedule = line:split(",")
		end
	end
	if schedule then
		local rtorrent_start = process_start(rtorrent_pid)
		local start, start_text
		if schedule[2]:match(":") then
			start = rtorrent_schedule_start(rtorrent_start, rtorrent_schedule_parse(schedule[2]))
			start_text = "<i>" .. schedule[2] .. "</i> start time"
		else
			start = rtorrent_start + schedule[2]
			start_text = "<i>" .. schedule[2] .. "</i> seconds initial delay"
		end
		local interval = rtorrent_schedule_parse(schedule[3])
		local interval_text = "<i>" .. schedule[3] .. "</i>" .. (schedule[3]:match(":") and "" or " seconds")
		return "RSS Downloader is scheduled by rTorrent with %s and %s interval.<br />"
			% { start_text, interval_text }
			.. 'The next fetch of RSS feed(s) will be at <span id="rss-next-fetch"></span>.'
			.. '<script type="text/javascript">updateNextRunTime("rss-next-fetch", %d, %d)</script>'
			% { start, interval }
	else
		return '<span class="orange">Warning!</span> RSS Downloader not scheduled by rTorrent! '
			.. 'Please add a <a target="_blank" href="'
			.. "https://rtorrent-docs.readthedocs.io/en/latest/cmd-ref.html#scheduling-commands"
			.. '">schedule2</a> line to your rTorrent config file (<i>/root/.rtorrent.rc</i>).<br />'
			.. "For example, to trigger it every <i>300</i> seconds, "
			.. "with an initial delay of <i>60</i> seconds after rTorrent startup:<br /><code>schedule2 = "
			.. "rss_downloader, 60, 300, ((execute.throw, /usr/lib/lua/rss_downloader.lua, --uci))</code>"
	end
end

function set_cookie(name, data, attributes)
	attributes = attributes or ""
	lhttp.header("Set-Cookie", "%s=%s; Path=%s; SameSite=Strict%s" % {
		name, data and util.serialize_data(data):urlencode() or "", build_url("admin", "rtorrent"), attributes
	})
end

function get_cookie(name, default)
	local cookie = lhttp.getcookie(name)
	return cookie and util.restore_data(cookie) or default
end

function remove_cookie(name)
	set_cookie(name, nil, "; Max-Age=0")
end
