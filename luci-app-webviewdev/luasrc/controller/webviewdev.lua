module("luci.controller.webviewdev", package.seeall)

function index()
    entry({"admin", "webviewdev"}, call("webviewdev_template"), _("webviewdev"), 5).leaf = true
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
function get_params()
    local data = {
        prefix=luci.dispatcher.build_url(unpack({"admin", "webviewdev"})),
        id=user_id(),
    }
    return data
end
function webviewdev_template()
    luci.template.render("webviewdev/main", get_params())
end
