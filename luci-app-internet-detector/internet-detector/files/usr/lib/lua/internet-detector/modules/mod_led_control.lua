
local dirent = require("posix.dirent")
local time   = require("posix.time")
local unistd = require("posix.unistd")

local Module = {
	name                     = "mod_led_control",
	runPrio                  = 10,
	config                   = {},
	syslog                   = function(level, msg) return true end,
	debugOutput              = function(msg) return true end,
	writeValue               = function(filePath, str) return false end,
	readValue                = function(filePath) return nil end,
	runInterval              = 5,
	sysLedsDir               = "/sys/class/leds",
	ledsPerInstance          = 3,
	ledAction1Default        = 1,	-- 1: off, 2: on, 3: blinking, 4: netdev
	ledAction2Default        = 1,
	ledBlinkDelayDefault     = 500,
	ledNetlinkDeviceDefault  = nil,
	ledNetdevModeLinkDefault = "1",
	ledNetdevModeRxDefault   = "0",
	ledNetdevModeTxDefault   = "0",
	status                   = nil,
	_enabled                 = false,
	_leds                    = {},
	_counter                 = 0,
	_exit                    = false,
}

function Module:setLedAttrs(t)
	t.ledDir               = string.format("%s/%s", self.sysLedsDir, t.ledName)
	t.ledMaxBrightnessFile = string.format("%s/max_brightness", t.ledDir)
	t.ledBrightnessFile    = string.format("%s/brightness", t.ledDir)
	t.ledMaxBrightness     = self.readValue(t.ledMaxBrightnessFile) or "1"
	t.ledTriggerFile       = string.format("%s/trigger", t.ledDir)
	t.ledDelayOnFile       = string.format("%s/delay_on", t.ledDir)
	t.ledDelayOffFile      = string.format("%s/delay_off", t.ledDir)
	t.ledDeviceNameFile    = string.format("%s/device_name", t.ledDir)
	t.ledLinkFile          = string.format("%s/link", t.ledDir)
	t.ledRxFile            = string.format("%s/rx", t.ledDir)
	t.ledTxFile            = string.format("%s/tx", t.ledDir)
	t.ledPrevState         = {
		brightness = self.readValue(t.ledBrightnessFile),
		trigger    = self.readValue(t.ledTriggerFile),
	}
	if t.ledPrevState.trigger then
		local val = t.ledPrevState.trigger:match("%[[%w%-_]+%]")
		if val then
			t.ledPrevState.trigger = val:gsub("[%]%[]", "")
		end
	end
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
	else
		return
	end
	for i, l in ipairs(self._leds) do
		local led = "led" .. i
		if t[led .. "_name"] ~= nil then
			l.ledName            = t[led .. "_name"]
			l.ledAction1         = tonumber(t[led .. "_action_1"]) or self.ledAction1Default
			l.ledAction2         = tonumber(t[led .. "_action_2"]) or self.ledAction2Default
			l.ledBlinkOnDelay1   = tonumber(t[led .. "_blink_on_delay_1"]) or self.ledBlinkDelayDefault
			l.ledBlinkOffDelay1  = tonumber(t[led .. "_blink_off_delay_1"]) or self.ledBlinkDelayDefault
			l.ledBlinkOnDelay2   = tonumber(t[led .. "_blink_on_delay_2"]) or self.ledBlinkDelayDefault
			l.ledBlinkOffDelay2  = tonumber(t[led .. "_blink_off_delay_2"]) or self.ledBlinkDelayDefault
			l.ledNetlinkDevice1  = t[led .. "_netdev_device_1"] or self.ledNetlinkDeviceDefault
			l.ledNetlinkDevice2  = t[led .. "_netdev_device_2"] or self.ledNetlinkDeviceDefault
			l.ledNetdevModeLink1 = self.ledNetdevModeLinkDefault
			l.ledNetdevModeTx1   = self.ledNetdevModeTxDefault
			l.ledNetdevModeRx1   = self.ledNetdevModeRxDefault
			l.ledNetdevModeLink2 = self.ledNetdevModeLinkDefault
			l.ledNetdevModeTx2   = self.ledNetdevModeTxDefault
			l.ledNetdevModeRx2   = self.ledNetdevModeRxDefault
			local ndm1 = t[led .. "_netdev_mode_1"]
			if ndm1 ~= nil and type(ndm1) == "table" then
				local enabledFlags = {}
				for _, v in ipairs(ndm1) do
					enabledFlags[v] = "1"
				end
				l.ledNetdevModeLink1 = enabledFlags.link or "0"
				l.ledNetdevModeTx1   = enabledFlags.tx or "0"
				l.ledNetdevModeRx1   = enabledFlags.rx or "0"
			end
			local ndm2 = t[led .. "_netdev_mode_2"]
			if ndm2 ~= nil and type(ndm2) == "table" then
				local enabledFlags = {}
				for _, v in ipairs(ndm2) do
					enabledFlags[v] = "1"
				end
				l.ledNetdevModeLink2 = enabledFlags.link or "0"
				l.ledNetdevModeTx2   = enabledFlags.tx or "0"
				l.ledNetdevModeRx2   = enabledFlags.rx or "0"
			end
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
		self._exit = false
	end
