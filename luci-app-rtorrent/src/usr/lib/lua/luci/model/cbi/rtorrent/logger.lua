-- Copyright 2014-2021 Sandor Balazsi <sandor.balazsi@gmail.com>
-- Licensed to the public under the GNU General Public License.

local socket = require "socket"
local nixio = require "nixio"
local class = require "luci.util".class
local array = require "luci.model.cbi.rtorrent.array"

local levels = {
	["TRACE"] = 1, ["DEBUG"] = 2, ["INFO"] = 3, ["WARN"] = 4, ["ERROR"] = 5, ["FATAL"] = 6, ["OFF"] = 7
}

local function timestamp()
	return os.date("%Y-%m-%d %H:%M:%S") .. "," .. tostring("%.3f" % socket.gettime()):match("%.(%d+)")
end

local function message(self, level, ...)
	if levels[level] >= levels[self.level] then
		local line = array()
			:append(timestamp())
			:append("%-5s" % level)
			:append(unpack({...}))
			:join(" ")
		self.fh:lock("lock")
		self.fh:write(line .. "\n")
		self.fh:sync()
		self.fh:lock("ulock")
	end
end

--[[ A P I ]]--

local logger = class()

function logger.__init__(self, level, target)
	self.level = level or "INFO"
	if level ~= "OFF" then
		self.fh = nixio.open(target or "/dev/tty", "a")
	end
end

function logger.close(self)
	self.fh:sync()
	self.fh:close()
end

function logger.trace(self, ...)
	message(self, "TRACE", ...)
end

function logger.debug(self, ...)
	message(self, "DEBUG", ...)
end

function logger.info(self, ...)
	message(self, "INFO", ...)
end

function logger.warn(self, ...)
	message(self, "WARN", ...)
end

function logger.error(self, ...)
	message(self, "ERROR", ...)
end

function logger.fatal(self, ...)
	message(self, "FATAL", ...)
end

return logger
