
module("luci.controller.poweroffdevice", package.seeall)


function index() 
        entry({"admin","system","poweroffdevice"},, template("poweroffdevice/poweroffdevice"), _("PowerOff"), 92)
	entry({"admin","system","poweroffdevice","call"},post("action_poweroff"))
end

function action_poweroff()
      luci.sys.exec("/sbin/poweroff" )

end
