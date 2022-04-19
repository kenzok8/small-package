-- Copyright 2014-2021 Sandor Balazsi <sandor.balazsi@gmail.com>
-- Licensed to the public under the GNU General Public License.

local io = require "io"
local nixio = require "nixio"
local http = require "luci.http"
local rtorrent = require "rtorrent"
local common = require "luci.model.cbi.rtorrent.common"
local array = require "luci.model.cbi.rtorrent.array"
require "luci.model.cbi.rtorrent.string"

module("luci.model.cbi.rtorrent.download", package.seeall)

function permitted(path)
	for _, path_prefix in ipairs({ "/bin/", "/boot/", "/dev/", "/etc/", "/lib/", "/overlay/", "/proc/",
			"/root/", "/run/", "/sbin/", "/srv/", "/sys/", "/tmp/", "/usr/", "/var/", "/www/" }) do
		if path:starts(path_prefix) then
			return false
		end
	end
	return true
end

function download(hash, ...)
	local download_dir = rtorrent.call("d.directory", hash)
	local path = nixio.fs.realpath(array({...}):insert(1, download_dir):join("/"))
	if not permitted(path) then
		http.write("<h2>Download from this location is not permitted!</h2>")
	elseif nixio.fs.stat(path, "type") == "reg" then
		download_file(path)
	elseif nixio.fs.stat(path, "type") == "dir" then
		download_folder(path)
	else
		http.write("<h2>No such file or directory: " .. path .. "</h2>")
	end
end

function download_file(file)
	http.header("Content-Disposition", 'attachment; filename="%s"' % nixio.fs.basename(file))
	http.header("Transfer-Encoding", "chunked")
	http.prepare_content("application/octet-stream")
	pump(nixio.open(file, "r"))
end

function download_folder(folder)
	if http.getenv("HTTP_USER_AGENT"):lower():find("linux")
	or nixio.fs.stat("/usr/bin/zip", "type") ~= "reg" then
		download_as_tar(folder)
	else
		download_as_zip(folder)
	end
end

function download_as_tar(folder)
	http.header("Content-Disposition", 'attachment; filename="%s.tar"' % nixio.fs.basename(folder))
	http.header("Transfer-Encoding", "chunked")
	http.prepare_content("application/x-tar")
	pump(io.popen('tar -cf - -C "%s" .' % folder))
end

function download_as_zip(folder)
	http.header("Content-Disposition", 'attachment; filename="%s.zip"' % nixio.fs.basename(folder))
	http.header("Transfer-Encoding", "chunked")
	http.prepare_content("application/zip")
	pump(io.popen('cd "%s" && zip -0 -r - .' % folder))
end

function pump(fh)
	local blocksize = 2^13	--8K
	repeat
		local chunk = fh:read(blocksize)
		http.write(string.format("%X", chunk and #chunk or 0) .. "\r\n" .. chunk .. "\r\n")
	until not chunk or chunk == ""
	fh:close()
end
