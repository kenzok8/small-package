
local unistd = require("posix.unistd")
local dirent = require("posix.dirent")

local Module = {
	name              = "mod_led_control",
	runPrio           = 10,
	config            = {},
	syslog            = function(level, msg) return true end,
	writeValue        = function(filePath, str) return false end,
	readValue         = function(filePath) return nil end,
	runInterval       = 5,
	sysLedsDir        = "/sys/class/leds",
	ledsPerInstance   = 3,
	ledAction1Default = 1,	-- 1: off, 2: on, 3: blink
	ledAction2Default = 1,
	status            = nil,
	_enabled          = false,
	_leds             = {},
	_counter          = 0,
}

function Module:resetLeds()
	local ok, dir = pcall(dirent.files, self.sysLedsDir)
	if not ok then
		return
	end
	for led in dir do
		local brightness = string.format("%s/%s/brightness", self.sysLedsDir, led)
		if unistd.access(brightness, "w") then
			self.writeValue(brightness, 0)
		end
	end
end

function Module:setLedAttrs(t)
	t.ledDir               = string.format("%s/%s", self.sysLedsDir, t.ledName)
	t.ledMaxBrightnessFile = string.format("%s/max_brightness", t.ledDir)
	t.ledBrightnessFile    = string.format("%s/brightness", t.ledDir)
	t.ledMaxBrightness     = self.readValue(t.ledMaxBrightnessFile) or 1
	t.ledTriggerFile       = string.format("%s/trigger", t.ledDir)
end

function Module:checkLed(t)
	return (unistd.access(t.ledDir, "r") and
		unistd.access(t.ledBrightnessFile, "rw") and
		unistd.access(t.ledTriggerFile, "rw"))
end

function Module:init(t)
	for i = 1, self.ledsPerInstance do
		self._leds[i] = {}
	end
	if t.led1_name then
		self._enabled = true
		-- Reset all LEDs
		--self:resetLeds()
	else
		return
	end
	for i, l in ipairs(self._leds) do
		if t["led" .. i .. "_name"] ~= nil then
			l.ledName    = t["led" .. i .. "_name"]
			l.ledAction1 = tonumber(t["led" .. i .. "_action_1"]) or self.ledAction1Default
			l.ledAction2 = tonumber(t["led" .. i .. "_action_2"]) or self.ledAction2Default
			self:setLedAttrs(l)
			l.enabled = true
		else
			l.enabled = false
		end
		if l.enabled and not self:checkLed(l) then
			self._enabled = false
			self.syslog("err", string.format(
				"%s: module disabled. LED '%s' is not available", self.name, l.ledName))
		end
	end
end

function Module:SetTriggerTimer(t)
	self.writeValue(t.ledTriggerFile, "timer")
end

function Module:SetTriggerNone(t)
	self.writeValue(t.ledTriggerFile, "none")
end

function Module:getCurrentTrigger(t)
	local trigger = self.readValue(t.ledTriggerFile)
	if trigger and trigger:match("%[timer%]") then
		return true
	end
end

function Module:on(t)
	self:SetTriggerNone(t)
	self.writeValue(t.ledBrightnessFile, t.ledMaxBrightness)
end

function Module:off(t)
	self:SetTriggerNone(t)
	self.writeValue(t.ledBrightnessFile, 0)
end

function Module:getCurrentState(t)
	local state = self.readValue(t.ledBrightnessFile)
	if state and tonumber(state) > 0 then
		return tonumber(state)
	end
end

function Module:ledRunFunc(t, currentStatus)
	if currentStatus == 0 then
		if t.ledAction1 == 1 then
			if self:getCurrentState(t) or self:getCurrentTrigger(t) then
				self:off(t)
			end
		elseif t.ledAction1 == 2 then
			if not self:getCurrentState(t) or self:getCurrentTrigger(t) then
				self:on(t)
			end
		elseif t.ledAction1 == 3 then
			if not self:getCurrentTrigger(t) then
				self:SetTriggerTimer(t)
			end
		end
	else
		if t.ledAction2 == 1 then
			if self:getCurrentState(t) or self:getCurrentTrigger(t) then
				self:off(t)
			end
		elseif t.ledAction2 == 2 then
			if not self:getCurrentState(t) or self:getCurrentTrigger(t) then
				self:on(t)
			end
		elseif t.ledAction2 == 3 then
			if not self:getCurrentTrigger(t) then
				self:SetTriggerTimer(t)
			end
		end
	end
end

function Module:run(currentStatus, lastStatus, timeDiff, timeNow, inetChecked)
	if not self._enabled then
		return
	end
	if self._counter == 0 or self._counter >= self.runInterval or currentStatus ~= lastStatus then
		for _, t in ipairs(self._leds) do
			if t.enabled then
				self:ledRunFunc(t, currentStatus)
			end
		end
		self._counter = 0
	end
	self._counter = self._counter + timeDiff
end

return Module
