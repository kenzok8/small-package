module("luci.controller.wizard", package.seeall)

local uci = luci.model.uci.cursor()
local http = require "luci.http"

function index()
        entry({"admin", "index"}, call("landing_page"), _("Home") , 1).dependent = false
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
		http.redirect(luci.dispatcher.build_url("admin","status"))
	end
		
end
