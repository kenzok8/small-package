
module("luci.controller.istorex", package.seeall)
local page_index = {"admin", "istorex","pages"}
function index()
    if luci.sys.call("pgrep quickstart >/dev/null") == 0 then
        entry({"admin", "istorex"}, call("redirect_index"))
        entry({"admin", "istorex", "pages"}, call("istorex_template")).leaf = true
    else
        entry({"admin", "istorex"})
        entry({"admin", "istorex", "pages"}, call("redirect_fallback")).leaf = true
    end
end

function istorex_template()
    luci.template.render("istorex/main", {
        prefix=luci.dispatcher.build_url(unpack(page_index))
    })
end

function redirect_index()
    luci.http.redirect(luci.dispatcher.build_url(unpack(page_index)))
end

function redirect_fallback()
    luci.http.redirect(luci.dispatcher.build_url("admin","status"))
end