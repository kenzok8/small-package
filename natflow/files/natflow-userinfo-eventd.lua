#!/usr/bin/lua

local userinfo = require "natflow.userinfo"
local nixio = require "nixio"

local DEV_EVENT = "/dev/natflow_userinfo_queue"
local HOTPLUG_CALL = "/sbin/hotplug-call"
local EVENT_CACHE_LIMIT = 256
local EVENT_READ_SIZE = userinfo.EVENT_SIZE * 32

local event_fd

local function log(priority, message)
	if nixio.syslog then
		nixio.syslog(priority, "natflow-userinfo-eventd: " .. message)
	else
		io.stderr:write("natflow-userinfo-eventd: " .. message .. "\n")
	end
end

local function sleep_msec(msec)
	if nixio.nanosleep then
		nixio.nanosleep(math.floor(msec / 1000), (msec % 1000) * 1000000)
	else
		os.execute("sleep " .. tostring(math.max(1, math.floor((msec + 999) / 1000))))
	end
end

local function fd_write_all(fd, data)
	if type(fd.writeall) == "function" then
		local ok = fd:writeall(data)
		return ok ~= nil and ok ~= false
	end

	local offset = 1
	while offset <= #data do
		local len = fd:write(data:sub(offset))
		if type(len) ~= "number" or len <= 0 then
			return false
		end
		offset = offset + len
	end
	return true
end

local function open_event_queue()
	local fd = nixio.open(DEV_EVENT, nixio.open_flags("rdwr"))
	if not fd then
		return nil
	end

	if not fd_write_all(fd, string.format("cache=%u\n", EVENT_CACHE_LIMIT)) then
		fd:close()
		return nil
	end
	return fd
end

local function wait_event_queue(fd)
	if type(nixio.poll) ~= "function" or type(nixio.poll_flags) ~= "function" then
		sleep_msec(1000)
		return true
	end

	local ok, ready = pcall(function()
		local fds = {
			{
				fd = fd,
				events = nixio.poll_flags("in"),
			}
		}
		return nixio.poll(fds, -1)
	end)
	if not ok or ready == nil then
		sleep_msec(1000)
		return true
	end
	if type(ready) == "number" then
		return ready >= 0
	end
	return ready ~= false
end

local function dispatch_hotplug(event, action)
	local env = userinfo.environment(event, action)
	local pid, err = nixio.fork()
	if not pid then
		log("err", "fork failed: " .. tostring(err or "unknown error"))
		return false
	end

	if pid == 0 then
		if event_fd then
			event_fd:close()
		end
		local _, exec_err = nixio.exece(HOTPLUG_CALL, { "userinfo" }, env)
		log("err", "exec failed: " .. tostring(exec_err or "unknown error"))
		os.exit(127)
	end

	local waited, state, status = nixio.waitpid(pid)
	if waited ~= pid or state ~= "exited" or status ~= 0 then
		log("warning", string.format("hotplug action %s failed: state=%s status=%s",
			tostring(action), tostring(state), tostring(status)))
		return false
	end
	return true
end

local function read_event_batch(fd, pending)
	local data = fd:read(EVENT_READ_SIZE)
	if not data then
		return false, pending, false
	end
	if #data == 0 then
		return true, pending, false
	end

	data = pending .. data
	local offset = 1
	while #data - offset + 1 >= userinfo.EVENT_SIZE do
		local record = data:sub(offset, offset + userinfo.EVENT_SIZE - 1)
		local event, err = userinfo.parse_binary(record)
		if event then
			dispatch_hotplug(event, "update")
		else
			log("warning", "skipped invalid queue record: " .. tostring(err))
		end
		offset = offset + userinfo.EVENT_SIZE
	end

	return true, data:sub(offset), true
end

local function run_worker()
	event_fd = open_event_queue()
	if not event_fd then
		log("err", "failed to open userinfo event queue")
		return 1
	end

	dispatch_hotplug(nil, "start")

	local pending = ""
	while wait_event_queue(event_fd) do
		for _ = 1, 32 do
			local ok, new_pending, had_events = read_event_batch(event_fd, pending)
			pending = new_pending
			if not ok then
				event_fd:close()
				event_fd = nil
				return 1
			end
			if not had_events then
				break
			end
		end
	end

	event_fd:close()
	event_fd = nil
	return 0
end

os.exit(run_worker())
