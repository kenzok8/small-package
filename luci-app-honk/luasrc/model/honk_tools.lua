local fs = require "nixio.fs"
local dsp = require "luci.dispatcher"

local Button = luci.cbi.Button
local TextValue = luci.cbi.TextValue
local TypedSection = luci.cbi.TypedSection
local SimpleSection = luci.cbi.SimpleSection
local DummyValue = luci.cbi.DummyValue
local translate = luci.i18n.translate

local M = {}

function M.init_editor(m, current_page)
    m:section(SimpleSection).template = "honk/honk_status"

    local s = m:section(TypedSection, "honk")
    s.addremove = false
    s.anonymous = true

    local o = s:option(Button, "_reload", translate("Reload Service"), translate("Reload service to apply configuration."))
    o.inputstyle = "reload"
    o.write = function()
        luci.sys.call("/etc/init.d/honk hot_reload >/dev/null 2>&1 &")
        luci.http.redirect(dsp.build_url("admin", "services", "honk", current_page) .. "?reload=1")
    end

    return s
end

function M.add_editor(s, config_file, option_name, title, description, rows)
    local o = s:option(TextValue, option_name, title, description)
    o.rows = rows or 25
    o.rmempty = true
    o.wrap = "off"

    function o.cfgvalue(self, section)
        return fs.readfile(config_file) or ""
    end

    function o.write(self, section, value)
        value = value:gsub("\r\n?", "\n")
        fs.writefile(config_file, value)
    end

    local d = s:option(DummyValue, "")
    d.template = "honk/honk_editor"
end

return M

