local http = require "luci.http"

module("luci.controller.quickstart", package.seeall)

local page_index = {"admin", "quickstart", "pages"}

function index()
    if luci.sys.call("pgrep quickstart >/dev/null") == 0 then
        entry({"admin", "quickstart"}, call("redirect_index"), _("QuickStart"), 1)
        entry({"admin", "network_guide"}, call("networkguide_index"), _("NetworkGuide"), 2)
        entry({"admin", "quickstart", "pages"}, call("quickstart_index", {index={"admin", "quickstart", "pages"}})).leaf = true
        entry({"admin", "network_guide", "pages"}, call("quickstart_index", {index={"admin", "network_guide", "pages"}})).leaf = true
        if nixio.fs.access("/usr/lib/lua/luci/view/quickstart/main_dev.htm") then
            entry({"admin", "quickstart", "dev"}, call("quickstart_dev", {index={"admin", "quickstart", "dev"}})).leaf = true
            entry({"admin", "network_guide", "dev"}, call("quickstart_dev", {index={"admin", "network_guide", "dev"}})).leaf = true
        end
        entry({"admin", "nas", "raid"}, call("quickstart_index", {index={"admin", "nas"}}), _("RAID"), 10).leaf = true
    else
        entry({"admin", "quickstart"})
        entry({"admin", "quickstart", "pages"}, call("redirect_fallback")).leaf = true
    end
end

function networkguide_index()
    luci.http.redirect(luci.dispatcher.build_url("admin","network_guide","pages","network"))
end

function redirect_index()
    luci.http.redirect(luci.dispatcher.build_url(unpack(page_index)))
end

function redirect_fallback()
    luci.http.redirect(luci.dispatcher.build_url("admin","status"))
end

function quickstart_index(param)
    local jsonc = require "luci.jsonc"
    local features = { "_lua_force_array_" }
    if luci.sys.call("which ota >/dev/null 2>&1") == 0 then
        features[#features+1] = "ota"
    end
    if luci.sys.call("[ -d /ext_overlay ] >/dev/null 2>&1") == 0 then
        features[#features+1] = "sandbox"
    end
    luci.template.render("quickstart/main", {prefix=luci.dispatcher.build_url(unpack(param.index)),features=jsonc.stringify(features)})
end

function quickstart_dev(param)
    luci.template.render("quickstart/main_dev", {prefix=luci.dispatcher.build_url(unpack(param.index))})
end
