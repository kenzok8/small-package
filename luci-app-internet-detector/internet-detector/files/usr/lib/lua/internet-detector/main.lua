
local dirent = require("posix.dirent")
local fcntl  = require("posix.fcntl")
local signal = require("posix.signal")
local socket = require("posix.sys.socket")
local stat   = require("posix.sys.stat")
local syslog = require("posix.syslog")
local time   = require("posix.time")
local unistd = require("posix.unistd")
local uci    = require("uci")

-- Default settings

local InternetDetector = {
	appName        = "internet-detector",
	libDir         = "/usr/lib/lua",
	logLevels = {
		emerg   = { level = syslog.LOG_EMERG,   num = 0 },
		alert   = { level = syslog.LOG_ALERT,   num = 1 },
		crit    = { level = syslog.LOG_CRIT,    num = 2 },
		err     = { level = syslog.LOG_ERR,     num = 3 },
		warning = { level = syslog.LOG_WARNING, num = 4 },
		notice  = { level = syslog.LOG_NOTICE,  num = 5 },
		info    = { level = syslog.LOG_INFO,    num = 6 },
		debug   = { level = syslog.LOG_DEBUG,   num = 7 },
	},
	pingCmd        = "/bin/ping",
	pingParams     = "-c 1",
	curlExec       = "/usr/bin/curl",
	curlParams     = '-s -g --no-keepalive --head --user-agent "Mozilla/5.0 (X11; Linux x86_64; rv:142.0) Gecko/20100101 Firefox/142.0"',
	mode           = 0,		-- 0: disabled, 1: Service, 2: UI detector
	loggingLevel   = 6,
	hostname       = "OpenWrt",
	uiRunTime      = 30,
	noModules      = false,
	uiAvailModules = { mod_public_ip = true },
	debug          = false,
	serviceConfig  = {
		hosts = {
			[1] = "8.8.8.8",
			[2] = "1.1.1.1",
		},
		urls = {
			[1] = "https://www.google.com",
		},
		check_type          = 0,	-- 0: TCP, 1: ICMP
		tcp_port            = 53,
		icmp_packet_size    = 56,
		interval_up         = 30,
		interval_down       = 5,
		connection_attempts = 2,
		connection_timeout  = 2,
		proxy_type          = nil,
		proxy_host          = nil,
		proxy_port          = nil,
		iface               = nil,
		instance            = nil,
	},
	modules       = {},
	parsedHosts   = {},
	proxyString   = "",
	uiCounter     = 0,
	pidFile       = nil,
	statusFile    = nil,
}
InternetDetector.configDir      = string.format("/etc/%s", InternetDetector.appName)
InternetDetector.modulesDir     = string.format(
	"%s/%s/modules", InternetDetector.libDir, InternetDetector.appName)
InternetDetector.commonDir      = string.format("/tmp/run/%s", InternetDetector.appName)
InternetDetector.appNamePattern = InternetDetector.appName:gsub("-", "%%-")
InternetDetector.pidFilePattern = "^" .. InternetDetector.appNamePattern .. ".-%.pid$"

-- Loading settings from UCI

local uciCursor = uci.cursor()
local mode, err = uciCursor:get(InternetDetector.appName, "config", "mode")
if mode ~= nil then
	InternetDetector.mode = tonumber(mode)
elseif err then
	io.stderr:write(string.format("Error: %s\n", err))
end
local loggingLevel, err = uciCursor:get(InternetDetector.appName, "config", "logging_level")
if loggingLevel ~= nil then
	InternetDetector.loggingLevel = tonumber(loggingLevel)
elseif err then
	io.stderr:write(string.format("Error: %s\n", err))
end
local hostname, err = uciCursor:get("system", "@[0]", "hostname")
if hostname ~= nil then
	InternetDetector.hostname = hostname
elseif err then
	io.stderr:write(string.format("Error: %s\n", err))
end

function InternetDetector:prequire(package)
	local ok, pkg = pcall(require, package)
	return ok and pkg
end

