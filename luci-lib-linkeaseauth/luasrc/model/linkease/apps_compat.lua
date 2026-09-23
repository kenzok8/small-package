local M = {}
local Compat = {}
Compat.__index = Compat

function M.new(options)
	assert(type(options) == "table" and options.http and options.resolver, "apps compatibility options are required")
	return setmetatable({
		http = options.http,
		resolver = options.resolver,
		auth_url = assert(options.auth_url, "auth_url is required")
	}, Compat)
end

function Compat:open(id)
	local decision = self.resolver:resolve(id)
	if decision.available ~= true then
		self.http.status(decision.registered == true and 503 or 404, "Service Unavailable")
		self.http.prepare_content("application/json")
		self.http.write_json(decision)
		return
	end
	self.http.redirect(self.auth_url .. "?return=" .. self.http.urlencode(decision.url))
end

function Compat:legacy_status(id, fields)
	local decision = self.resolver:status(id)
	local response = fields or {}
	response.entry_url = decision.url or ""
	response.proxy_prefix_supported = decision.proxy and decision.proxy.supported == true or false
	response.proxy_prefix_enabled = decision.proxy and decision.proxy.enabled == true or false
	response.app_entry_running = decision.mode == "apps" and decision.available == true
	response.access = decision
	self.http.status(200, "OK")
	self.http.prepare_content("application/json")
	self.http.write_json(response)
end

return M
