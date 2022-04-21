module("luci.controller.tencentddns",package.seeall)
function index()
entry({"admin", "tencentcloud"}, firstchild(), "腾讯云设置", 30).dependent=false
entry({"admin", "tencentcloud", "tencentddns"},cbi("tencentddns"),_("TencentDDNS"),2)
end
