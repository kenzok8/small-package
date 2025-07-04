--[[
	Dependences:
		modemmanager
--]]
local unistd = require("posix.unistd")

local Module = {
	name                    = "mod_modem_restart",
	runPrio                 = 40,
	config                  = {},
	syslog                  = function(level, msg) return true end,
	debugOutput             = function(msg) return true end,
	writeValue              = function(filePath, str) return false end,
	readValue               = function(filePath) return nil end,
	mmcli                   = "/usr/bin/mmcli",
	mmInit                  = "/etc/init.d/modemmanager",
	deadPeriod              = 600,
	attempts                = 1,
	attemptInterval         = 15,
	ifaceTimeout            = 0,
	iface                   = nil,
	anyBand                 = false,
	status                  = nil,
	_enabled                = false,
	_attemptsCounter        = 0,
	_attemptIntervalCounter = 0,
	_deadCounter            = 0,
	_firstAttempt           = true,
	_ifaceRestarting        = false,
	_ifaceRestartCounter    = 0,
	_disconnectedAtStartup  = false,
}

function Module:toggleIface(flag)
	if not self.iface then
		return
	end
	return os.execute(
		string.format("%s %s", (flag and "/sbin/ifup" or "/sbin/ifdown"), self.iface)
	)
end

function Module:init(t)
	if t.dead_period ~= nil then
		self.deadPeriod = tonumber(t.dead_period)
	end
	if t.attempts ~= nil then
		self.attempts = tonumber(t.attempts)
	end
	if t.attempt_interval ~= nil then
		self.attemptInterval = tonumber(t.attempt_interval)
	end
	if t.iface ~= nil then
		self.iface = t.iface
	end
	if t.iface_timeout ~= nil then
		self.ifaceTimeout = tonumber(t.iface_timeout)
	end
	if t.any_band ~= nil then
		self.anyBand = (tonumber(t.any_band) ~= 0)
	end
	if tonumber(t.disconnected_at_startup) == 1 then
		self._disconnectedAtStartup = true
	end

	if not unistd.access(self.mmcli, "x") then
		self.anyBand = false
	end

	if (unistd.access(self.mmInit, "x")
		and os.execute(string.format("%s enabled", self.mmInit)) == 0) then
		self._enabled = true
	else
		self._enabled = false
		self.syslog("err", string.format(
			"%s: modemmanager service is not available", self.name))
	end
end

function Module:restartMM()
	if os.execute(string.format("%s enabled", self.mmInit)) == 0 then
		if self.anyBand then
			self.syslog("info", string.format(
				"%s: resetting current-bands to 'any'", self.name))
			os.execute(string.format("%s -m any --set-current-bands=any", self.mmcli))
		end

		self.syslog("info", string.format("%s: reconnecting modem", self.name))
		os.execute(string.format("%s restart", self.mmInit))

		if self.iface then
			self.syslog("info", string.format(
				"%s: restarting network interface '%s'", self.name, self.iface))
			self:toggleIface(false)
			if self.ifaceTimeout < 1 then
				self:toggleIface(true)
			else
				self._ifaceRestarting = true
			end
		end
	else
		self.syslog("warning", string.format(
			"%s: modemmanager service is disabled", self.name))
	end
	if self.attempts > 0 then
		self._attemptsCounter = self._attemptsCounter + 1
	end
end

function Module:run(currentStatus, lastStatus, timeDiff, timeNow, inetChecked)
	if not self._enabled then
		return
	end
	if self.iface and self._ifaceRestarting then
		if self._ifaceRestartCounter >= self.ifaceTimeout then
			self:toggleIface(true)
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
						self:restartMM()
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
