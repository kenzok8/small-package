-- Copyright 2014-2021 Sandor Balazsi <sandor.balazsi@gmail.com>
-- Licensed to the public under the GNU General Public License.

local common = require "luci.model.cbi.rtorrent.common"
local array = require "luci.model.cbi.rtorrent.array"
require "luci.model.cbi.rtorrent.string"

local map, cookies, domain, cookie

function cookie_list(value)
	if value:blank() or value:trim():ends(";") or value:trim():starts(";")
	or value:match(";[^ ]") or value:match(";  +") then
		return false
	end
	local name_value
	for name_value in value:gmatch("[^; ]+") do
		-- https://stackoverflow.com/a/1969339
		if not name_value:match("^[%w!#$%%&'*+-.^_`|~]+"
			.. "=" .. "[%w!#$%%&'()*+-./:<=>?@%[%]^_`{|}~]+$") then
			return false
		end
	end
	return true
end

map = Map("rtorrent", "rTorrent LuCI Frontend Settings")
map.on_parse = function(self, ...)
	local domains = array()
	for _, section_id in ipairs(cookies:cfgsections()) do
		if domains:get(domain:formvalue(section_id)) then
			domains:get(domain:formvalue(section_id)):insert(section_id)
		else domains:set(domain:formvalue(section_id), { section_id }) end
	end
	for _, sections in domains:pairs() do
		if sections:size() > 1 then
			for _, section_id in sections:pairs() do
				domain:add_error(section_id, "invalid", "Same domain defined more than once!")
			end
			self.save = false
		end
	end
end

cookies = map:section(TypedSection, "cookies", "Cookies",
	"Cookies are used to download torrent files and RSS feeds from authenticated pages and trackers.")
cookies.addremove = true
cookies.anonymous = true

domain = cookies:option(Value, "domain", "Domain")
domain.rmempty = false

cookie = cookies:option(TextValue, "cookie", "Cookie",
	'List of name-value pairs separated by a semicolon and space: <a target="_blank" href="'
	.. 'https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Cookie#syntax">syntax</a>.')
cookie.template = "rtorrent/tvalue"
cookie.rmempty = false
cookie.rows = 1
cookie.validate = function(self, value, section)
	if value and not cookie_list(value) then
		return nil, "The provided cookie does not satisfy cookie name-value list syntax!"
	end
	return value
end

return map