function InternetDetector:loadInstanceConfig(instance)
	local sections = uciCursor:get_all(self.appName)
	local t        = sections[instance]
	if t then
		for k, v in pairs(t) do
			if type(v) == "string" and v:match("^[%d]+$") then
				v = tonumber(v)
			end
			self.serviceConfig[k] = v
		end
		self.serviceConfig.instance    = instance
		self.serviceConfig.instanceNum = t[".index"]
		return true
	end
	return false
end

function InternetDetector:writeValueToFile(filePath, str)
	local retValue = false
	local fh       = io.open(filePath, "w")
	if fh then
		fh:setvbuf("no")
		fh:write(string.format("%s\n", str))
		fh:close()
		retValue = true
	end
	return retValue
end

function InternetDetector:readValueFromFile(filePath)
	local retValue
	local fh = io.open(filePath, "r")
	if fh then
		retValue = fh:read("*l")
		fh:close()
	end
	return retValue
end

function InternetDetector:statusJson(inet, instance, t)
	local lines = { [1] = string.format(
		'{"instance":"%s","num":"%d","inet":%d',
		instance,
		self.serviceConfig.instanceNum,
		inet)}
	if t then
		for k, v in pairs(t) do
			lines[#lines + 1] = string.format('"%s":"%s"', k, v)
		end
	end
	return table.concat(lines, ",") .. "}"
end

function InternetDetector:writeLogMessage(level, msg)
	local levelItem  = self.logLevels[level]
	local levelValue = (levelItem and levelItem.level) or self.logLevels["info"].level
	local num        = (levelItem and levelItem.num) or self.logLevels["info"].num
	if num <= self.loggingLevel then
		syslog.syslog(levelValue, string.format(
				"%s: %s", self.serviceConfig.instance or "", msg))
	end
end

function InternetDetector:debugOutput(msg)
	if self.debug then
		io.stdout:write(string.format("[%s] %s\n", os.date("%Y.%m.%d-%H:%M:%S"), msg))
		io.stdout:flush()
	end
end

function InternetDetector:loadModules()
	self.modules = {}
	local ok, modulesDir = pcall(dirent.files, self.modulesDir)
	if ok then
		for item in modulesDir do
			if item:match("^mod_") then
				local modName = item:gsub("%.lua$", "")
				if self.noModules and not self.uiAvailModules[modName] then
				else
					local modConfig = {}
					for k, v in pairs(self.serviceConfig) do
						if k:match("^" .. modName) then
							modConfig[k:gsub("^" .. modName .. "_", "")] = v
						end
					end
					if modConfig.enabled == 1 then
						local m
						if self.debug then
							m = require(string.format("%s.modules.%s", self.appName, modName))
						else
							m = self:prequire(string.format("%s.modules.%s", self.appName, modName))
						end
						if m then
							m.config      = self
							m.syslog      = function(level, msg) self:writeLogMessage(level, msg) end
							m.debugOutput = function(msg) self:debugOutput(msg) end
							m.writeValue  = function(filePath, str) return self:writeValueToFile(filePath, str) end
							m.readValue   = function(filePath) return self:readValueFromFile(filePath) end
							m:init(modConfig)
							self.modules[#self.modules + 1] = m
						end
					end
				end
			end
		end
		table.sort(self.modules, function(a, b) return a.runPrio < b.runPrio end)
	end
end

function InternetDetector:parseHost(host)
	local addr, port = host:match("^([^%[%]:]+):?(%d?%d?%d?%d?%d?)$")
	if not addr then
		addr, port = host:match("^%[?([^%[%]]+)%]?:?(%d?%d?%d?%d?%d?)$")
	end
	return addr, tonumber(port)
end

function InternetDetector:parseHosts()
	self.parsedHosts = {}
	for k, v in ipairs(self.serviceConfig.hosts) do
		local addr, port    = self:parseHost(v)
		self.parsedHosts[k] = { addr = addr, port = port }
	end
end

function InternetDetector:parseUrls()
	self.parsedHosts = {}
	for k, v in ipairs(self.serviceConfig.urls) do
		self.parsedHosts[k] = { addr = v }
	end
end

function InternetDetector:pingHost(host)
	local ping = string.format(
		"%s %s -W %d -s %d%s %s > /dev/null 2>&1",
		self.pingCmd,
		self.pingParams,
		self.serviceConfig.connection_timeout,
		self.serviceConfig.icmp_packet_size,
		self.serviceConfig.iface and (" -I " .. self.serviceConfig.iface) or "",
		host
	)
	local retCode = os.execute(ping)

	self:debugOutput(string.format(
		"--- Ping ---\ntime = %s\n%s\nretCode = %s", os.time(), ping, retCode))

	return retCode
end

function InternetDetector:TCPConnectionToHost(host, port)
	local retCode = 1
	local saTable, errMsg, errNum = socket.getaddrinfo(host, port or self.serviceConfig.tcp_port)

	if not saTable then
		self:debugOutput(string.format(
			"GETADDRINFO ERROR: %s, %s", errMsg, errNum))
	else
		local family = saTable[1].family

		if family then
			local sock, errMsg, errNum = socket.socket(family, socket.SOCK_STREAM, 0)

			if not sock then
				self:debugOutput(string.format(
					"SOCKET ERROR: %s, %s", errMsg, errNum))
				return retCode
			end

			socket.setsockopt(sock, socket.SOL_SOCKET,
				socket.SO_SNDTIMEO, self.serviceConfig.connection_timeout, 0)
			socket.setsockopt(sock, socket.SOL_SOCKET,
				socket.SO_RCVTIMEO, self.serviceConfig.connection_timeout, 0)

			if self.serviceConfig.iface then
				local ok, errMsg, errNum = socket.setsockopt(sock, socket.SOL_SOCKET,
					socket.SO_BINDTODEVICE, self.serviceConfig.iface)
				if not ok then
					self:debugOutput(string.format(
						"SOCKET ERROR: %s, %s", errMsg, errNum))
					unistd.close(sock)
					return retCode
				end
			end

			local success = socket.connect(sock, saTable[1])

			if self.debug then
				if not success then
					self:debugOutput(string.format(
						"SOCKET CONNECT ERROR: %s", tostring(success)))
				end
				local sockTable, err_s, e_s = socket.getsockname(sock)
				local peerTable, err_p, e_p = socket.getpeername(sock)
				if not sockTable then
					sockTable = {}
					self:debugOutput(
						string.format("SOCKET ERROR: %s, %s", err_s, e_s))
				end
				if not peerTable then
					peerTable = {}
					self:debugOutput(
						string.format("SOCKET ERROR: %s, %s", err_p, e_p))
				end
				self:debugOutput(string.format(
					"--- TCP ---\ntime = %s\nconnection_timeout = %s\niface = %s\nhost:port = [%s]:%s\nsockname = [%s]:%s\npeername = [%s]:%s\nsuccess = %s",
					os.time(),
					self.serviceConfig.connection_timeout,
					tostring(self.serviceConfig.iface),
					host,
					port or self.serviceConfig.tcp_port,
					tostring(sockTable.addr),
					tostring(sockTable.port),
					tostring(peerTable.addr),
					tostring(peerTable.port),
					tostring(success))
				)
			end

			socket.shutdown(sock, socket.SHUT_RDWR)
			unistd.close(sock)
			retCode = success and 0 or 1
		end
	end
	return retCode
end

function InternetDetector:httpRequest(url)
	local retCode = 1, data
	local curl = string.format(
		'%s%s%s --connect-timeout %s %s "%s"; printf "\n$?";',
		self.curlExec,
		self.serviceConfig.iface and (" --interface " .. self.serviceConfig.iface) or "",
		self.proxyString,
		self.serviceConfig.connection_timeout,
		self.curlParams,
		url
	)
	local fh = io.popen(curl, "r")
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

	self:debugOutput(string.format(
		"--- Curl ---\ntime = %s\n%s\nretCode = %s\ndata = [\n%s]\n",
		os.time(),
		curl,
		retCode,
		tostring(data)))
	return retCode, data
end

function InternetDetector:getHTTPCode(data)
	local httpCode
	local respHeader = data:match("^HTTP/[^%c]+")
	if respHeader then
		httpCode = respHeader:match("%d%d%d")
	end
	return tonumber(httpCode)
end

function InternetDetector:checkURL(url)
	local httpCode
	local retCode, data = self:httpRequest(url)
	if retCode == 0 and data then
		httpCode = self:getHTTPCode(data)
	end
	return (httpCode ~= 200) and 1 or 0
end

function InternetDetector:exit()
	for _, e in ipairs(self.modules) do
		e:onExit()
	end
	self:removeProcessFiles()
	if self.loggingLevel > 0 then
		self:writeLogMessage("info", "stoped")
		syslog.closelog()
	end
	os.exit(0)
end

function InternetDetector:resetUiCounter(signo)
	self.uiCounter = 0
end

function InternetDetector:mainLoop()
	signal.signal(signal.SIGTERM, function(signo) self:exit(signo) end)
	signal.signal(signal.SIGINT, function(signo) self:exit(signo) end)
	signal.signal(signal.SIGQUIT, function(signo) self:exit(signo) end)
	signal.signal(signal.SIGUSR1, function(signo) self:resetUiCounter(signo) end)

	local mTimeNow, mTimeDiff, mLastTime, uiTimeNow, uiLastTime
	local lastStatus    = -1
	local currentStatus = -1
	local interval      = self.serviceConfig.interval_up
	local modulesStatus = {}
	local counter       = 0
	local inetChecked   = false
	local checking      = false
	local hostNum       = 1
	local attempt       = 1

	local checkFunc = self.TCPConnectionToHost
	if self.serviceConfig.check_type == 1 then
		checkFunc = self.pingHost
		self:parseHosts()
	elseif self.serviceConfig.check_type == 2 then
		checkFunc = self.checkURL
		self:parseUrls()
		if (self.serviceConfig.proxy_type and self.serviceConfig.proxy_host and
			self.serviceConfig.proxy_port) then
			self.proxyString = string.format(
				" --proxy %s://%s:%d",
				self.serviceConfig.proxy_type,
				self.serviceConfig.proxy_host,
				self.serviceConfig.proxy_port)
		end
	else
		self:parseHosts()
	end

	self:writeValueToFile(
		self.statusFile, self:statusJson(currentStatus, self.serviceConfig.instance))

	while true do
		if counter == 0 or counter >= interval then
			checking = true
		end

		inetChecked = false

		if checking then
			local newStatus = 1
			if hostNum <= #self.parsedHosts then
				if attempt <= self.serviceConfig.connection_attempts then
					local addr    = self.parsedHosts[hostNum].addr
					local port    = self.parsedHosts[hostNum].port
					local retCode = 1
					if self.debug then
						retCode = checkFunc(self, addr, port)
					else
						local ok, status = pcall(checkFunc, self, addr, port)
						if ok then
							retCode = status
						else
							self:writeLogMessage("err", string.format(
								"An error occurred while checking the host %s: %s",
								tostring(addr),
								tostring(status))
							)
						end
					end
					if retCode == 0 then
						attempt     = 1
						hostNum     = 1
						checking    = false
						newStatus   = 0
						counter     = 0
						inetChecked = true
					else
						attempt = attempt + 1
						if attempt > self.serviceConfig.connection_attempts then
							attempt = 1
							hostNum = hostNum + 1
						end
					end
				else
					attempt = 1
					hostNum = hostNum + 1
				end
				if hostNum > #self.parsedHosts then
					hostNum     = 1
					checking    = false
					counter     = 0
					inetChecked = true
				end
			else
				hostNum     = 1
				checking    = false
				counter     = 0
				inetChecked = true
			end

			if inetChecked then
				currentStatus = newStatus
				if not stat.stat(self.statusFile) then
					self:writeValueToFile(self.statusFile, self:statusJson(
						currentStatus, self.serviceConfig.instance))
				end
				if currentStatus == 0 then
					interval = self.serviceConfig.interval_up
					if currentStatus ~= lastStatus then
						self:writeValueToFile(self.statusFile, self:statusJson(
							currentStatus, self.serviceConfig.instance))
						self:writeLogMessage("notice", "Connected")
					end
				elseif currentStatus == 1 then
					interval = self.serviceConfig.interval_down
					if currentStatus ~= lastStatus then
						self:writeValueToFile(self.statusFile, self:statusJson(
							currentStatus, self.serviceConfig.instance))
						self:writeLogMessage("notice", "Disconnected")
					end
				end
			end
		end

		mTimeDiff   = 0
		for _, e in ipairs(self.modules) do
			mTimeNow = time.clock_gettime(time.CLOCK_MONOTONIC).tv_sec
			if mLastTime then
				mTimeDiff = mTimeDiff + mTimeNow - mLastTime
			else
				mTimeDiff = 1
			end
			mLastTime = mTimeNow

			if self.debug then
				e:run(currentStatus, lastStatus, mTimeDiff, mTimeNow, inetChecked)
			else
				local ok, err = pcall(e.run, e, currentStatus, lastStatus, mTimeDiff, mTimeNow, inetChecked)
				if not ok then
					self:writeLogMessage("err", string.format(
						"%s: Module error: %s", e.name, tostring(err)))
				end
			end
		end

		local modStatusChanged = false
		for k, v in ipairs(self.modules) do
			if modulesStatus[v.name] ~= v.status then
				modulesStatus[v.name] = v.status
				modStatusChanged      = true
			end
		end
		if modStatusChanged and next(modulesStatus) then
			self:writeValueToFile(self.statusFile, self:statusJson(
				currentStatus, self.serviceConfig.instance, modulesStatus))
		end

		unistd.sleep(1)

		if not checking then
			lastStatus = currentStatus
			counter    = counter + 1
		end

		if self.mode == 2 then
			uiTimeNow = time.clock_gettime(time.CLOCK_MONOTONIC).tv_sec
			if uiLastTime then
				self.uiCounter = self.uiCounter + uiTimeNow - uiLastTime
			else
				self.uiCounter = self.uiCounter + 1
			end
			uiLastTime = uiTimeNow
			if self.uiCounter >= self.uiRunTime then
				self:exit(signal.SIGTERM)
			end
		end
	end
end

function InternetDetector:removeProcessFiles()
	os.remove(self.statusFile)
	os.remove(self.pidFile)
end

function InternetDetector:status()
	local ok, commonDir = pcall(dirent.files, self.commonDir)
	if ok then
		for item in commonDir do
			if item:match(self.pidFilePattern) then
				return "running"
			end
		end
	end
	return "stoped"
end

function InternetDetector:inetStatus()
	local inetStat      = '{"instances":[]}'
	local ok, commonDir = pcall(dirent.files, self.commonDir)
	if ok then
		local statusFilePattern = "^" .. self.appNamePattern .. ".-%.status$"
		local lines             = {}
		for item in commonDir do
			if item:match(statusFilePattern) then
				lines[#lines + 1] = self:readValueFromFile(
					string.format("%s/%s", self.commonDir, item))
			end
		end
		inetStat = '{"instances":[' .. table.concat(lines, ",") .. "]}"
	end
	return inetStat
end

function InternetDetector:stopInstance(pidFile)
	local retVal = false, pidValue
	if stat.stat(pidFile) then
		pidValue = self:readValueFromFile(pidFile)
		if pidValue then
			local ok, errMsg, errNum
			for i = 0, 10 do
				ok, errMsg, errNum = signal.kill(tonumber(pidValue), signal.SIGTERM)
				if ok then
					break
				end
			end
			if not ok then
				io.stderr:write(string.format(
					'Process stopping error: %s (%s). PID: "%s"\n', errMsg, errNum, pidValue))
			end
			if errNum == 3 then
				os.remove(pidFile)
			end
			retVal = true
		else
			os.remove(pidFile)
		end
	end
	if not pidValue then
		io.stderr:write(
			string.format('PID file "%s" does not exists. Is the %s not running?\n',
				pidFile, self.appName))
	end
	return retVal
end

function InternetDetector:stop()
	local nopids = false
	for i = 0, 100 do
		nopids = true
		local ok, commonDir = pcall(dirent.files, self.commonDir)
		if ok then
			for item in commonDir do
				if item:match(self.pidFilePattern) then
					if self:stopInstance(string.format("%s/%s", self.commonDir, item)) then
						nopids = false
					end
				end
			end
			if nopids then
				break
			end
			time.nanosleep({ tv_sec = 0, tv_nsec = 10000000 })
		else
			break
		end
	end
end

function InternetDetector:setSIGUSR()
	local ok, commonDir = pcall(dirent.files, self.commonDir)
	if ok then
		for item in commonDir do
			if item:match(self.pidFilePattern) then
				pidValue = self:readValueFromFile(string.format("%s/%s", self.commonDir, item))
				if pidValue then
					signal.kill(tonumber(pidValue), signal.SIGUSR1)
				end
			end
		end
	end
end

function InternetDetector:preRun()
	-- Exit if internet-detector mode != (1 or 2)
	if self.mode ~= 1 and self.mode ~= 2 then
		io.stderr:write(string.format('Start failed, mode != (1 or 2)\n', self.appName))
		os.exit(0)
	end
	local s = stat.stat(self.commonDir)
	if not s or not (stat.S_ISDIR(s.st_mode) ~= 0) then
		if not stat.mkdir(self.commonDir) then
			io.stderr:write(
				string.format('Error occurred while creating %s. Exit.\n', self.commonDir))
			os.exit(1)
		end
	end
	if self.serviceConfig.check_type == 2 and not unistd.access(self.curlExec, "x") then
		io.stderr:write(string.format(
			"Error, %s is not available. You need to install curl.\n", self.curlExec))
		os.exit(1)
	end
	local ok, commonDir = pcall(dirent.files, self.commonDir)
	if ok then
		local instancePattern = "^" .. self.appNamePattern .. "%." .. self.serviceConfig.instance .. "%.[%d]+%.pid$"
		for item in commonDir do
			if item:match(instancePattern) then
				self:stopInstance(string.format("%s/%s", self.commonDir, item))
			end
		end
	end
end

function InternetDetector:run()
	local pidValue      = unistd.getpid()
	self.pidFile        = string.format(
		"%s/%s.%s.%s.pid", self.commonDir, self.appName, self.serviceConfig.instance, pidValue)
	self.statusFile     = string.format(
		"%s/%s.%s.status", self.commonDir, self.appName, self.serviceConfig.instance)
	self:writeValueToFile(self.pidFile, pidValue)

	if self.loggingLevel > 0 then
		syslog.openlog(self.appName, syslog.LOG_PID, syslog.LOG_DAEMON)
	end
	self:writeLogMessage("info", "started")
	self:loadModules()

	-- Loaded modules
	local modules = {}
	for _, v in ipairs(self.modules) do
		modules[#modules + 1] = string.format("%s", v.name)
	end
	if #modules > 0 then
		self:writeLogMessage(
			"info", string.format("Loaded modules: %s", table.concat(modules, ", "))
		)
	end

	if self.debug then
		local function inspectTable()
			local tables = {}, f
			f = function(t, prefix)
				tables[t] = true
				for k, v in pairs(t) do
					self:debugOutput(string.format(
						"%s%s = %s", prefix, k, tostring(v))
					)
					if type(v) == "table" and not tables[v] then
						f(v, string.format("%s%s.", prefix, k))
					end
				end
			end
			return f
		end

		self:debugOutput("--- Config ---")
		inspectTable()(self, "self.")
	end

	self:mainLoop()
	self:exit()
end

function InternetDetector:noDaemon()
	self:preRun()
	self:run()
end

function InternetDetector:daemon()
	self:preRun()
	-- UNIX double fork
	if unistd.fork() == 0 then
		unistd.setpid("s")
		if unistd.fork() == 0 then
			unistd.chdir("/")
			stat.umask(0)
			local devnull = fcntl.open("/dev/null", fcntl.O_RDWR)
			io.stdout:flush()
			io.stderr:flush()
			unistd.dup2(devnull, 0)	-- io.stdin
			unistd.dup2(devnull, 1)	-- io.stdout
			unistd.dup2(devnull, 2)	-- io.stderr
			self:run()
			unistd.close(devnull)
		end
		os.exit(0)
	end
	os.exit(0)
end

function InternetDetector:setServiceConfig(instance)
	if self:loadInstanceConfig(instance) then
		if self.mode == 2 then
			self.loggingLevel = 0
			self.noModules    = true
		end
		return true
	end
end

return InternetDetector
