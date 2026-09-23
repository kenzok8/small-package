local sys = require "luci.sys"
local dispatcher = require "luci.dispatcher"

local m = Map("fastnet", translate("FastNet"))
m.description = translate("FastNet provides network testing tools and a Web UI.")

local st = m:section(SimpleSection, translate("Status"))
local running = (sys.call("pidof FastNet >/dev/null") == 0)
local url = dispatcher.build_url("admin", "services", "linkease_apps", "open") .. "?id=fastnet"

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
