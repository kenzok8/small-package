-- Copyright 2014-2021 Sandor Balazsi <sandor.balazsi@gmail.com>
-- Licensed to the public under the GNU General Public License.

local nixio = require "nixio"
local rtorrent = require "rtorrent"
local build_url = require "luci.dispatcher".build_url
local common = require "luci.model.cbi.rtorrent.common"
local array = require "luci.model.cbi.rtorrent.array"
require "luci.model.cbi.rtorrent.string"

luci.dispatcher.context.requestpath = array(luci.dispatcher.context.requestpath):map(string.urlencode):get()

local args = array():append(unpack(arg))
local compute, format, hash, sort, page, path = {}, {},
	table.remove(arg, 1), table.remove(arg, 1), table.remove(arg), array(arg)
common.set_cookie("rtorrent-files", array():append(hash, sort):append(unpack(path:get())):append(page):get())

sort = sort or "name-asc"
page = page and tonumber(page) or 1
local sort_column, sort_order = unpack(sort:split("-"))

function filter_by_folders(file, index, files, folders)
	file:set("name", file:get("path_components"):get(path:size() + 1))
	if file:get("path_components"):size() > path:size() + 1 then
		file:set("type", "folder")
		if not folders:keys():contains(file:get("name")) then
			folders:set(file:get("name"), index)
			return true
		else
			files:get(folders:get(file:get("name")))
				:increment("size_bytes", file:get("size_bytes"))
				:increment("size_chunks", file:get("size_chunks"))
				:increment("completed_chunks", file:get("completed_chunks"))
			if file:get("priority") ~= files:get(folders:get(file:get("name"))):get("priority") then
				files:get(folders:get(file:get("name"))):set("priority", math.huge)
			end
			return false
		end
	else
		file:set("type", "file")
		return true
	end
end

function sort_by_folders(lhs, rhs, comparator, order)
	if lhs:get("type") == "folder" and rhs:get("type") ~= "folder" then
		return true
	elseif lhs:get("type") ~= "folder" and rhs:get("type") == "folder" then
		return false
	else
		if order == "asc" then
			return lhs:get(comparator) < rhs:get(comparator)
		elseif order == "desc" then
			return lhs:get(comparator) > rhs:get(comparator)
		else assert(false, "invalid sort order: " .. tostring(order)) end
	end
end

function compute_navigate_up()
	if path:empty() then return nil end
	return format_values(array()
		:set("type", "up")
		:set("icon", compute.icon)
		:set("name", ".."))
end

function compute_total(file, index, files, total)
	total:increment("count")
		:increment("size", file:get("size"))
		:increment("size_chunks", file:get("size_chunks"))
		:increment("completed_chunks", file:get("completed_chunks"))
		:increment("files", file:get("type") == "file" and 1 or 0)
		:increment("folders", file:get("type") == "folder" and 1 or 0)
	total:get("priority"):insert(file:get("priority"))
	if files:last(index) then
		format_values(total:set(".total_row", true)
			:set("type", "total")
			:set("name", "TOTAL: %d pcs." % total:get("count"))
			:set("done", compute.done)
			:set("priority", total:get("priority"):unique():size() == 1
				and total:get("priority"):get(1) or math.huge))
	end
end

function compute_values(file, index, files, ...)
	for _, key in ipairs({ "index", "icon", "size", "done" }) do
		file:set(key, compute[key], index, files, ...)
	end
end

function compute.icon(key, file)
	local icons_path = "/luci-static/resources/icons/filetypes"
	if file:get("type") == "up" then return "%s/%s.png" % { icons_path, "up" } end
	if file:get("type") == "folder" then return "%s/%s.png" % { icons_path, "dir" } end
	local ext = file:get("path"):match("%.([^%.]+)$")
	if ext and nixio.fs.stat("/www%s/%s.png" % { icons_path, ext:lower() }, "type") then
		return "%s/%s.png" % { icons_path, ext:lower() }
	else return "%s/%s.png" % { icons_path, "file" } end
end

function compute.size(key, file) return file:get("size_bytes") end

function compute.done(key, file)
	return 100.0 * file:get("completed_chunks") / file:get("size_chunks")
end

function format_values(file, index, files, ...)
	for key, value in file:pairs() do
		file:set(key, format[key]
		and format[key](value, key, file, index, files, ...) or value)
	end
	return file
end

function format.icon(value) return '<img src="%s"/>' % value end
function format.priority(value) return value == math.huge and "mixed" or tostring(value) end

function format.name(value, key, file)
	if file:get("type") == "total"
	or file:get("type") == "file" and file:get("completed_chunks") ~= file:get("size_chunks") then
		return value
	end
	local title, href = "", array():append("admin", "rtorrent")
	if file:get("type") == "up" then href
		:append("torrent", "files", hash, sort)
		:append(unpack(array(path:get()):remove(path:size()):get())):insert("1")
		title = ' title="Navigate up one directory level"'
	elseif file:get("type") == "folder" then href
		:append("torrent", "files", hash, sort)
		:append(unpack(array(path:get()):insert(value):get())):insert("1")
	elseif file:get("type") == "file" then href
		:append("download", hash)
		:append(unpack(array(path:get()):insert(value):get()))
	end
	return '<a href="%s"%s>%s</a>' % { build_url(unpack(href:map(string.urlencode):get())), title, value }
