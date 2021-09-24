-- Copyright 2014-2021 Sandor Balazsi <sandor.balazsi@gmail.com>
-- Licensed to the public under the GNU General Public License.

local nixio = require "nixio"
local rtorrent = require "rtorrent"
local build_url = require "luci.dispatcher".build_url
local common = require "luci.model.cbi.rtorrent.common"
local array = require "luci.model.cbi.rtorrent.array"
require "luci.model.cbi.rtorrent.string"

local hash, page = unpack(arg)
common.set_cookie("rtorrent-chunks", { hash, page })

page = page and tonumber(page) or 1

local torrent = array(rtorrent.batchcall("d.", hash,
	"name", "bitfield", "chunks_seen", "size_chunks", "chunk_size", "completed_chunks", "wanted_chunks"))
local bitfield, chunks, line, group, pos = array(), array(), (page - 1) * 10 + 1, 1, 1
torrent:get("bitfield"):gsub("(%x%x)", function(hex) bitfield:insert(tonumber(hex, 16)) end)
torrent:get("chunks_seen"):sub((line - 1) * 200 + 1, (line + 9) * 200):gsub("%x(%x)", function(seen)
	if pos == 1 then
		if group == 1 then
			chunks:set(line, array():set("offset", "<b>%s</b>" % ((line - 1) * 100)))
		end
		chunks:get(line):set(group, "")
	end
	local chunk_index = (line - 1) * 100 + (group - 1) * 10 + pos - 1
	local chunk_status = bitfield:get(math.floor(chunk_index / 8) + 1)
	local chunk_mask = nixio.bit.lshift(1, 7 - chunk_index % 8)
	local chunk_done = nixio.bit.band(chunk_status, chunk_mask) == chunk_mask
	chunks:get(line):set(group, chunks:get(line):get(group)
		.. (chunk_done and '<span class="green">%s</span>' % seen or seen))
	pos = pos + 1
	if pos > 10 then pos, group = 1, group + 1 end
	if group > 10 then group, line = 1, line + 1 end
end)

local form, summary, list, offset
local chunks_count, chunk_size, completed_chunks, wanted_chunks, excluded_chunks, download_done

_G.redirect = build_url("admin", "rtorrent", "main", unpack(common.get_cookie("rtorrent-main", {})))
form = SimpleForm("rtorrent", torrent:get("name"))
form.template = "rtorrent/simpleform"
form.submit = false
form.reset = false
form.all_tabs = array():append("info", "files", "trackers", "peers", "chunks"):get()
form.tab_url_postfix = function(tab)
	local filters = (tab == "chunks") and array(arg) or array(common.get_cookie("rtorrent-" .. tab, {}))
	return filters:get(1) == hash and filters:join("/") or hash
end
form.handle = function(self, state, data)
	if state == FORM_VALID then luci.http.redirect(nixio.getenv("REQUEST_URI")) end
	return true
end

summary = form:section(Table, { [1] = {
	["chunks_count"] = tostring(torrent:get("size_chunks")),
	["chunk_size"] = common.human_size(torrent:get("chunk_size")),
	["completed_chunks"] = tostring(torrent:get("completed_chunks")),
	["wanted_chunks"] = tostring(torrent:get("wanted_chunks")),
	["excluded_chunks"] = tostring(torrent:get("size_chunks")
		- torrent:get("completed_chunks") - torrent:get("wanted_chunks")),
	["download_done"] = "%.2f%%" % math.min(100.0 * torrent:get("completed_chunks")
		/ (torrent:get("completed_chunks") + torrent:get("wanted_chunks")), 100)
} })
summary.template = "rtorrent/tblsection"
summary.name = "rtorrent-chunks-summary"

chunks_count = summary:option(DummyValue, "chunks_count", "Chunks count")
chunks_count.classes = { "center" }

chunk_size = summary:option(DummyValue, "chunk_size", "Chunk size")
chunk_size.classes = { "center" }

completed_chunks = summary:option(DummyValue, "completed_chunks", "Completed chunks")
completed_chunks.classes = { "center" }

wanted_chunks = summary:option(DummyValue, "wanted_chunks", "Wanted chunks")
wanted_chunks.classes = { "center" }

excluded_chunks = summary:option(DummyValue, "excluded_chunks",
	'<span title="Chunks from files that are prioritized as &quot;off&quot;">Excluded chunks</span>')
excluded_chunks.classes = { "center" }

download_done = summary:option(DummyValue, "download_done", "Download done")
download_done.classes = { "center" }

list = form:section(Table, chunks:get())
list.template = "rtorrent/tblsection"
list.name = "rtorrent-chunks"
list.pages = common.pagination(math.floor(torrent:get("chunks_seen"):len() / 200) + 1, page,
	common.pagination_link, build_url("admin", "rtorrent", "torrent", "chunks", hash)):join()

offset = list:option(DummyValue, "offset", "Offset")
offset.rawhtml = true
offset.width = "8%"
offset.classes = { "right" }

for group = 1, 10 do
	local column = list:option(DummyValue, group)
	column.rawhtml = true
	if group ~= 10 then column.width = "1%" end
end

return form
