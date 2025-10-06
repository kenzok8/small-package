--[[
LuCI - Lua Configuration Interface

Copyright 2025 LunaticKochiya<125438787@qq.com>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

$Id$
]]--
local NXFS = require "nixio.fs"
local sys = require "luci.sys"
local util = require "luci.util"

local base_dir = "/etc/openvpn"

local function get_config_path(identifier)
    if identifier and identifier:match("^[a-zA-Z0-9_%-]+$") then
        return base_dir .. "/" .. identifier .. ".conf"
    end
    return nil
end

m2 = Map("openvpn", "OpenVPN Client", translate("Configuration for OpenVPN client instances. The instance name you provide becomes the UCI section name (e.g., 'client1' leads to `config openvpn 'client1'`)."))

m2:section(SimpleSection).template = "openvpn/openvpn_status"

sl = m2:section(TypedSection, "openvpn", translate("OpenVPN Client Instances"))
sl.title = translate("OpenVPN Client Instances")
sl.anonymous = false
sl.addremove = true
sl.description = translate("Enter a unique identifier (e.g., client1, client2) when adding an instance. This identifier is used for the UCI section name and the corresponding .conf file.")
sl.sortable = true

sl.filter = function(self, section)
    return section:match("^client") ~= nil
end

sl:tab("base", translate("Base Settings"))
sl:tab("config_file", translate("Client Config File Content"))

local o

o = sl:taboption("base", Flag, "enabled", translate("Enable Instance"))
o.default = o.disabled
o.rmempty = false

o = sl:taboption("base", Value, "config", translate("Config File Path"))
o.readonly = true
o.placeholder = translate("Auto-generated based on instance identifier")
o.datatype = "file"
o.rmempty = false

o.cfgvalue = function(self, section)
    return get_config_path(section) or translate("Invalid instance identifier.")
end

o = sl:taboption("config_file", TextValue, "_config_content")
o.title = translate("OpenVPN Configuration (.ovpn/.conf)")
o.description = translate("Paste the content of the .ovpn or .conf file here. This will be saved to the path shown in 'Base Settings'.")
o.rows = 15
o.wrap = "off"
o.rmempty = true

o.cfgvalue = function(self, section)
    local conf_file = get_config_path(section)
    if conf_file then
        return NXFS.readfile(conf_file) or ""
    else
        return "-- " .. translate("Cannot read file: Invalid instance identifier used for this section.") .. " --"
    end
end

o.write = function(self, section, value)
    local conf_file = get_config_path(section)
    if not conf_file then
        luci.util.perror("OpenVPN: Invalid identifier '" .. tostring(section) .. "', cannot write config file.")
        return
    end

    if value and value ~= "" then
        NXFS.writefile(conf_file, value:gsub("\r\n", "\n"))
        self.map:set(section, "config", conf_file)
    else
        NXFS.remove(conf_file)
    end
end

o.remove = function(self, section)
    local conf_file = get_config_path(section)
    if conf_file then
        NXFS.remove(conf_file)
    end
end

sl.on_remove = function(self, section)
    local conf_file = get_config_path(section)
    if conf_file then
        local ok, err = NXFS.remove(conf_file)
        if ok then
            luci.util.perror("OpenVPN: Removed config file: " .. conf_file)
        else
            luci.util.perror("OpenVPN: Error removing config file " .. conf_file .. ": " .. tostring(err))
        end
    end
    TypedSection.on_remove(self, section)
end

sp = m2:section(TypedSection, "openvpnpassword", translate("OpenVPN Client Authentication"))
sp.title = translate("OpenVPN Client Authentication")
sp.anonymous = false
sp.addremove = true
sp.description = translate("Configure authentication files for OpenVPN client instances.")
sp.sortable = true

o = sp:option(Value, "pwdfile", translate("Authentication File Path"))
o.placeholder = translate("Enter the path for the authentication file (e.g., /etc/openvpn/password.txt)")
o.datatype = "string"
o.rmempty = false

o = sp:option(TextValue, "_auth_content", translate("Authentication File Content"))
o.description = translate("Enter the content of the authentication file (e.g., username on the first line, password on the second line). This will be saved to the path shown above.")
o.rows = 5
o.wrap = "off"
o.rmempty = true

o.cfgvalue = function(self, section)
    local pwdfile = self.map:get(section, "pwdfile")
    if pwdfile then
        return NXFS.readfile(pwdfile) or ""
    else
        return "-- " .. translate("Cannot read file: Invalid instance identifier used for this section.") .. " --"
    end
end

o.write = function(self, section, value)
    local pwdfile = self.map:get(section, "pwdfile")
    if not pwdfile then
        luci.util.perror("OpenVPN: Invalid identifier '" .. tostring(section) .. "', cannot write authentication file.")
        return
    end

    if value and value ~= "" then
        NXFS.writefile(pwdfile, value:gsub("\r\n", "\n"))
    else
        NXFS.remove(pwdfile)
    end
end

o.remove = function(self, section)
    local pwdfile = self.map:get(section, "pwdfile")
    if pwdfile then
        NXFS.remove(pwdfile)
    end
end

sp.on_remove = function(self, section)
    local pwdfile = self.map:get(section, "pwdfile")
    if pwdfile then
        local ok, err = NXFS.remove(pwdfile)
        if ok then
            luci.util.perror("OpenVPN: Removed authentication file: " .. pwdfile)
        else
            luci.util.perror("OpenVPN: Error removing authentication file " .. pwdfile .. ": " .. tostring(err))
        end
    end
    TypedSection.on_remove(self, section)
end

m2.on_commit = function(self)
    local result = sys.call("/etc/init.d/openvpn reload")
    if result ~= 0 then
        self.message = translate("Failed to reload OpenVPN service.")
    end
end

return m2
