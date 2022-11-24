
module("luci.controller.unishare", package.seeall)

function index()
	if not nixio.fs.access("/etc/config/unishare") then
		return
	end

	entry({"admin", "nas", "unishare"}, alias("admin", "nas", "unishare", "index"), _("UniShare"), 2).dependent = true
	entry({"admin", "nas", "unishare", "index"}, cbi("unishare/index"), _("UniShare"), 1)
	entry({"admin", "nas", "unishare", "users"}, cbi("unishare/users"), _("Users"), 2)
	entry({"admin", "nas", "unishare", "share"}, cbi("unishare/share", {hideapplybtn=true})).leaf = true
end
