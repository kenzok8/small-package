module("luci.controller.nekobox", package.seeall)
function index()
entry({"admin","services","nekobox"}, template("nekobox"), _("Nekobox"), 1).leaf=true
end
