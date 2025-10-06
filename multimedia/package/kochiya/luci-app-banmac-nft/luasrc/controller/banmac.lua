module("luci.controller.banmac",package.seeall)

function index()
	local page = entry({"admin", "services", "banmac"}, cbi("banmac"), _("BanMac"),5)
	page.dependent = true
end