end

function format.size(value, key, file)
	return '<div title="%s B">%s</div>' % { value, common.human_size(value) }
end

function format.done(value, key, file)
	return "%.1f%%" % value
end

local folders, total = array(), array():set("priority", array()):set("count", 0)
local torrent = array(rtorrent.batchcall("d.", hash, "name", "is_multi_file"))
local files = array(rtorrent.multicall("f.", hash, "/" .. array(path:get()):insert(""):join("/") .. "*",
	"path", "path_components", "frozen_path", "size_bytes",
	"size_chunks", "completed_chunks", "priority"))
	:filter(filter_by_folders, folders)
	:foreach(compute_values, torrent)
	:foreach(compute_total, total)
	:sort(sort_by_folders, sort_column, sort_order)
	:limit(10, (page - 1) * 10)
	:foreach(format_values)
	:insert(1, compute_navigate_up)
	:insert(total:get("count") > 1 and total or nil)

local form, breadcrumb, list, icon, name, size, done, prio

_G.redirect = build_url("admin", "rtorrent", "main", unpack(common.get_cookie("rtorrent-main", {})))
form = SimpleForm("rtorrent", torrent:get("name"))
form.template = "rtorrent/simpleform"
form.all_tabs = array():append("info", "files", "trackers", "peers", "chunks"):get()
form.tab_url_postfix = function(tab)
	local filters = (tab == "files") and args or array(common.get_cookie("rtorrent-" .. tab, {}))
	return filters:get(1) == hash and filters:join("/") or hash
end
form.handle = function(self, state, data)
	if state == FORM_VALID then luci.http.redirect(nixio.getenv("REQUEST_URI")) end
	return true
end
if torrent:get("is_multi_file") == 1 and total:get("size_chunks") == total:get("completed_chunks")
and total:get("folders") > 0 or total:get("files") > 1 then
	form.cancel = "Download this folder"
	form.on_cancel = function()
		luci.http.redirect(build_url(unpack(array():append("admin", "rtorrent", "download", hash)
			:append(unpack(path:get())):map(string.urlencode):get())))
	end
end

if not path:empty() then
	breadcrumb = form:field(DummyValue, "breadcrumb")
	breadcrumb.rawhtml = true
	breadcrumb.value = array(path:get()):insert(1, ""):map(function(subpath, index, subpaths)
		return '<a href="%s">%s</a>' % {
			build_url("admin", "rtorrent", "torrent", "files", hash, sort,
				subpaths:limit(index):filter(string.not_blank):map(string.urlencode):join("/"), "1"),
			subpath:blank() and '<img src="/luci-static/resources/icons/home.png"/>' or subpath
		}
	end):join(" / ")
end

list = form:section(Table, files:get())
list.template = "rtorrent/tblsection"
list.name = "rtorrent-files"
list.pages = common.pagination(total:get("count") or files:size(), tonumber(page), common.pagination_link,
	build_url("admin", "rtorrent", "torrent", "files", hash, sort, path:map(string.urlencode):join("/"))):join()
list.column = function(self, class, option, title, tooltip, sort_by)
	return self:option(class, option, '<a href="%s" title="%s"%s>%s</a>' % {
		build_url("admin", "rtorrent", "torrent", "files",
			hash, sort_by, path:map(string.urlencode):join("/"), "1"),
		tooltip, sort == sort_by and ' class="active"' or "", title
	})
end

icon = list:option(DummyValue, "icon")
icon.rawhtml = true
icon.width = "1%"
icon.classes = { "nowrap" }

name = list:column(DummyValue, "name", "Name", "Sort by name", "name-asc")
name.rawhtml = true
name.classes = { "wrap" }

size = list:column(DummyValue, "size", "Size", "Sort by size", "size-desc")
size.rawhtml = true
size.width = "1%"
size.classes = { "nowrap", "center" }

done = list:column(DummyValue, "done", "Done", "Sort by download done percent", "done-desc")
done.rawhtml = true
done.width = "10%"
done.classes = { "nowrap", "center" }

local all_files
prio = list:column(ListValue, "priority", "Priority", "Sort by priority", "priority-desc")
prio.classes = { "nowrap", "center" }
prio.width = "15%"
prio:value("0", "off")
prio:value("1", "normal")
prio:value("2", "high")
prio:value("", "hidden")
prio:value("mixed", "mixed")
prio.write = function(self, section, value)
	if files:get(section):get("type") == "total" then return end
	if not all_files then
		all_files = array(rtorrent.multicall("f.", hash, "", "path_components", "priority"))
	end
	local indices = array()
	all_files:foreach(function(file, index)
		if files:get(section):get("path_components"):limit(path:size() + 1):join("/")
			== file:get("path_components"):limit(path:size() + 1):join("/")
		and file:get("priority") ~= tonumber(value) then
			indices:insert(index - 1)
		end
	end)
	for _, index in indices:pairs() do
		rtorrent.call("f.priority.set", hash .. ":f" .. index, tonumber(value))
		rtorrent.call("d.update_priorities", hash)
	end
end

return form
