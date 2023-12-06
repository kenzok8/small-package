module("luci.controller.ua2f", package.seeall)

function index()
    entry({"admin", "services", "ua2f"}, cbi("ua2f"), "UA2F", 99)
end
