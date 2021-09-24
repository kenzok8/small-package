-- Copyright 2014-2021 Sandor Balazsi <sandor.balazsi@gmail.com>
-- Licensed to the public under the GNU General Public License.

local dm = require "luci.model.cbi.rtorrent.download"

module("luci.controller.rtorrent", package.seeall)

function index()
	entry({ "admin", "rtorrent" },  firstchild(), "Torrent", 70)
	entry({ "admin", "rtorrent", "main" },
		form("rtorrent/main"), "List", 10).leaf = true
	entry({ "admin", "rtorrent", "add" },
		form("rtorrent/add", { autoapply = true }), "Add", 20)
	entry({ "admin", "rtorrent", "rss" }, arcombine(
		cbi("rtorrent/rss"), cbi("rtorrent/rss-rule")), "RSS Downloader", 30).leaf = true
	entry({ "admin", "rtorrent", "settings" },
		alias("admin", "rtorrent", "settings", "rtorrent"), "Settings", 40)

	-- torrent
	entry({ "admin", "rtorrent", "torrent", "info" },
		form("rtorrent/torrent/info"), "Info", 10).leaf = true
	entry({ "admin", "rtorrent", "torrent", "files" },
		form("rtorrent/torrent/files"), "Files", 20).leaf = true
	entry({ "admin", "rtorrent", "torrent", "trackers" },
		form("rtorrent/torrent/trackers"), "Trackers", 30).leaf = true
	entry({ "admin", "rtorrent", "torrent", "peers" },
		form("rtorrent/torrent/peers"), "Peers", 40).leaf = true
	entry({ "admin", "rtorrent", "torrent", "chunks" },
		form("rtorrent/torrent/chunks"), "Chunks", 50).leaf = true

	-- settings
	entry({ "admin", "rtorrent", "settings", "rtorrent" },
		form("rtorrent/settings/rtorrent"), "rTorrent", 10)
	entry({ "admin", "rtorrent", "settings", "frontend" },
		cbi("rtorrent/settings/frontend"), "rTorrent Frontend", 20)
	entry({ "admin", "rtorrent", "settings", "rss" },
		cbi("rtorrent/settings/rss"), "RSS Downloader", 30)

	-- download
	entry({ "admin", "rtorrent", "download" }, call("download")).leaf = true
end

function download()
	dm.download(unpack(luci.dispatcher.context.requestpath, 4))
end