end

function Module:checkLedTimer(t)
	return (unistd.access(t.ledDelayOnFile, "rw") and unistd.access(t.ledDelayOffFile, "rw"))
end

function Module:checkLedNetdev(t)
	return (unistd.access(t.ledDeviceNameFile, "rw") and
		unistd.access(t.ledLinkFile, "rw") and
		unistd.access(t.ledRxFile, "rw") and
		unistd.access(t.ledTxFile, "rw"))
end

function Module:setTriggerNone(t)
	self.writeValue(t.ledTriggerFile, "none")
	self.debugOutput(string.format(
		"%s: LED TRIGGER SET: none, %s", self.name, t.ledTriggerFile))
end

function Module:setTriggerTimer(t, delayOn, delayOff)
	if not delayOn then
		delayOn = self.ledBlinkDelayDefault
	end
	if not delayOff then
		delayOff = self.ledBlinkDelayDefault
	end

	self.writeValue(t.ledTriggerFile, "timer")

	for i = 0, 10 do
		if self:checkLedTimer(t) then
			self.writeValue(t.ledDelayOnFile, delayOn)
			self.writeValue(t.ledDelayOffFile, delayOff)
			break
		else
			time.nanosleep({ tv_sec = 0, tv_nsec = 500000 })
		end
	end

	self.debugOutput(string.format(
		"%s: LED TRIGGER SET: timer, %s; delayOn = %s, delayOff = %s",
		self.name, t.ledTriggerFile, tostring(delayOn), tostring(delayOff))
	)
end

function Module:setTriggerNetdev(t, device, link, tx, rx)
	if not device then
		return
	end

	self.writeValue(t.ledTriggerFile, "netdev")

	for i = 0, 10 do
		if self:checkLedNetdev(t) then
			self.writeValue(t.ledDeviceNameFile, device)
			self.writeValue(t.ledLinkFile, link)
			self.writeValue(t.ledTxFile, tx)
			self.writeValue(t.ledRxFile, rx)
			break
		else
			time.nanosleep({ tv_sec = 0, tv_nsec = 500000 })
		end
	end

	self.debugOutput(string.format(
		"%s: LED TRIGGER SET: netdev, %s; device = %s, link = %s, rx = %s, tx = %s",
		self.name, t.ledTriggerFile, tostring(device), tostring(link), tostring(rx), tostring(tx))
	)
end

function Module:getCurrentTrigger(t)
	local trigger = self.readValue(t.ledTriggerFile)
	if trigger then
		if trigger:match("%[timer%]") then
			return "timer"
		elseif trigger:match("%[netdev%]") then
			return "netdev"
		end
	end
end

