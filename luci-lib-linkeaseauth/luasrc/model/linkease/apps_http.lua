local M = {}
local Handler = {}
Handler.__index = Handler

local status_messages = {
	[200] = "OK",
	[400] = "Bad Request",
	[404] = "Not Found",
	[503] = "Service Unavailable"
}

local function response_status(decision)
	if decision.reason == "invalid_id" then return 400 end
	if decision.registered ~= true then return 404 end
	if decision.available ~= true then return 503 end
	return 200
end

function M.new(options)
	assert(type(options) == "table" and options.http and options.resolver, "apps HTTP options are required")
	return setmetatable({
		http = options.http,
		resolver = options.resolver,
		auth_url = assert(options.auth_url, "auth_url is required")
	}, Handler)
end

function Handler:write(decision, code)
	self.http.status(code, status_messages[code])
	self.http.prepare_content("application/json")
	self.http.write_json(decision)
end

function Handler:status()
	local decision = self.resolver:status(self.http.formvalue("id"))
	self:write(decision, response_status(decision))
end

function Handler:open()
	local decision = self.resolver:resolve(self.http.formvalue("id"))
	local code = response_status(decision)
	if code ~= 200 then
		self:write(decision, code)
		return
	end
	self.http.redirect(self.auth_url .. "?return=" .. self.http.urlencode(decision.url))
end

return M
