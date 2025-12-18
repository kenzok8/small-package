local sys = require "luci.sys"
local uci = require "luci.model.uci".cursor()
local http = require "luci.http"

local m = Map("fastnet", translate("FastNet"))
m.description = translate("FastNet provides network testing tools and a Web UI.")

local function get_host()
	local host = http.getenv("HTTP_HOST") or http.getenv("SERVER_NAME") or ""
	host = host:gsub(":%d+$", "")
	if host == "_redirect2ssl" or host == "redirect2ssl" or host == "" then
		host = http.getenv("SERVER_ADDR") or "localhost"
	end
	return host
end

local st = m:section(SimpleSection, translate("Status"))
local running = (sys.call("pidof FastNet >/dev/null") == 0)
local listen_port = uci:get_first("fastnet", "fastnet", "port") or "3200"
local token = uci:get_first("fastnet", "fastnet", "token") or ""
local url = "http://" .. get_host() .. ":" .. listen_port .. "/"
if token ~= "" then
  url = url .. "?token=" .. token
end

st.template = "fastnet/status"
st.running = running
st.url = url

local s = m:section(TypedSection, "fastnet", translate("Settings"))
s.anonymous = true

local enabled = s:option(Flag, "enabled", translate("Enable"))
enabled.default = enabled.enabled

local port = s:option(Value, "port", translate("Listen Port"))
port.datatype = "port"
port.default = "3200"

local token = s:option(Value, "token", translate("API Token"))
token.password = true
token.rmempty = true

local logger = s:option(Flag, "logger", translate("Enable Logging"))
logger.rmempty = true

return m
