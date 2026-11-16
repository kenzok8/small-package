--[[
	Dependences:
		mailsend
--]]
local unistd = require("posix.unistd")

local Module = {
	name                 = "mod_email",
	runPrio              = 60,
	config               = {
		debug = false,
	},
	syslog               = function(level, msg) return true end,
	debugOutput          = function(msg) return true end,
	writeValue           = function(filePath, str) return false end,
	readValue            = function(filePath) return nil end,
	deadPeriod           = 0,
	alivePeriod          = 0,
	mode                 = 0,		-- 0: connected, 1: disconnected, 2: both
	hostAlias            = "OpenWrt",
	mta                  = "/usr/bin/mailsend",
	mtaConnectTimeout    = 5,
	mtaReadTimeout       = 5,
	mailRecipient        = nil,
	mailSender           = nil,
	mailUser             = nil,
	mailPassword         = nil,
	mailSmtp             = nil,
	mailSmtpPort         = nil,
	mailSecurity         = "tls",
	msgTextPattern       = "[%s] (%s) @ %s",	-- Message (host, instance, message)
	msgSubPattern        = "%s notification",	-- Subject (host)
	msgConnectPattern    = "Connected: %s",
	msgDisconnectPattern = "Disconnected: %s",
	msgSeparator         = " | ",
	msgMaxItems          = 50,
	msgSendAttempts      = 3,
	msgSendTimeout       = 5,
	status               = nil,
	_enabled             = false,
	_deadCounter         = 0,
	_aliveCounter        = 0,
	_msgSentDisconnect   = true,
	_disconnected        = true,
	_msgSentConnect      = true,
	_connected           = true,
	_msgBuffer           = {},
	_msgSendCounter      = 3,
	_msgTimeoutCounter   = 5,
}

function Module:init(t)
	if t.mode ~= nil then
		self.mode = tonumber(t.mode)
	end
	if t.dead_period ~= nil then
		self.deadPeriod = tonumber(t.dead_period)
	end
	if t.alive_period ~= nil then
		self.alivePeriod = tonumber(t.alive_period)
	end
	if t.host_alias then
		self.hostAlias = t.host_alias
	else
		self.hostAlias = self.config.hostname
	end

	self.mailRecipient = t.mail_recipient
	self.mailSender    = t.mail_sender
	self.mailUser      = t.mail_user
	self.mailPassword  = t.mail_password
	self.mailSmtp      = t.mail_smtp
	self.mailSmtpPort  = t.mail_smtp_port

	if t.mail_security ~= nil then
		self.mailSecurity = t.mail_security
	end
	if tonumber(t.message_at_startup) == 1 then
		self._msgSentDisconnect = false
		self._disconnected      = false
		self._msgSentConnect    = false
		self._connected         = false
	end

	if unistd.access(self.mta, "x") then
		self._enabled = true
	else
		self._enabled = false
		self.syslog("err", string.format("%s: %s is not available", self.name, self.mta))
	end

	if (not self.mailRecipient or
	    not self.mailSender or
	    not self.mailUser or
	    not self.mailPassword or
	    not self.mailSmtp or
	    not self.mailSmtpPort) then
		self._enabled = false
		self.syslog("warning", string.format(
			"%s: Insufficient data to connect to the SMTP server", self.name))
	end

	self._msgSendCounter = self.msgSendAttempts
end

function Module:appendNotice(str)
	self._msgBuffer[#self._msgBuffer + 1] = str
	if #self._msgBuffer > self.msgMaxItems then
		local t = {}
		for i = #self._msgBuffer - self.msgMaxItems + 1, #self._msgBuffer do
			t[#t + 1] = self._msgBuffer[i]
		end
		self._msgBuffer = t
	end
end

function Module:sendMessage(msg, textPattern)
	local retVal     = 1
	local verboseArg = ""
	local emailMsg   = string.format(
		textPattern, self.hostAlias, self.config.serviceConfig.instance, msg)

	-- Debug
	if self.config.debug then
		verboseArg = " -v"
	end
	self.debugOutput(string.format("--- %s ---", self.name))

	local securityArgs = "-starttls -auth-login"
	if self.mailSecurity == "ssl" then
		securityArgs = "-ssl -auth"
	end

	local mtaCmd = string.format(
		'%s%s %s -smtp "%s" -port %s -ct %s -read-timeout %s -cs utf-8 -user "%s" -pass "%s" -f "%s" -t "%s" -sub "%s" -M "%s"',
		self.mta, verboseArg, securityArgs, self.mailSmtp, self.mailSmtpPort,
		self.mtaConnectTimeout, self.mtaReadTimeout,
		self.mailUser, self.mailPassword, self.mailSender, self.mailRecipient,
		string.format(self.msgSubPattern, self.hostAlias),
		emailMsg)

	-- Debug
	self.debugOutput(string.format("%s: %s", self.name, mtaCmd))
	self.syslog("debug", string.format("%s: %s", self.name, mtaCmd))

	retVal = os.execute(mtaCmd)
	if retVal == 0 then
		self.syslog("info", string.format(
			"%s: Message sent to %s", self.name, self.mailRecipient))
		self._msgBuffer = {}
	else
		self.syslog("err", string.format(
			"%s: An error occured while sending message", self.name))
	end

	return retVal
end

function Module:run(currentStatus, lastStatus, timeDiff, timeNow, inetChecked)
	if not self._enabled then
		return
	end

	if currentStatus == 1 then
		self._aliveCounter   = 0
		self._msgSentConnect = false

		if not self._disconnected then
			self._disconnected = true
			self:appendNotice(string.format(
				self.msgDisconnectPattern, os.date("%Y.%m.%d %H:%M:%S", os.time())))
		end

		if not self._msgSentDisconnect and (self.mode == 1 or self.mode == 2) then
			if self._deadCounter >= self.deadPeriod then
				self._msgSendCounter    = 0
				self._msgSentDisconnect = true
			else
				self._deadCounter = self._deadCounter + timeDiff
			end
		end
		self._connected = false
	elseif currentStatus == 0 then
		self._deadCounter       = 0
		self._msgSentDisconnect = false

		if not self._connected then
			self._connected = true
			self:appendNotice(string.format(
				self.msgConnectPattern, os.date("%Y.%m.%d %H:%M:%S", os.time())))
		end

		if not self._msgSentConnect and (self.mode == 0 or self.mode == 2) then
			if self._aliveCounter >= self.alivePeriod then
				self._msgSendCounter = 0
				self._msgSentConnect = true
			else
				self._aliveCounter = self._aliveCounter + timeDiff
			end
		end
		self._disconnected = false
	end

	if self._msgSendCounter < self.msgSendAttempts then
		if self._msgTimeoutCounter >= self.msgSendTimeout then
			if #self._msgBuffer > 0 then
				if self:sendMessage(table.concat(self._msgBuffer, self.msgSeparator), self.msgTextPattern) == 0 then
					self._msgSendCounter = self.msgSendAttempts
				else
					self._msgSendCounter = self._msgSendCounter + 1
				end
			end
			self._msgTimeoutCounter = 0
		else
			self._msgTimeoutCounter = self._msgTimeoutCounter + timeDiff
		end
	else
		self._msgTimeoutCounter = self.msgSendTimeout
	end
end

function Module:onExit()
	return true
end

return Module
