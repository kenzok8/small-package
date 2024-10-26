module("luci.controller.neko", package.seeall)

function index()
    entry({"admin","services","neko"}, template("neko"), _("NekoBox"), 1).leaf=true
    entry({"admin", "services", "neko", "mon"}, template("neko_mon"), nil, 2).leaf = true
    entry({"admin", "services", "neko", "logs"}, call("render_logs"), nil, 3).leaf = true
    entry({"admin", "services", "neko", "fetch_plugin_log"}, call("fetch_plugin_log")).leaf = true
    entry({"admin", "services", "neko", "fetch_mihomo_log"}, call("fetch_mihomo_log")).leaf = true
    entry({"admin", "services", "neko", "fetch_singbox_log"}, call("fetch_singbox_log")).leaf = true
end

function render_logs()
    if luci.http.formvalue("clear_plugin_log") then
        luci.sys.exec("echo '' > /etc/neko/tmp/log.txt")
    elseif luci.http.formvalue("clear_mihomo_log") then
        luci.sys.exec("echo '' > /etc/neko/tmp/neko_log.txt")
    elseif luci.http.formvalue("clear_singbox_log") then
        luci.sys.exec("echo '' > /var/log/singbox_log.txt")
    end

    luci.template.render("neko_logs")
end

function fetch_plugin_log()
    luci.http.prepare_content("text/plain")
    luci.http.write(luci.sys.exec("cat /etc/neko/tmp/log.txt"))
end

function fetch_mihomo_log()
    luci.http.prepare_content("text/plain")
    luci.http.write(luci.sys.exec("cat /etc/neko/tmp/neko_log.txt"))
end

function fetch_singbox_log()
    luci.http.prepare_content("text/plain")
    luci.http.write(luci.sys.exec("cat /var/log/singbox_log.txt"))
end
