
module("luci.controller.istorerouter", package.seeall)

function index()
    if luci.sys.call("pgrep quickstart >/dev/null") == 0 then
        entry({"admin", "istorerouter"}, call("istorerouter_template")).leaf = true
        if nixio.fs.access("/usr/lib/lua/luci/view/istorerouter/main_dev.htm") then
            entry({"admin", "istorerouter_dev"}, call("istorerouter_template_dev")).leaf = true
        end
    else
        entry({"admin", "istorerouter"}, call("redirect_fallback")).leaf = true
    end
    entry({"admin", "istorerouter_api","status"}, call("istorerouter_api_status"))
    entry({"admin", "istorerouter_api","update"}, call("istorerouter_api_update"))
    entry({"admin", "istorerouter_api","upload-bg"}, call("istorerouter_api_uploadbg"))
end

local function user_id()
    local jsonc = require "luci.jsonc"
    local json_parse = jsonc.parse
    local fs   = require "nixio.fs"
	local data = fs.readfile("/etc/.app_store.id")

    local id
    if data ~= nil then
        id = json_parse(data)
    end
    if id == nil then
        fs.unlink("/etc/.app_store.id")
        id = {arch="",uid=""}
    end

    id.version = (fs.readfile("/etc/.app_store.version") or "?"):gsub("[\r\n]", "")

    return id
end

function get_config_data()
    local uci  = require "luci.model.uci".cursor()
    local model   = uci:get_first("istorerouter", "istorerouter", "model")
    local enabled = uci:get_first("istorerouter", "istorerouter", "enabled")
    local data = {
        model   = model,
        enabled = enabled,
    }
    return data
end

local function static_cache_tag()
    local fs = require "nixio.fs"
    local stat = fs.stat("/www/luci-static/istorerouter/index.js")
    return stat and stat.mtime or os.time()
end

function get_params()
    local config = get_config_data()
    local data = {
        prefix=luci.dispatcher.build_url(unpack({"admin", "istorerouter"})),
        id=user_id(),
        model = config.model,
        cache_tag = static_cache_tag(),
    }
    return data
end

function get_dev_params()
    local config = get_config_data()
    local data = {
        prefix=luci.dispatcher.build_url(unpack({"admin", "istorerouter_dev"})),
        id=user_id(),
        model = config.model,
        cache_tag = static_cache_tag(),
    }
    return data
end

function redirect_fallback()
    luci.http.redirect(luci.dispatcher.build_url("admin","status"))
end

function istorerouter_template()
    luci.template.render("istorerouter/main", get_params())
end

function istorerouter_template_dev()
    luci.template.render("istorerouter/main_dev", get_dev_params())
end

function istorerouter_api_status()
    local result = get_config_data()
    luci.http.prepare_content("application/json")
    luci.http.write_json({
         success = 0,
         result  = result,
    })
end

function istorerouter_api_update()
    local http = require "luci.http"
    local jsonc = require "luci.jsonc"
    local uci  = require "luci.model.uci".cursor()
    local content = http.content()
    local json_parse = jsonc.parse
    local req = json_parse(content)
    local data = {
    }
    if req == nil or next(req) == nil then
        data.error = "invalid request"
    else
        uci:set("istorerouter","@istorerouter[0]","model", req.model)
        uci:commit("istorerouter")
        data.success = 0
    end
    http.prepare_content("application/json")
    http.write_json(data)
end

function istorerouter_api_uploadbg()
    local uci = require "uci"
    local x = uci.cursor()
    local fd
    local path
    local finished = false
    local tmpdir = "/www/luci-static/istorerouter/image"
    local filename = ""
    luci.http.setfilehandler(
        function(meta, chunk, eof)
            if not fd then
                filename = meta.file
                path = tmpdir .. "/bg.gif" 
                fd = io.open(path, "w")
            end
            if chunk then
                fd:write(chunk)
            end
            if eof then
                fd:close()
                finished = true
            end
        end
    )
    luci.http.formvalue("file")
    local result = {
        filename = filename
    }
    local data = {
        success = finished,
        result  = result
    }
    luci.http.prepare_content("application/json")
    luci.http.write_json(data)
end
