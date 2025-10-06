m = Map("softethervpn", translate("SoftEther VPN"))
m.description = translate("SoftEther VPN is an open source, cross-platform, multi-protocol virtual private network solution developed by university of tsukuba graduate student Daiyuu Nobori for master's thesis. <br>can easily set up OpenVPN, IPsec, L2TP, ms-sstp, L2TPv3 and EtherIP servers on the router using the console.")
m.template = "softethervpn/index"

s = m:section(TypedSection, "softether")
s.anonymous = true

o = s:option(DummyValue, "softethervpn_status", translate("Current Condition"))
o.template = "softethervpn/status"
o.value = translate("Collecting data...")

o = s:option(Flag, "enabled", translate("Enabled"))
o.rmempty = false

o = s:option(DummyValue, "moreinfo", translate("Console download"))
o.rawhtml = true
o.cfgvalue = function(self, section)
    local obj = {
        {
            title = "Windows-x86_x64-intel.exe",
            url = "https://github.com/SoftEtherVPN/SoftEtherVPN_Stable/releases/download/v4.38-9760-rtm/softether-vpnserver_vpnbridge-v4.38-9760-rtm-2021.08.17-windows-x86_x64-intel.exe"
        },
        {
            title = "macos-x86-32bit.pkg",
            url = "https://www.softether-download.com/files/softether/v4.21-9613-beta-2016.04.24-tree/Mac_OS_X/Admin_Tools/VPN_Server_Manager_Package/softether-vpnserver_manager-v4.21-9613-beta-2016.04.24-macos-x86-32bit.pkg"
        }
    }

    local html = ""

    for i, o in ipairs(obj) do
        html = html .. string.format("<a href='%s'>%s &nbsp&nbsp", o.url, o.title)
    end

    return html
end
return m
