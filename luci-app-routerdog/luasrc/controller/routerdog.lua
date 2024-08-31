module("luci.controller.routerdog", package.seeall)

function index()
    if nixio.fs.access("/usr/lib/lua/luci/view/routerdog/main.htm") then
        entry({"admin", "routerdog"}, template("routerdog/index"), _("RouterDog"), 1).leaf = true
    end
    entry({"admin", "routerdog_api"}, call("redirect_index"))
    entry({"admin", "routerdog_api", "status"}, call("routerdog_api_status"))
    entry({"admin", "routerdog_api", "upload-bg"}, call("routerdog_api_uploadbg"))
    entry({"admin", "routerdog_api", "setting"}, call("routerdog_api_setting"))
    entry({"admin", "routerdog_api", "routergo"}, call("routerdog_api_routergo"))
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
        prefix=luci.dispatcher.build_url(unpack({"admin", "routerdog"})),
        id=user_id(),
    }
    return data
end

function redirect_index()
    luci.http.redirect(luci.dispatcher.build_url("admin/routerdog"))
end

function routerdog_template()
    luci.template.render("routerdog/main", get_params())
end


function routerdog_api_status()
    local success = 0
    local response = {
        success = success,
    }
    luci.http.prepare_content("application/json")
    luci.http.write_json(response)
end
function routerdog_api_uploadbg()
    local uci = require "uci"
    local x = uci.cursor()
    local fd
    local path
    local success = 0
    local tmpdir = "/www/luci-static/routerdog/image"
    local filename = ""
    
    local opf = io.open(tmpdir,"r+")
    if opf then 
       opf:close()
    else
        local sys  = require "luci.sys"
        sys.exec("mkdir "..tmpdir)
    end

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
    local response = {
        success = success,
    }
    luci.http.prepare_content("application/json")
    luci.http.write_json(response)
end

function getRouterdogSettingData()
    local uci  = require "luci.model.uci".cursor()
    local bgBlur   = uci:get_first("routerdog", "routerdog", "bgBlur")
    local hiddenApp   = uci:get_first("routerdog", "routerdog", "hiddenApp")
    local hiddenDockerApp   = uci:get_first("routerdog", "routerdog", "hiddenDockerApp")
    local hiddenUseApp   = uci:get_first("routerdog", "routerdog", "hiddenUseApp")
    local result = {
        bgBlur    = (bgBlur == "1"),
        hiddenApp = (hiddenApp == "1"),
        hiddenDockerApp = (hiddenDockerApp == "1"),
        hiddenUseApp = (hiddenUseApp == "1"),
    }
    return result
end
function submitRouterdogSettingData(req)
    local uci = require "luci.model.uci".cursor()
    if req.bgBlur ~= nil then
        uci:set("routerdog","@routerdog[0]","bgBlur",req.bgBlur)
    end
    if req.hiddenApp ~= nil then
        uci:set("routerdog","@routerdog[0]","hiddenApp",req.hiddenApp)
    end
    if req.hiddenUseApp ~= nil then
        uci:set("routerdog","@routerdog[0]","hiddenUseApp",req.hiddenUseApp)
    end
     if req.hiddenDockerApp ~= nil then
        uci:set("routerdog","@routerdog[0]","hiddenDockerApp",req.hiddenDockerApp)
    end
    uci:commit("routerdog")  
end
function routerdog_api_setting()
    local http = require "luci.http"
	http.prepare_content("application/json")
	local method = http.getenv("REQUEST_METHOD")
	if method == "post" or method == "POST" then
        local content = http.content()
		local jsonc = require "luci.jsonc"
		local json_parse = jsonc.parse
		local req = json_parse(content)
		if req == nil or next(req) == nil then
			luci.http.write_json({
				error =  "invalid request"
			})
			return 
		end
        submitRouterdogSettingData(req)
    end
    local result = getRouterdogSettingData()
    local response = {
            success = 0,
            result = result,
    } 
    luci.http.write_json(response)
end


function routerdog_api_routergo()
    local http = require "luci.http"
    local uci = require "luci.model.uci".cursor()
	http.prepare_content("application/json")
	local method = http.getenv("REQUEST_METHOD")
	if method == "post" or method == "POST" then
        local content = http.content()
		local jsonc = require "luci.jsonc"
		local json_parse = jsonc.parse
		local req = json_parse(content)
		if req == nil or next(req) == nil then
			luci.http.write_json({
				error =  "invalid request"
			})
			return 
		end
        if req.path ~= nil then
            uci:set("routergo","@routergo[0]","path",req.path)
        end
        uci:commit("routergo") 
        luci.util.exec("/etc/init.d/routergo stop") 
        luci.util.exec("/etc/init.d/routergo start")
    end

    local path   = uci:get_first("routergo", "routergo", "path")
    local result = {
        path    = path,
    }
    local response = {
            success = 0,
            result = result,
    } 
    luci.http.write_json(response)
end