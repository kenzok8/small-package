
local unistd = require("posix.unistd")

local Module = {
	name                              = "mod_user_scripts",
	runPrio                           = 80,
	config                            = {},
	syslog                            = function(level, msg) return true end,
	debugOutput                       = function(msg) return true end,
	writeValue                        = function(filePath, str) return false end,
	readValue                         = function(filePath) return nil end,
	deadPeriod                        = 0,
	alivePeriod                       = 0,
	upScript                          = "",
	downScript                        = "",
	upScriptAttempts                  = 1,
	upScriptAttemptInterval           = 15,
	downScriptAttempts                = 1,
	downScriptAttemptInterval         = 15,
	status                            = nil,
	_deadCounter                      = 0,
	_aliveCounter                     = 0,
	_upScriptAttemptsCounter          = 0,
	_upScriptAttemptIntervalCounter   = 0,
	_downScriptAttemptsCounter        = 0,
	_downScriptAttemptIntervalCounter = 0,
	_upScriptFirstAttempt             = true,
	_downScriptFirstAttempt           = true,
	_disconnectedAtStartup            = false,
	_connectedAtStartup               = false,
}

function Module:runExternalScript(scriptPath)
	if unistd.access(scriptPath, "r") then
		os.execute(string.format('/bin/sh "%s" &', scriptPath))
	end
end

function Module:init(t)
	if t.dead_period ~= nil then
		self.deadPeriod  = tonumber(t.dead_period)
	end
	if t.alive_period ~= nil then
		self.alivePeriod = tonumber(t.alive_period)
	end
	if t.up_script_attempts ~= nil then
		self.upScriptAttempts = tonumber(t.up_script_attempts)
	end
	if t.up_script_attempt_interval ~= nil then
		self.upScriptAttemptInterval = tonumber(t.up_script_attempt_interval)
	end
	if t.down_script_attempts ~= nil then
		self.downScriptAttempts = tonumber(t.down_script_attempts)
	end
	if t.down_script_attempt_interval ~= nil then
		self.downScriptAttemptInterval = tonumber(t.down_script_attempt_interval)
	end
	if self.config.configDir then
		self.upScript   = string.format(
			"%s/up-script.%s", self.config.configDir, self.config.serviceConfig.instance)
		self.downScript = string.format(
			"%s/down-script.%s", self.config.configDir, self.config.serviceConfig.instance)
	end
	if tonumber(t.connected_at_startup) == 1 then
		self._connectedAtStartup = true
	end
	if tonumber(t.disconnected_at_startup) == 1 then
		self._disconnectedAtStartup = true
	end
end

function Module:runUpScriptFunc()
	self:runExternalScript(self.upScript)
	if self.upScriptAttempts > 0 then
		self._upScriptAttemptsCounter = self._upScriptAttemptsCounter + 1
	end
end

function Module:runDownScriptFunc()
	self:runExternalScript(self.downScript)
	if self.downScriptAttempts > 0 then
		self._downScriptAttemptsCounter = self._downScriptAttemptsCounter + 1
	end
end

function Module:run(currentStatus, lastStatus, timeDiff, timeNow, inetChecked)
	if currentStatus == 1 then
		self._upScriptAttemptsCounter        = 0
		self._upScriptAttemptIntervalCounter = 0
		self._aliveCounter                   = 0
		self._connectedAtStartup             = true
		self._upScriptFirstAttempt           = true

		if self._disconnectedAtStartup and self._deadCounter >= self.deadPeriod then
			if self.downScriptAttempts == 0 or self._downScriptAttemptsCounter < self.downScriptAttempts then
				if self._downScriptFirstAttempt or self._downScriptAttemptIntervalCounter >= self.downScriptAttemptInterval then
					self:runDownScriptFunc()
					self._downScriptAttemptIntervalCounter = 0
					self._downScriptFirstAttempt           = false
				else
					self._downScriptAttemptIntervalCounter = self._downScriptAttemptIntervalCounter + timeDiff
				end
			end
		else
			self._deadCounter = self._deadCounter + timeDiff
		end
	elseif currentStatus == 0 then
		self._downScriptAttemptsCounter        = 0
		self._downScriptAttemptIntervalCounter = 0
		self._deadCounter                      = 0
		self._disconnectedAtStartup            = true
		self._downScriptFirstAttempt           = true

		if self._connectedAtStartup and self._aliveCounter >= self.alivePeriod then
			if self.upScriptAttempts == 0 or self._upScriptAttemptsCounter < self.upScriptAttempts then
				if self._upScriptFirstAttempt or self._upScriptAttemptIntervalCounter >= self.upScriptAttemptInterval then
					self:runUpScriptFunc()
					self._upScriptAttemptIntervalCounter = 0
					self._upScriptFirstAttempt           = false
				else
					self._upScriptAttemptIntervalCounter = self._upScriptAttemptIntervalCounter + timeDiff
				end
			end
		else
			self._aliveCounter = self._aliveCounter + timeDiff
		end
	end
end

function Module:onExit()
	return true
end

return Module
