-- Copyright 2014-2021 Sandor Balazsi <sandor.balazsi@gmail.com>
-- Licensed to the public under the GNU General Public License.

local nixio = require "nixio"
local bencode = require "bencode"
local xmlrpc = require "xmlrpc"
local rtorrent = require "rtorrent"
local datatypes = require "luci.cbi.datatypes"
local common = require "luci.model.cbi.rtorrent.common"
local array = require "luci.model.cbi.rtorrent.array"
require "luci.model.cbi.rtorrent.string"

local torrents = array()
local uploads = "/etc/luci-uploads/rtorrent"
local form, uri, file, dir, tags, start
common.remove_cookie("rtorrent-notifications")

form = SimpleForm("rtorrent", "Add Torrent")
form.template = "rtorrent/simpleform"
form.submit = "Add"
form.notifications = common.get_cookie("rtorrent-notifications", {})
form.handle = function(self, state, data)
	if state ~= FORM_NODATA and torrents:empty() then
		uri:add_error(1, "missing")
		file:add_error(1, "missing", "Either a torrent URL / magnet URI or "
			.. "an uploaded torrent file must be provided!")
		return true, FORM_INVALID
	end
	if state == FORM_VALID then
		for _, torrent in torrents:pairs() do
			torrent:set("start", data.start):set("directory", data.dir):set("tags", data.tags)
			common.add_to_rtorrent(torrent)
			table.insert(form.notifications, "Added <i>%s</i>" % torrent:get("name"))
		end
		file:remove(1)
		common.set_cookie("rtorrent-notifications", form.notifications)
		luci.http.redirect(nixio.getenv("REQUEST_URI"))
	end
	return true
end

uri = form:field(TextValue, "uri", "Torrent URL(s)<br />or magnet URI(s)",
	"All torrent URL and magnet URI should be in a separate line.")
uri.template = "rtorrent/tvalue"
uri.rows = 3
uri.validate = function(self, value, section)
	local errors = array()
	for _, line in ipairs(value:split("\r\n")) do
		if "magnet:" == line:trim():sub(1, 7) then
			local magnet, err = common.parse_magnet(line:trim())
			if not magnet then errors:insert(err)
			else
				local content, err = bencode.encode({ ["magnet-uri"] = line:trim() })
				if not content then errors:insert("Failed to encode torrent: " .. err .. "!")
				else
					torrents:insert({
						["name"] = magnet:get("dn")
							and magnet:get("dn"):get(1) or line:trim(),
						["data"] = nixio.bin.b64encode(content),
						["icon"] = common.tracker_icon(common.extract_urls(magnet))
					})
				end
			end
		elseif "file://" == line:trim():sub(1, 7) then
			local filename = line:trim():sub(8)
			if not filename:starts("/") then filename = uploads .. "/" .. filename end
			local result, err = file.validate(self, filename)
			if not result then errors:insert(err) end
		elseif "http://" == line:trim():sub(1, 7) or "https://" == line:trim():sub(1, 8) then
			local content, err = common.download(line:trim())
			if not content then
				errors:insert("Failed to download torrent: " .. err .. "!")
			else
				local data, err = bencode.decode(content)
				if not data then
					errors:insert("Failed to parse torrent: " .. err .. "!")
				else
					-- TODO: extract comment from torrent file
					torrents:insert({
						["name"] = data.info.name,
						["data"] = nixio.bin.b64encode(content),
						["icon"] = common.tracker_icon(array({ line:trim(),
							unpack(common.extract_urls(array(data)):get()) })),
						["url"] = line:trim()
					})
				end
			end
		else
			errors:insert("Not supported URL/URI: \"%s\"! "  % line:trim()
				.. "Supported schemes: \"http://\", \"https://\", \"file://\", \"magnet:\".")
		end
	end
	if not errors:empty() then
		for i, err in errors:pairs() do
			if not errors:last(i) then self:add_error(section, err) end
		end
		return nil, errors:last()
	end
	return value
end

file = form:field(FileUpload, "file", "Upload torrent file")
file.template = "rtorrent/upload"
file.root_directory = uploads
file.unsafeupload = true
file.validate = function(self, value, section)
	if not datatypes.file(value) then
		return nil, "File '" .. value .. "' does not exists!"
	elseif not nixio.fs.access(value, "r") then
		return nil, "File '" .. value .. "' read permission denied!"
	end
	local content = nixio.fs.readfile(value)
	local data, err = bencode.decode(content)
	if not data then
		return nil, "Failed to parse torrent file '" .. value .. "': " .. err .. "!"
	end
	-- TODO: extract comment from torrent file
	torrents:insert({
		["name"] = data.info.name,
		["data"] = nixio.bin.b64encode(content),
		["icon"] = common.tracker_icon(common.extract_urls(array(data)))
	})
	return value
end

dir = form:field(Value, "dir", "Download directory")
dir.default = rtorrent.call("directory.default")
dir.rmempty = false
dir.validate = function(self, value, section)
	if not value then
		return nil, "Download directory must be provided!"
	elseif not datatypes.directory(value) then
		return nil, "Directory '" .. value .. "' does not exists!"
	elseif not nixio.fs.access(value, "w") then
		return nil, "Directory '" .. value .. "' write permission denied!"
	end
	return value
end

tags = form:field(Value, "tags", "Tags")

start = form:field(Flag, "start", "Start now")
start.default = "1"
start.rmempty = false

return form
