local sys = require "luci.sys"

-- Create the main map object
local map = Map("timewol", translate("Timed Wake on LAN"),
    translate("Wake up your local area network devices on schedule"))
map.template = "timewol/index"

-- Running Status Section
local status_section = map:section(TypedSection, "basic", translate("Running Status"))
status_section.anonymous = true

local status = status_section:option(DummyValue, "timewol_status", translate("Current Status"))
status.template = "timewol/timewol"
status.value = translate("Collecting data...")

-- Basic Settings Section
local basic_section = map:section(TypedSection, "basic", translate("Basic Settings"))
basic_section.anonymous = true

local enable = basic_section:option(Flag, "enable", translate("Enable"))
enable.rmempty = false

-- Client Settings Section
local client_section = map:section(TypedSection, "macclient", translate("Client Settings"))
client_section.template = "cbi/tblsection"
client_section.anonymous = true
client_section.addremove = true

-- Client MAC Address
local mac_addr = client_section:option(Value, "macaddr", translate("Client MAC"))
mac_addr.rmempty = false
sys.net.mac_hints(function(mac, hint)
    mac_addr:value(mac, string.format("%s (%s)", mac, hint))
end)

-- Network Interface
local net_iface = client_section:option(Value, "maceth", translate("Network Interface"))
net_iface.rmempty = false
net_iface.default = "br-lan"
for _, device in ipairs(sys.net.devices()) do
    if device ~= "lo" then
        net_iface:value(device)
    end
end

-- wake device
local btn = client_section:option(Button, "_awake",translate("Wake Up Host"))
btn.inputtitle	= translate("Awake")
btn.inputstyle	= "apply"
btn.disabled	= false
btn.template = "timewol/awake"

-- Function to validate cron field values
local function validate_cron_field(option_name, value, min, max, default)
    if value == "" then
        return default
    elseif value == "*" then
        return value
    end
    local num = tonumber(value)
    if num and num >= min and num <= max then
        return value
    else
        return nil, translatef("Invalid value for %s: %s. Must be between %d and %d or '*'", option_name, value, min, max)
    end
end

-- Scheduling Options with Default Values and Range Checks
local schedule_options = {
    { "minute", translate("Minute"), 0, 59, "0" },
    { "hour", translate("Hour"), 0, 23, "0" },
    { "day", translate("Day"), 1, 31, "*" },
    { "month", translate("Month"), 1, 12, "*" },
    { "weeks", translate("Week"), 0, 6, "*" }  -- 0 for Sunday, 6 for Saturday
}

for _, opt in ipairs(schedule_options) do
    local field = client_section:option(Value, opt[1], opt[2])
    field.default = opt[5] or opt[4] -- Use default value if present, otherwise use maximum value
    field.optional = false
    field.validate = function(self, value)
        return validate_cron_field(opt[2], value, opt[3], opt[4], field.default)
    end
end

-- Apply the configuration changes
map.apply_on_parse = true
function map.on_apply(self)
    sys.exec("/etc/init.d/timewol restart")
end

return map

