
local unistd = require("posix.unistd")

local Module = {
	name              = "mod_reboot",
	runPrio           = 20,
	config            = {},
	syslog            = function(level, msg) return true end,
	debugOutput       = function(msg) return true end,
	writeValue        = function(filePath, str) return false end,
	readValue         = function(filePath) return nil end,
	deadPeriod        = 3600,
	forceRebootDelay  = 300,
	antiBootloopDelay = 300,
	status            = nil,
	_deadCounter      = 0,
	_rebooted         = true,
}

function Module:rebootDevice()
	self.syslog("warning", string.format("%s: reboot", self.name))
	os.execute("/sbin/reboot &")
	if self.forceRebootDelay > 0 then
		unistd.sleep(self.forceRebootDelay)
		self.syslog("warning", string.format("%s: force reboot", self.name))
		self.writeValue("/proc/sys/kernel/sysrq", "1")
		self.writeValue("/proc/sysrq-trigger", "b")
	end
end

function Module:init(t)
	if t.dead_period ~= nil then
		self.deadPeriod  = tonumber(t.dead_period)
	end
	if t.force_reboot_delay ~= nil then
		self.forceRebootDelay = tonumber(t.force_reboot_delay)
	end
	if tonumber(t.disconnected_at_startup) == 1 then
		self._rebooted = false
	end
end

function Module:run(currentStatus, lastStatus, timeDiff, timeNow, inetChecked)
	if currentStatus == 1 then
		if not self._rebooted then
			if timeNow >= self.antiBootloopDelay and self._deadCounter >= self.deadPeriod then
				self:rebootDevice()
				self._rebooted = true
			else
				self._deadCounter = self._deadCounter + timeDiff
			end
		end
	else
		self._deadCounter = 0
		self._rebooted    = false
	end
end

function Module:onExit()
	return true
end

return Module