function Module:getTriggerValues(t, trigger)
	local currentTrigger = self:getCurrentTrigger(t)
	if trigger == currentTrigger then
		if trigger == "timer" then
			return {
				trigger  = currentTrigger,
				delayOn  = tonumber(self.readValue(t.ledDelayOnFile)),
				delayOff = tonumber(self.readValue(t.ledDelayOffFile)),
			}
		elseif trigger == "netdev" then
			return {
				trigger = currentTrigger,
				device  = self.readValue(t.ledDeviceNameFile),
				link    = self.readValue(t.ledLinkFile),
				tx      = self.readValue(t.ledTxFile),
				rx      = self.readValue(t.ledRxFile),
			}
		end
	end
	return {}
end

function Module:on(t)
	self:setTriggerNone(t)
	self.writeValue(t.ledBrightnessFile, t.ledMaxBrightness)

	self.debugOutput(string.format("%s: LED ON: %s", self.name, t.ledBrightnessFile))
end

function Module:off(t)
	self:setTriggerNone(t)
	self.writeValue(t.ledBrightnessFile, "0")

	self.debugOutput(string.format("%s: LED OFF: %s", self.name, t.ledBrightnessFile))
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
			local triggerValues = self:getTriggerValues(t, "timer")
			if (not next(triggerValues)) or (triggerValues.delayOn ~= t.ledBlinkOnDelay1 or
			    triggerValues.delayOff ~= t.ledBlinkOffDelay1) then
				self:setTriggerTimer(t, t.ledBlinkOnDelay1, t.ledBlinkOffDelay1)
			end
		elseif t.ledAction1 == 4 then
			local triggerValues = self:getTriggerValues(t, "netdev")
			if (not next(triggerValues)) or (triggerValues.device ~= t.ledNetlinkDevice1 or
			    triggerValues.link ~= t.ledNetdevModeLink1 or
			    triggerValues.tx ~= t.ledNetdevModeTx1 or
			    triggerValues.rx ~= t.ledNetdevModeRx1) then
				self:setTriggerNetdev(t,
					t.ledNetlinkDevice1, t.ledNetdevModeLink1,
					t.ledNetdevModeTx1, t.ledNetdevModeRx1
				)
			end
		end
	elseif currentStatus == 1 then
		if t.ledAction2 == 1 then
			if self:getCurrentState(t) or self:getCurrentTrigger(t) then
				self:off(t)
			end
		elseif t.ledAction2 == 2 then
			if not self:getCurrentState(t) or self:getCurrentTrigger(t) then
				self:on(t)
			end
		elseif t.ledAction2 == 3 then
			local triggerValues = self:getTriggerValues(t, "timer")
			if (not next(triggerValues)) or (triggerValues.delayOn ~= t.ledBlinkOnDelay2 or
			    triggerValues.delayOff ~= t.ledBlinkOffDelay2) then
				self:setTriggerTimer(t, t.ledBlinkOnDelay2, t.ledBlinkOffDelay2)
			end
		elseif t.ledAction2 == 4 then
			local triggerValues = self:getTriggerValues(t, "netdev")
			if (not next(triggerValues)) or (triggerValues.device ~= t.ledNetlinkDevice2 or
			    triggerValues.link ~= t.ledNetdevModeLink2 or
			    triggerValues.tx ~= t.ledNetdevModeTx2 or
			    triggerValues.rx ~= t.ledNetdevModeRx2) then
				self:setTriggerNetdev(t,
					t.ledNetlinkDevice2, t.ledNetdevModeLink2,
					t.ledNetdevModeTx2, t.ledNetdevModeRx2
				)
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
			if self._exit then
				break
			end
			if t.enabled then
				self:ledRunFunc(t, currentStatus)
			end
		end
		self._counter = 0
	end
	self._counter = self._counter + timeDiff
end

function Module:onExit()
	self._exit = true
	for _, l in ipairs(self._leds) do
		if l.ledPrevState then
			if l.ledPrevState.brightness then
				self.writeValue(l.ledBrightnessFile, l.ledPrevState.brightness)
			end
			if l.ledPrevState.trigger then
				self.writeValue(l.ledTriggerFile, l.ledPrevState.trigger)
			end
		end
	end
end

return Module
