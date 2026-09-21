module("luci.controller.wizard", package.seeall)

local uci = luci.model.uci.cursor()
local http = require "luci.http"

function index()
    entry({"admin", "index"}, call("landing_page"), _("Home") , 0).dependent = false

    -- 2. 核心：直接改写 admin 根节点的调度目标
    -- 这样当用户访问 /admin、登录后跳转或访问根目录时，无需经过 firstchild()，直接执行 landing_page()
    local admin = node("admin")
    if admin then
        admin.target = call("landing_page")
    end
end

local function check_wifi()
    local has_wifi = false
    pcall(function()
        uci:foreach("wireless", "wifi-device", function(s)
            has_wifi = true
            return false -- 检测到任意 wifi-device 即终止遍历
        end)
    end)
    return has_wifi
end

function landing_page()
	local landing_page = uci:get("wizard", "default", "landing_page")
	if (luci.sys.call("pgrep routergo >/dev/null") == 0 and landing_page == "routerdog") then
		http.redirect(luci.dispatcher.build_url("admin","routerdog"));
	elseif luci.sys.call("pgrep quickstart >/dev/null") == 0 then
		if landing_page == "nas" then
			http.redirect(luci.dispatcher.build_url("admin","istorex","nas"));
		elseif landing_page == "next-nas" then
			http.redirect(luci.dispatcher.build_url("admin","istorex","next-nas"));
		elseif landing_page == "router" then
			http.redirect(luci.dispatcher.build_url("admin","istorex","router"));
		else
			http.redirect(luci.dispatcher.build_url("admin","quickstart"));
		end
	else
        if check_wifi() then
            -- 具备无线功能，跳转至常用无线仪表盘界面
            http.redirect(luci.dispatcher.build_url("admin", "dashboard"))
        else
            -- 无无线设备（纯有线环境），跳转至原生状态概览
            http.redirect(luci.dispatcher.build_url("admin", "status", "overview"))
        end
    end
		
end
