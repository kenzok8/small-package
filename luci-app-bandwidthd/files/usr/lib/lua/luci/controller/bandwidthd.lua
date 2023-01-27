module("luci.controller.bandwidthd", package.seeall)
function index()
        if not nixio.fs.access("/etc/config/bandwidthd") then
                return
        end
        entry({"admin", "network", "bandwidthd"}, cbi("bandwidthd"), _("Bandwidthd")).dependent = true
end