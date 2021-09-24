-- Copyright 2014-2021 Sandor Balazsi <sandor.balazsi@gmail.com>
-- Licensed to the public under the GNU General Public License.

local rtorrent = require "rtorrent"
local common = require "luci.model.cbi.rtorrent.common"
local array = require "luci.model.cbi.rtorrent.array"
local build_url = require "luci.dispatcher".build_url

local throttle = array(rtorrent.batchcall("throttle.", "",
	"global_down.max_rate", "global_up.max_rate", "max_downloads.global", "max_uploads.global",
	"max_downloads", "max_uploads", "min_peers.normal", "max_peers.normal",
	"min_peers.seed", "max_peers.seed"))
local trackers = array(rtorrent.batchcall("trackers.", "", "numwant", "use_udp"))
local network = array(rtorrent.batchcall("network.", "",
	"http.max_open", "max_open_files", "max_open_sockets", "xmlrpc.size_limit"))

local form, bandwidth_limits, download_limit, upload_limit
local global_limits, max_downloads_global, max_uploads_global
local torrent_limits, max_downloads, max_uploads, min_peers, max_peers, min_seeds, max_seeds, peers_numwant
local network_limits, max_http_requests, max_open_files, max_open_sockets, max_xmlrpc_size

form = SimpleForm("rtorrent", "rTorrent Settings",
	"The below settings are change the running rTorrent instance only!<br />"
	.. "If you want to make it permanent, please change them in "
	.. "the <code>/root/.rtorrent.rc</code> config file.")
form.handle = function(self, state, data)
	if state == FORM_VALID then luci.http.redirect(nixio.getenv("REQUEST_URI")) end
	return true
end

bandwidth_limits = form:section(SimpleSection, "Bandwidth limits")

download_limit = bandwidth_limits:option(Value, "global_down_max_rate_kb", "Download limit (KiB/sec)",
	"Global download rate (0: unlimited).<br />Related <i>.rtorrent.rc</i> config line: "
	.. "<code>throttle.global_down.max_rate.set_kb</code>.")
download_limit.template = "rtorrent/value"
download_limit.rmempty = false
download_limit.default = throttle:get("global_down_max_rate") / 1024
download_limit.datatype = "uinteger"
download_limit.write = function(self, section, value)
	if value ~= tostring(download_limit.default) then
		rtorrent.call("throttle.global_down.max_rate.set_kb", "", value)
	end
end

upload_limit = bandwidth_limits:option(Value, "global_up_max_rate_kb", "Upload limit (KiB/sec)",
	"Global upload rate (0: unlimited).<br />Related <i>.rtorrent.rc</i> config line: "
	.. "<code>throttle.global_up.max_rate.set_kb</code>.")
upload_limit.template = "rtorrent/value"
upload_limit.rmempty = false
upload_limit.default = throttle:get("global_up_max_rate") / 1024
upload_limit.datatype = "uinteger"
upload_limit.write = function(self, section, value)
	if value ~= tostring(upload_limit.default) then
		rtorrent.call("throttle.global_up.max_rate.set_kb", "", value)
	end
end

global_limits = form:section(SimpleSection, "Global limits")

max_downloads_global = global_limits:option(Value, "max_downloads_global", "Download slots",
	"Maximum number of simultaneous downloads (0: unlimited).<br />Related <i>.rtorrent.rc</i> config line: "
	.. "<code>throttle.max_downloads.global.set</code>.")
max_downloads_global.rmempty = false
max_downloads_global.default = throttle:get("max_downloads_global")
max_downloads_global.datatype = "uinteger"
max_downloads_global.write = function(self, section, value)
	if value ~= tostring(max_downloads_global.default) then
		rtorrent.call("throttle.max_downloads.global.set", "", value)
	end
end

max_uploads_global = global_limits:option(Value, "max_uploads_global", "Upload slots",
	"Maximum number of simultaneous uploads (0: unlimited).<br />Related <i>.rtorrent.rc</i> config line: "
	.. "<code>throttle.max_uploads.global.set</code>.")
max_uploads_global.rmempty = false
max_uploads_global.default = throttle:get("max_uploads_global")
max_uploads_global.datatype = "uinteger"
max_uploads_global.write = function(self, section, value)
	if value ~= tostring(max_uploads_global.default) then
		rtorrent.call("throttle.max_uploads.global.set", "", value)
	end
end

torrent_limits = form:section(SimpleSection, "Torrent limits")

max_downloads = torrent_limits:option(Value, "max_downloads", "Maximum downloads",
	"Maximum number of simultanious downloads per torrent (0: unlimited).<br />"
	.. "Related <i>.rtorrent.rc</i> config line: <code>throttle.max_downloads.set</code>.")
max_downloads.rmempty = false
max_downloads.default = throttle:get("max_downloads")
max_downloads.datatype = "uinteger"
max_downloads.write = function(self, section, value)
	if value ~= tostring(max_downloads.default) then
		rtorrent.call("throttle.max_downloads.set", "", value)
	end
end

max_uploads = torrent_limits:option(Value, "max_uploads", "Maximum uploads",
	"Maximum number of simultanious uploads per torrent (0: unlimited).<br />"
	.. "Related <i>.rtorrent.rc</i> config line: <code>throttle.max_uploads.set</code>.")
max_uploads.rmempty = false
max_uploads.default = throttle:get("max_uploads")
max_uploads.datatype = "uinteger"
max_uploads.write = function(self, section, value)
	if value ~= tostring(max_uploads.default) then
		rtorrent.call("throttle.max_uploads.set", "", value)
	end
