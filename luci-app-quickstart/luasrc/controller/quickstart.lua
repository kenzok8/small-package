local http = require "luci.http"

module("luci.controller.quickstart", package.seeall)

function index()
    if luci.sys.call("pgrep quickstart >/dev/null") == 0 then
        entry({"admin", "quickstart"}, template("quickstart/home"), _("QuickStart"), 1).leaf = true
        entry({"admin", "network_guide"}, call("networkguide_index"), _("NetworkGuide"), 2)
        entry({"admin", "network_guide", "pages"}, call("quickstart_index", {index={"admin", "network_guide", "pages"}})).leaf = true
        if nixio.fs.access("/usr/lib/lua/luci/view/quickstart/main_dev.htm") then
            entry({"admin", "quickstart_dev"}, call("quickstart_dev", {index={"admin", "quickstart_dev"}})).leaf = true
        end
        entry({"admin", "nas", "raid"}, call("quickstart_index", {index={"admin", "nas"}}), _("RAID"), 10).leaf = true
        entry({"admin", "nas", "smart"}, call("quickstart_index", {index={"admin", "nas"}}), _("S.M.A.R.T."), 11).leaf = true
    else
        entry({"admin", "quickstart"}, call("redirect_fallback")).leaf = true
    end
end

function networkguide_index()
    luci.http.redirect(luci.dispatcher.build_url("admin","network_guide","pages","network"))
end

function redirect_fallback()
    luci.http.redirect(luci.dispatcher.build_url("admin", "status"))
end

function quickstart_index(param)
    luci.template.render("quickstart/main", {prefix=luci.dispatcher.build_url(unpack(param.index))})
end

function quickstart_dev(param)
    luci.template.render("quickstart/main_dev", {prefix=luci.dispatcher.build_url(unpack(param.index))})
end
