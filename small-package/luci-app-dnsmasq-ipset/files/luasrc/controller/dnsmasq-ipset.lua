
-- Auther Qier LU <lvqier@gmail.com>

module("luci.controller.dnsmasq-ipset", package.seeall)

function index()
    if not nixio.fs.access("/etc/config/dnsmasq-ipset") then
        return
    end

    entry({"admin", "services", "dnsmasq-ipset"}, view("dnsmasq-ipset"), _("DNSmasq IP-Set"), 60).dependent = true
end
