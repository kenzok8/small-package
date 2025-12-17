--[[
	Dependences:
		curl
--]]

local unistd = require("posix.unistd")

local Module = {
	name                 = "mod_telegram",
	runPrio              = 70,
	syslog               = function(level, msg) return true end,
	debugOutput          = function(msg) return true end,
	writeValue           = function(filePath, str) return false end,
	readValue            = function(filePath) return nil end,
	deadPeriod           = 0,
	alivePeriod          = 0,
	mode                 = 0,		-- 0: connected, 1: disconnected, 2: both
	hostAlias            = "OpenWrt",
	connectTimeout       = 5,
	tgAPIToken           = nil,
	tgChatId             = nil,
	tgMsgURLpattern      = "https://api.telegram.org/bot%s/sendMessage?chat_id=%s&parse_mode=html&text=%s",
	msgTextPattern       = "<strong>[%s] (%s)</strong> @ %s",	-- Message (host, instance, message)
	msgConnectPattern    = "Connected: %s",
	msgDisconnectPattern = "Disconnected: %s",
	msgSeparator         = " | ",
	msgMaxItems          = 50,
	msgSendAttempts      = 3,
	msgSendTimeout       = 5,
	curlExec             = "/usr/bin/curl",
	curlParams           = "-s -g --no-keepalive",
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

local function prequire(package)
	local retVal, pkg = pcall(require, package)
	return retVal and pkg
end

function Module:init(t)
	self._enabled = true
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
	if t.api_token ~= nil then
		self.tgAPIToken = t.api_token
	end
	if t.chat_id ~= nil then
		self.tgChatId = t.chat_id
	end
	if tonumber(t.message_at_startup) == 1 then
		self._msgSentDisconnect = false
		self._disconnected      = false
		self._msgSentConnect    = false
		self._connected         = false
	end

	if unistd.access(self.curlExec, "x") then
		self._enabled = true
	else
		self._enabled = false
		self.syslog("err", string.format("%s: %s is not available", self.name, self.curlExec))
	end
	if not self.tgAPIToken then
		self._enabled = false
		self.syslog("err", string.format("%s: Telegram bot API token not specified.", self.name))
	end
	if not self.tgChatId then
		self._enabled = false
		self.syslog("err", string.format("%s: Telegram chat ID not specified.", self.name))
	end

	self._msgSendCounter = self.msgSendAttempts
end

function Module:escape(str)
	local t = {}
	for i in str:gmatch(".") do
		if i:match("[^%w_]") then
			t[#t + 1] = "%" .. string.format("%x", string.byte(i))
		else
			t[#t + 1] = i
		end
	end
	return table.concat(t)
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

function Module:httpRequest(url)
	local retCode = 1, data
	local fh      = io.popen(string.format(
		'%s --connect-timeout %s %s "%s"; printf "\n$?";',
		self.curlExec,
		self.connectTimeout,
		self.curlParams,
		url
	), "r")
	if fh then
		data = fh:read("*a")
		fh:close()
		if data ~= nil then
			local s, e = data:find("[0-9]+\n?$")
			retCode    = tonumber(data:sub(s))
			data       = data:sub(0, s - 2)
			if not data or data == "" then
				data = nil
			end
		end
	else
		retCode = 1
	end
	return retCode, data
end

function Module:parseResponse(str)
    local ok, errCode, desc
    ok = str:match('"ok":(%w+)')
    if ok == "false" then
        errCode = tonumber(str:match('"error_code":(%d+)'))
        if errCode then
            desc = str:match('"description":"([%w%s%p_]+)"')
        end
    end
    return ok, errCode, desc
end

function Module:messageRequest(msg, textPattern)
	local retVal = 1
	local tgMsg  = string.format(
		textPattern, self.hostAlias, self.config.serviceConfig.instance, msg)
	local url    = string.format(
		self.tgMsgURLpattern, self.tgAPIToken, self.tgChatId, self:escape(tgMsg))

	local ok, errCode, desc
	local retCode, data = self:httpRequest(url)
	if data then
		ok, errCode, desc = self:parseResponse(data)
	end
	if retCode == 0 and ok == "true" then
		retVal = 0
		self.syslog("info", string.format(
			"%s: Message sent to chat %s", self.name, self.tgChatId))
	else
		if errCode == 400 or errCode == 406 then
			retVal = 2
		elseif (errCode == 401 or
		        errCode == 403 or
		        errCode == 404 or
		        errCode == 420) then
			retVal = 3
		end
		if errCode and desc then
			self.syslog("warning", string.format(
				"%s: %s %s", self.name, tostring(errCode), tostring(desc)))
		end
	end
	return retVal
end

function Module:sendMessage(msg, textPattern)
	local retVal = self:messageRequest(msg, textPattern)
	if retVal == 0 then
		self._msgBuffer = {}
	elseif retVal == 2 then
		self.syslog("err", string.format(
			"%s: Server error (invalid API token or chat ID)", self.name))
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
				local retVal = self:sendMessage(table.concat(self._msgBuffer, self.msgSeparator), self.msgTextPattern)
				if retVal == 1 then
					self._msgSendCounter = self._msgSendCounter + 1
				else
					self._msgSendCounter = self.msgSendAttempts
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
