
module("luci.controller.istorex", package.seeall)
local page_index = {"admin", "istorex","pages"}
function index()
    if luci.sys.call("pgrep quickstart >/dev/null") == 0 then
        entry({"admin", "istorex"}, template("istorex/index")).leaf = true
        if nixio.fs.access("/usr/lib/lua/luci/view/istorex/main_dev.htm") then
            entry({"admin", "istorex_dev"}, call("istorex_template_dev")).leaf = true
        end
    else
        entry({"admin", "istorex"}, call("redirect_fallback")).leaf = true
    end
end

function istorex_template()
    luci.template.render("istorex/main", {
        prefix=luci.dispatcher.build_url(unpack(page_index))
    })
end

function istorex_template_dev()
    luci.template.render("istorex/main_dev",{
        prefix=luci.dispatcher.build_url(unpack({"admin", "istorex_dev"}))
    })
end

function redirect_index()
    luci.http.redirect(luci.dispatcher.build_url(unpack(page_index)))
end

function redirect_fallback()
    luci.http.redirect(luci.dispatcher.build_url("admin","status"))
end
