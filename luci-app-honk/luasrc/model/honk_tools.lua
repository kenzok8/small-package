local fs = require "nixio.fs"

local M = {}

function M.init_editor(m, current_page)
    local cbi = luci.cbi
    local translate = luci.i18n.translate

    m:section(cbi.SimpleSection).template = "honk/honk_status"

    local s = m:section(cbi.TypedSection, "honk")
    s.addremove = false
    s.anonymous = true

    local o = s:option(cbi.Button, "_reload", translate("Reload Service"), translate("Reload service to apply configuration."))
    o.inputstyle = "reload"
    o.write = function()
        local dsp = require "luci.dispatcher"
        local sys = require "luci.sys"
        sys.call("/etc/init.d/honk hot_reload >/dev/null 2>&1 &")
        luci.http.redirect(dsp.build_url("admin", "services", "honk", current_page) .. "?reload=1")
    end

    return s
end

function M.add_editor(s, config_file, option_name, title, description, rows)
    local cbi = luci.cbi
    local o = s:option(cbi.TextValue, option_name, title, description)
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

    local d = s:option(cbi.DummyValue, "")
    d.template = "honk/honk_editor"
end

function M.strip_dae_comments(content)
    if not content then return "" end
    local lines = {}
    for line in content:gmatch("[^\r\n]+") do
        local in_single = false
        local in_double = false
        local clean_line = ""
        local i = 1
        local len = #line
        while i <= len do
            local c = line:sub(i, i)
            local next_c = line:sub(i + 1, i + 1)
            if c == "'" and not in_double then
                in_single = not in_single
                clean_line = clean_line .. c
            elseif c == '"' and not in_single then
                in_double = not in_double
                clean_line = clean_line .. c
            elseif not in_single and not in_double then
                if c == "#" or (c == "/" and next_c == "/") then
                    break
                else
                    clean_line = clean_line .. c
                end
            else
                clean_line = clean_line .. c
            end
            i = i + 1
        end
        if clean_line:match("%S") then
            table.insert(lines, clean_line)
        end
    end
    return table.concat(lines, "\n")
end

function M.get_config_file_path()
    local uci = require "luci.model.uci".cursor()
    local config_file = uci:get("honk", "config", "config_file")
    if not config_file or config_file == "" then
        config_file = "/etc/honk/config.dae"
    end
    return config_file
end

function M.get_clash_api_config()
    local config_file = M.get_config_file_path()
    local content = fs.readfile(config_file) or ""
    local clean_content = M.strip_dae_comments(content)

    local res = {
        configured = false,
        has_ui = false,
        running = false,
        config_file = config_file,
        external_controller = "",
        host = "",
        port = "",
        secret = "",
        external_ui = "",
        default_mode = "Rule"
    }

    local sys = require "luci.sys"
    local pids = sys.exec("pidof honk-core 2>/dev/null") or ""
    local pid = pids:match("(%d+)") or ""
    res.running = (pid ~= "")

    local api_block = clean_content:match("clash_api%s*{(.-)}")
    if not api_block then
        return res
    end

    local ec = api_block:match("external_controller%s*:%s*['\"]?([^'\"%s\r\n]+)['\"]?")
    local ui = api_block:match("external_ui%s*:%s*['\"]?([^'\"%s\r\n]+)['\"]?")
    local sec = api_block:match("secret%s*:%s*['\"]?([^'\"%s\r\n]*)['\"]?")
    local dm = api_block:match("default_mode%s*:%s*['\"]?([^'\"%s\r\n]*)['\"]?")

    if ec and ec ~= "" then
        res.external_controller = ec
        local h, p
        if ec:match("^%[([^%]]+)%]:(%d+)$") then
            h, p = ec:match("^%[([^%]]+)%]:(%d+)$")
        elseif ec:match("^([^:]+):(%d+)$") then
            h, p = ec:match("^([^:]+):(%d+)$")
        elseif ec:match("^:(%d+)$") then
            h = "0.0.0.0"
            p = ec:match("^:(%d+)$")
        elseif ec:match("^%d+$") then
            h = "0.0.0.0"
            p = ec
        end
        res.host = h or "0.0.0.0"
        res.port = p or "9090"
        res.configured = true
    end

    if ui and ui ~= "" then
        res.external_ui = ui
    else
        res.external_ui = "/etc/honk/zashboard"
    end

    if sec then
        res.secret = sec
    end

    if dm and dm ~= "" then
        res.default_mode = dm
    end

    if res.external_ui ~= "" and fs.access(res.external_ui .. "/index.html") then
        res.has_ui = true
    end

    return res
end

function M.enable_default_clash_api()
    local config_file = M.get_config_file_path()
    local content = fs.readfile(config_file) or ""

    -- Extract existing settings (even from commented-out lines) to preserve user secret/ports
    local secret = content:match("[#%s]*secret%s*:%s*['\"]([^'\"]*)['\"]") or ""
    local ctrl = content:match("[#%s]*external_controller%s*:%s*['\"]([^'\"]*)['\"]") or "0.0.0.0:9090"
    local ui = content:match("[#%s]*external_ui%s*:%s*['\"]([^'\"]*)['\"]") or "/etc/honk/zashboard"
    local dm = content:match("[#%s]*default_mode%s*:%s*['\"]?([^'\"%s\r\n]+)['\"]?") or "Rule"

    local clean = M.strip_dae_comments(content)
    if clean:match("clash_api%s*{") then
        -- Already configured. Clean up any duplicate experimental blocks if present
        local fixed_content = content:gsub("experimental%s*{%s*#clash_api%s*{.-#%s*}%s*}%s*experimental%s*{", "experimental {")
        if fixed_content ~= content then
            fs.writefile(config_file, fixed_content)
        end
        luci.sys.call("/etc/init.d/honk restart >/dev/null 2>&1 &")
        return true, "Already configured"
    end

    local clash_snippet = string.format([[    clash_api {
        external_controller: '%s'
        external_ui: '%s'
        secret: '%s'
        default_mode: '%s'
    }]], ctrl, ui, secret, dm)

    local new_content = content

    -- Clean up duplicate experimental blocks if existing commented block precedes active one
    new_content = new_content:gsub("experimental%s*{%s*#clash_api%s*{.-#%s*}%s*}%s*experimental%s*{", "experimental {")

    -- Case 1: Existing commented-out clash_api block inside or outside experimental
    if new_content:match("#%s*clash_api%s*{") then
        new_content = new_content:gsub("#%s*clash_api%s*{.-#%s*}", clash_snippet, 1)
    -- Case 2: Existing experimental block (insert clash_api into it directly)
    elseif new_content:match("experimental%s*{") then
        new_content = new_content:gsub("experimental%s*{", "experimental {\n" .. clash_snippet, 1)
    -- Case 3: No experimental block at all
    else
        local full_snippet = string.format("\nexperimental {\n%s\n}\n", clash_snippet)
        new_content = new_content .. full_snippet
    end

    fs.writefile(config_file, new_content)
    -- Must restart honk service so it initializes the Clash API listener!
    luci.sys.call("/etc/init.d/honk restart >/dev/null 2>&1 &")
    return true
end

return M

