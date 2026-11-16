
local unistd = require("posix.unistd")

local Module = {
	name                    = "mod_network_restart",
	runPrio                 = 30,
	config                  = {},
	syslog                  = function(level, msg) return true end,
	debugOutput             = function(msg) return true end,
	writeValue              = function(filePath, str) return false end,
	readValue               = function(filePath) return nil end,
	deadPeriod              = 900,
	attempts                = 1,
	attemptInterval         = 15,
	deviceTimeout           = 0,
	status                  = nil,
	_attemptsCounter        = 0,
	_attemptIntervalCounter = 0,
	_deadCounter            = 0,
	_firstAttempt           = true,
	_ifaceRestarting        = false,
	_ifaceRestartCounter    = 0,
	_netIfaces              = {},
	_netDevices             = {},
	_netItemsNum            = 0,
	_disconnectedAtStartup  = false,
}

function Module:toggleDevices(flag)
	if #self._netDevices == 0 then
		return
	end
	local ip = "/sbin/ip"
	if unistd.access(ip, "x") then
		for _, v in ipairs(self._netDevices) do
			os.execute(string.format("%s link set dev %s %s", ip, v, (flag and "up" or "down")))
		end
	end
end

function Module:toggleIfaces(flag)
	if #self._netIfaces == 0 then
		return
	end
	for _, v in ipairs(self._netIfaces) do
		os.execute(string.format("%s %s", (flag and "/sbin/ifup" or "/sbin/ifdown"), v))
	end
end

function Module:netItemsUp()
	self:toggleDevices(true)
	self:toggleIfaces(true)
end

function Module:netItemsDown()
	self:toggleIfaces(false)
	self:toggleDevices(false)
end

function Module:restartNetworkService()
	return os.execute("/etc/init.d/network restart")
end

function Module:init(t)
	if t.ifaces ~= nil and type(t.ifaces) == "table" then
		self._netIfaces   = {}
		self._netDevices  = {}
		self._netItemsNum = 0
		for k, v in ipairs(t.ifaces) do
			if v:match("^@") then
				self._netIfaces[#self._netIfaces + 1] = v:gsub("^@", "")
			else
				self._netDevices[#self._netDevices + 1] = v
			end
			self._netItemsNum = self._netItemsNum + 1
		end
	end
	if t.dead_period ~= nil then
		self.deadPeriod = tonumber(t.dead_period)
	end
	if t.attempts ~= nil then
		self.attempts = tonumber(t.attempts)
	end
	if t.attempt_interval ~= nil then
		self.attemptInterval = tonumber(t.attempt_interval)
	end
	if t.device_timeout ~= nil then
		self.deviceTimeout = tonumber(t.device_timeout)
	end
	if tonumber(t.disconnected_at_startup) == 1 then
		self._disconnectedAtStartup = true
	end
end

function Module:networkRestartFunc()
	if self._netItemsNum > 0 then
		if #self._netIfaces > 0 then
			self.syslog("info", string.format("%s: restarting interfaces: %s",
				self.name, table.concat(self._netIfaces, ", ")))
		end
		if #self._netDevices > 0 then
			self.syslog("info", string.format("%s: restarting devices: %s",
				self.name, table.concat(self._netDevices, ", ")))
		end
		self:netItemsDown()
		if self.deviceTimeout < 1 then
			self:netItemsUp()
		else
			self._ifaceRestarting = true
		end
	else
		self.syslog("info", string.format(
			"%s: restarting network", self.name))
		self:restartNetworkService()
	end
	if self.attempts > 0 then
		self._attemptsCounter = self._attemptsCounter + 1
	end
end

function Module:run(currentStatus, lastStatus, timeDiff, timeNow, inetChecked)
	if self._ifaceRestarting then
		if self._ifaceRestartCounter >= self.deviceTimeout then
			self:netItemsUp()
			self._ifaceRestarting     = false
			self._ifaceRestartCounter = 0
		else
			self._ifaceRestartCounter = self._ifaceRestartCounter + timeDiff
		end
	else
		if currentStatus == 1 then
			if self._disconnectedAtStartup and self._deadCounter >= self.deadPeriod then
				if self.attempts == 0 or self._attemptsCounter < self.attempts then
					if self._firstAttempt or self._attemptIntervalCounter >= self.attemptInterval then
						self:networkRestartFunc()
						self._attemptIntervalCounter = 0
						self._firstAttempt           = false
					else
						self._attemptIntervalCounter = self._attemptIntervalCounter + timeDiff
					end
				end
			else
				self._deadCounter = self._deadCounter + timeDiff
			end
		else
			self._attemptsCounter        = 0
			self._attemptIntervalCounter = 0
			self._deadCounter            = 0
			self._disconnectedAtStartup  = true
			self._firstAttempt           = true
		end
		self._ifaceRestartCounter = 0
	end
end

function Module:onExit()
	return true
end

return Module
