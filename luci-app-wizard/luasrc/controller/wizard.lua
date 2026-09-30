module("luci.controller.wizard", package.seeall)

local http = require "luci.http"

function index()
    entry({"admin", "index"}, call("landing_page"), _("Home"), 0).dependent = false

    -- 直接改写 admin 根节点的调度目标
    local admin = node("admin")
    if admin then
        admin.target = call("landing_page")
    end
end

local function check_wifi(uci)
    local has_wifi = false
    pcall(function()
        uci:foreach("wireless", "wifi-device", function(s)
            has_wifi = true
            return false -- 检测到任意 wifi-device 即终止遍历
        end)
    end)
    return has_wifi
end

local function is_running(proc)
    return luci.sys.call(string.format("pgrep %s >/dev/null", proc)) == 0
end

function landing_page()
    local uci = luci.model.uci.cursor()
    local page = uci:get("wizard", "default", "landing_page")
    local target = {"admin", "status", "overview"}

    -- 1. 默认/自动模式
    if not page or page == "auto" then
        if is_running("quickstart") then
            target = {"admin", "quickstart"}
        elseif check_wifi(uci) then
            target = {"admin", "status", "dashboard"}
        end

    -- 2. 常规指定页面
    elseif page == "overview" then
        target = {"admin", "status", "overview"}
    elseif page == "dashboard" then
        target = {"admin", "status", "dashboard"}

    -- 3. Routerdog 模式（优先比对字符串，命中再检测进程）
    elseif page == "routerdog" and is_running("routergo") then
        target = {"admin", "routerdog"}

    -- 4. iStoreOS / iStoreX 增强页面（仅在 quickstart 运行时有效）
    elseif is_running("quickstart") then
        local istore_routes = {
            istoreos   = {"admin", "quickstart"},
            nas        = {"admin", "istorex", "nas"},
            ["next-nas"] = {"admin", "istorex", "next-nas"},
            router     = {"admin", "istorex", "router"}
        }
        if istore_routes[page] then
            target = istore_routes[page]
        end
    end

    http.redirect(luci.dispatcher.build_url(unpack(target)))
end