end

min_peers = torrent_limits:option(Value, "min_peers", "Minimum peers",
	"Minimum number of peers to connect to per torrent.<br />"
	.. "Related <i>.rtorrent.rc</i> config line: <code>throttle.min_peers.normal.set</code>.")
min_peers.rmempty = false
min_peers.default = throttle:get("min_peers_normal")
min_peers.datatype = "uinteger"
min_peers.write = function(self, section, value)
	if value ~= tostring(min_peers.default) then
		rtorrent.call("throttle.min_peers.normal.set", "", value)
	end
end

max_peers = torrent_limits:option(Value, "max_peers", "Maximum peers",
	"Maximum number of peers to connect to per torrent.<br />"
	.. "Related <i>.rtorrent.rc</i> config line: <code>throttle.max_peers.normal.set</code>.")
max_peers.rmempty = false
max_peers.default = throttle:get("max_peers_normal")
max_peers.datatype = "uinteger"
max_peers.write = function(self, section, value)
	if value ~= tostring(max_peers.default) then
		rtorrent.call("throttle.max_peers.normal.set", "", value)
	end
end

min_seeds = torrent_limits:option(Value, "min_seeds", "Minimum seeds",
	"Minimum number of seeds for completed torrents (-1: same as peers).<br />"
	.. "Related <i>.rtorrent.rc</i> config line: <code>throttle.min_peers.seed.set</code>.")
min_seeds.rmempty = false
min_seeds.default = throttle:get("min_peers_seed")
min_seeds.datatype = "integer"
min_seeds.write = function(self, section, value)
	if value ~= tostring(min_seeds.default) then
		rtorrent.call("throttle.min_peers.seed.set", "", value)
	end
end

max_seeds = torrent_limits:option(Value, "max_seeds", "Maximum seeds",
	"Maximum number of seeds for completed torrents (-1: same as peers).<br />"
	.. "Related <i>.rtorrent.rc</i> config line: <code>throttle.max_peers.seed.set</code>.")
max_seeds.rmempty = false
max_seeds.default = throttle:get("max_peers_seed")
max_seeds.datatype = "integer"
max_seeds.write = function(self, section, value)
	if value ~= tostring(max_seeds.default) then
		rtorrent.call("throttle.max_peers.seed.set", "", value)
	end
end

peers_numwant = torrent_limits:option(Value, "peers_numwant", "Wished peers",
	"Wished number of peers (-1: disable feature).<br />"
	.. "Related <i>.rtorrent.rc</i> config line: <code>trackers.numwant.set</code>.")
peers_numwant.rmempty = false
peers_numwant.default = trackers:get("numwant")
peers_numwant.datatype = "integer"
peers_numwant.write = function(self, section, value)
	if value ~= tostring(peers_numwant.default) then
		rtorrent.call("trackers.numwant.set", "", value)
	end
end

network_limits = form:section(SimpleSection, "Network limits")

max_http_requests = network_limits:option(Value, "max_http_requests", "Maximum http requests",
	"Maximum number of simultaneous HTTP request (used by announce / scrape requests).<br />"
	.. "Related <i>.rtorrent.rc</i> config line: <code>network.http.max_open.set</code>.")
max_http_requests.rmempty = false
max_http_requests.default = network:get("http_max_open")
max_http_requests.datatype = "uinteger"
max_http_requests.write = function(self, section, value)
	if value ~= tostring(max_http_requests.default) then
		rtorrent.call("network.http.max_open.set", "", value)
	end
end

max_open_files = network_limits:option(Value, "max_open_files", "Maximum open files",
	"Maximum number of open files rTorrent can keep open.<br />"
	.. "Related <i>.rtorrent.rc</i> config line: <code>network.max_open_files.set</code>.")
max_open_files.rmempty = false
max_open_files.default = network:get("max_open_files")
max_open_files.datatype = "uinteger"
max_open_files.write = function(self, section, value)
	if value ~= tostring(max_open_files.default) then
		rtorrent.call("network.max_open_files.set", "", value)
	end
end

max_open_sockets = network_limits:option(Value, "max_open_sockets", "Maximum open sockets",
	"Maximum number of connections rTorrent can accept / make (sockets).<br />"
	.. "Related <i>.rtorrent.rc</i> config line: <code>network.max_open_sockets.set</code>.")
max_open_sockets.rmempty = false
max_open_sockets.default = network:get("max_open_sockets")
max_open_sockets.datatype = "uinteger"
max_open_sockets.write = function(self, section, value)
	if value ~= tostring(max_open_sockets.default) then
		rtorrent.call("network.max_open_sockets.set", "", value)
	end
end

max_xmlrpc_size = network_limits:option(Value, "max_xmlrpc_size", "Maximum XML-RPC size",
	"Maximum size of any XML-RPC requests in bytes.<br />"
	.. "Human-readable forms such as 2M are also allowed (for 2 MiB, i.e. 2097152 bytes).<br />"
	.. "Related <i>.rtorrent.rc</i> config line: <code>network.xmlrpc.size_limit.set</code>.")
max_xmlrpc_size.rmempty = false
max_xmlrpc_size.default = network:get("xmlrpc_size_limit")
max_xmlrpc_size.write = function(self, section, value)
	if value ~= tostring(max_xmlrpc_size.default) then
		rtorrent.call("network.xmlrpc.size_limit.set", "", value)
	end
end

return form
