m = Map("iperf3-server",
	translate("iPerf3 Server"),
	translate("iPerf3 - The ultimate speed test tool for TCP, UDP and SCTP")
)

m:section(SimpleSection).template = "iperf3-server/iperf3-server_status"

-- 主配置段
local g = m:section(TypedSection, "iperf3-server", "")
g.addremove = false
g.anonymous  = true

local main_enable = g:option(Flag, "main_enable",
	translate("Enable"),
	translate("Enable iPerf3 Servers")
)
main_enable.default = "0"
main_enable.rmempty = false

-- servers 表格
local s = m:section(TypedSection, "servers",
	translate("Server Settings"),
	translate("Set up Multi-iPerf3 Servers")
)
s.anonymous = true
s.addremove = true
s.template  = "cbi/tblsection"

local enable_server = s:option(Flag, "enable_server", translate("Enable"))
enable_server.default = "1"
enable_server.rmempty = false

local port = s:option(Value, "port", translate("Port"))
port.datatype = "port"
port.default  = "5201"
port.rmempty  = true   -- 关键：允许新增行先空着，避免“点添加无反应”

function port.validate(self, value, section)
	-- 新增行刚创建时可能是空值：先放行，让它能显示出来
	if value == nil or value == "" then
		return value
	end

	local v = tonumber(value)
	if not v or v < 1 or v > 65535 then
		return nil, translate("Invalid port.")
	end

	-- 端口去重：仅在有值时检查
	local dup = false
	m.uci:foreach("iperf3-server", "servers", function(s2)
		if s2[".name"] ~= section and s2.port and tonumber(s2.port) == v then
			dup = true
		end
	end)

	if dup then
		return nil, translate("Port must be unique.")
	end

	return tostring(v)
end

local delay = s:option(Value, "delay", translate("Start delay (Seconds)"))
delay.default  = "0"
delay.datatype = "uinteger"
delay.rmempty  = true  -- 同理：新增行先允许空

function delay.validate(self, value, section)
	if value == nil or value == "" then
		return value
	end
	local v = tonumber(value)
	if v == nil or v < 0 or v > 3600 then
		return nil, translate("Delay must be between 0 and 3600 seconds.")
	end
	return tostring(v)
end

local extra_options = s:option(Value, "extra_options", translate("Extra Options"))
extra_options.rmempty  = true
extra_options.password = false

function extra_options.validate(self, value, section)
	if not value or value == "" then
		return value
	end
	-- 简单拦截 shell 元字符（安全兜底）
	if value:match("[;&|`$()<>\"']") then
		return nil, translate("Invalid characters in Extra Options.")
	end
	return value
end

return m
