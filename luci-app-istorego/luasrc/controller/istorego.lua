local http = require "luci.http"

module("luci.controller.istorego", package.seeall)

function index()
    if nixio.fs.access("/usr/lib/lua/luci/view/istorego/main.htm") then
        entry({"admin", "istorego"}, call("istorego_index"), _("iStoreGo"), 32).leaf = true
    end
    entry({"admin", "istorego_api", "containers"}, call("istorego_api_containers"))
    entry({"admin", "istorego_api", "images"}, call("istorego_api_images"))
    entry({"admin", "istorego_api", "install"}, call("istorego_api_install"))
    entry({"admin", "istorego_api", "uninstall"}, call("istorego_api_uninstall"))
    entry({"admin", "istorego_api", "restart"}, call("istorego_api_restar"))
    entry({"admin", "istorego_api", "start"}, call("istorego_api_start"))
    entry({"admin", "istorego_api", "stop"}, call("istorego_api_stop"))
    entry({"admin", "istorego_api", "pull"}, call("istorego_api_pull"))
    entry({"admin", "istorego_api", "logs"}, call("istorego_api_logs"))
end

function istorego_index()
    luci.template.render("istorego/main", {
        prefix=luci.dispatcher.build_url(unpack({"admin", "istorego"}))
    })
end

function istorego_api_images()
    local http = require "luci.http"
    http.prepare_content("application/json")
	local method = http.getenv("REQUEST_METHOD")
    local result;
    result  = luci.util.exec("docker images --format '{{json . }}'") 
    local response = {
            success = 0,
            result = result,
    } 
    luci.http.write_json(response)
end

function istorego_api_containers()
    local http = require "luci.http"
    http.prepare_content("application/json")
	local method = http.getenv("REQUEST_METHOD")
    local result;
    -- 展示全部容器，需要在前端格式化
    -- 当监测到 Name 为 iStore_xxx 的则认为是 我们创建的插件
    result  = luci.util.exec("docker ps -a --format '{{json . }}'") 
    local response = {
            success = 0,
            result = result,
    } 
    luci.http.write_json(response)
end


local function is_exec(cmd, async)
    local nixio = require "nixio"
    local os   = require "os"
    local fs   = require "nixio.fs"
    local rshift  = nixio.bit.rshift

    local oflags = nixio.open_flags("wronly", "creat")
    local lock, code, msg = nixio.open("/var/lock/istorego.lock", oflags)
    if not lock then
        return 255, "", "Open lock failed: " .. msg
    end

    -- Acquire lock
    local stat, code, msg = lock:lock("tlock")
    if not stat then
        lock:close()
        return 255, "", "Lock failed: " .. msg
    end

    if async then
        cmd = "/etc/init.d/tasks task_add istorego " .. luci.util.shellquote(cmd)
    end
    local r = os.execute(cmd .. " >/var/log/istorego.stdout 2>/var/log/istorego.stderr")
    local e = fs.readfile("/var/log/istorego.stderr")
    local o = fs.readfile("/var/log/istorego.stdout")

    fs.unlink("/var/log/istorego.stderr")
    fs.unlink("/var/log/istorego.stdout")

    lock:lock("ulock")
    lock:close()

    e = e or ""
    if r == 256 and e == "" then
        e = "os.execute exit code 1"
    end
    return rshift(r,8), o or "", e or ""
end

function istorego_api_install()
    local http = require "luci.http"
    http.prepare_content("application/json")
	local method = http.getenv("REQUEST_METHOD")
    local result = "";
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
        if req.name == nil then
            luci.http.write_json({
				error =  "not found name"
			})
			return 
        end
        if req.cmds == nil then
            luci.http.write_json({
				error =  "not found cmds"
			})
			return 
        end
        -- 
        local cmds = "docker run -d --name=iStore_"..req.name .. " ".. table.concat(req.cmds, " ")
        result = cmds
        local r,o,e = is_exec(cmds, true)
        if  r ~= 0 then
            luci.http.write_json({
                success = -1,
				error =  e,
			})
			return 
        end
    end
    local response = {
        success = 0,
        result = luci.util.shellquote(result),
    } 
    luci.http.write_json(response)
end

function istorego_api_uninstall()
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
        -- 卸载插件
        if req.id ~= nil then
            local force = "";
            -- 强制删除
            if req.force ~= nil and req.force == true then
                force = "-f "
            end
            local r,o,e = is_exec("docker rm "..force..req.id, true) 
            if  r ~= 0 then
                luci.http.write_json({
                    error =  e,
                })
                return 
            end
        end
    end
    local response = {
        success = 0,
    } 
    luci.http.write_json(response)
end

function istorego_api_start()
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
        -- 启动插件
        if req.id ~= nil then
            local r,o,e = is_exec("docker start "..req.id, true)
            if  r ~= 0 then
                luci.http.write_json({
                    error =  e,
                })
                return 
            end
        end
    end
    local response = {
        success = 0,
    } 
    luci.http.write_json(response)
end

function istorego_api_restart()
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
        -- 启动插件
        if req.id ~= nil then
            local r,o,e = is_exec("docker restart "..req.id, true)
            if  r ~= 0 then
                luci.http.write_json({
                    error =  e,
                })
                return 
            end
        end
    end
    local response = {
        success = 0,
    } 
    luci.http.write_json(response)
end

function istorego_api_stop()
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
        -- 停止插件
        if req.id ~= nil then
            local r,o,e = is_exec("docker stop "..req.id, true)
            if  r ~= 0 then
                luci.http.write_json({
                    error =  e,
                })
                return 
            end
        end
    end
    local response = {
        success = 0,
    } 
    luci.http.write_json(response)
end

function istorego_api_logs()
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
        if req.id ~= nil then
            local r,o,e = is_exec("docker logs "..req.id, true)
            if  r ~= 0 then
                luci.http.write_json({
                    error =  e,
                })
                return 
            end
        end
    end
    local response = {
        success = 0,
    } 
    luci.http.write_json(response)
end

function istorego_api_pull()
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
        if req.image ~= nil then
            local r,o,e = is_exec("docker pull "..req.image, true)
            if  r ~= 0 then
                luci.http.write_json({
                    error =  e,
                })
                return 
            end
        end
    end
    local response = {
        success = 0,
    } 
    luci.http.write_json(response)
end