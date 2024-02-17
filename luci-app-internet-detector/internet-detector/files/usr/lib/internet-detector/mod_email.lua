--[[
	Dependences:
		mailsend
--]]
local unistd = require("posix.unistd")

local Module = {
	name               = "mod_email",
	runPrio            = 60,
	config             = {
		debug = false,
	},
	syslog             = function(level, msg) return true end,
	writeValue         = function(filePath, str) return false end,
	readValue          = function(filePath) return nil end,
	alivePeriod        = 0,
	hostAlias          = "OpenWrt",
	mta                = "/usr/bin/mailsend",
	mailRecipient      = "email@gmail.com",
	mailSender         = "email@gmail.com",
	mailUser           = "email@gmail.com",
	mailPassword       = "password",
	mailSmtp           = "smtp.gmail.com",
	mailSmtpPort       = '587',
	mailSecurity       = "tls",
	status             = nil,
	_enabled           = false,
	_aliveCounter      = 0,
	_msgSent           = true,
	_disconnected      = true,
	_lastDisconnection = nil,
	_lastConnection    = nil,
}

function Module:init(t)
	self.alivePeriod = tonumber(t.alive_period)
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
	self.mailSecurity  = t.mail_security

	if unistd.access(self.mta, "x") then
		self._enabled = true
	else
		self._enabled = false
		self.syslog("warning", string.format("%s: %s is not available", self.name, self.mta))
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
end

function Module:sendMessage(msg)
	local verboseArg = ""

	-- Debug
	if self.config.debug then
		verboseArg = " -v"
		io.stdout:write(string.format("--- %s ---\n", self.name))
		io.stdout:flush()
	end

	local securityArgs = "-starttls -auth-login"
	if self.mailSecurity == "ssl" then
		securityArgs = "-ssl -auth"
	end

	local mtaCmd = string.format(
		'%s%s %s -smtp "%s" -port %s -cs utf-8 -user "%s" -pass "%s" -f "%s" -t "%s" -sub "%s" -M "%s"',
		self.mta, verboseArg, securityArgs, self.mailSmtp, self.mailSmtpPort,
		self.mailUser, self.mailPassword, self.mailSender, self.mailRecipient,
		string.format("%s notification", self.hostAlias),
		string.format("%s:\n%s", self.hostAlias, msg))

	if os.execute(mtaCmd) ~= 0 then
		self.syslog("err", string.format(
			"%s: An error occured while sending message", self.name))
	else
		self.syslog("info", string.format(
			"%s: Message sent to %s", self.name, self.mailRecipient))
	end
end

function Module:run(currentStatus, lastStatus, timeDiff)
	if not self._enabled then
		return
	end

	if currentStatus == 1 then
		self._aliveCounter   = 0
		self._msgSent        = false
		self._lastConnection = nil
		if not self._disconnected then
			self._disconnected = true
			if not self._lastDisconnection then
				self._lastDisconnection = os.date("%Y.%m.%d %H:%M:%S", os.time())
			end
		end

	else

		if not self._msgSent then

			if not self._lastConnection then
				self._lastConnection = os.date("%Y.%m.%d %H:%M:%S", os.time())
			end

			if self._aliveCounter >= self.alivePeriod then
				local message = {}
				if self._lastDisconnection then
					message[#message + 1] = string.format(
						"Internet disconnected: %s", self._lastDisconnection)
					self._lastDisconnection = nil
				end
				if self._lastConnection then
					message[#message + 1] = string.format(
						"Internet connected: %s", self._lastConnection)
					self:sendMessage(table.concat(message, ", "))
					self._msgSent = true
				end
			else
				self._aliveCounter = self._aliveCounter + timeDiff
			end
		end

		self._disconnected = false
	end
end

return Module
