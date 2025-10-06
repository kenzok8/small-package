m = Map("nvr", translate("The luci-app for instead of network video recorder hardware."))

m:section(SimpleSection).template  = "nvr_status"

s = m:section(TypedSection, "nvr", "", translate("Network Video Recorder"))
s.anonymous = true
s.addremove = false

s:tab("nvr", translate("Basic setting"))
enabled = s:taboption("nvr", Flag, "enabled", translate("Record daemon"))
enabled.rmempty = false

nvr_sourcelist = s:taboption("nvr", ListValue, "nvr_sourcelist", translate("camera source"))
nvr_sourcelist.placeholder = "none"
nvr_sourcelist:value("none")
nvr_sourcelist:value("hikvision",translate("hikvision"))
nvr_sourcelist:value("tplink",translate("tplink"))
nvr_sourcelist:value("rtmp-url",translate("rtmp url"))
nvr_sourcelist:value("multiple-types",translate("multiple types"))
nvr_sourcelist.default = "none"
nvr_sourcelist.rmempty  = true

hik_list = s:taboption("nvr", ListValue, "hik_list", translate("camera list"))
hik_list:depends( "nvr_sourcelist", "hikvision" )
hik_list.placeholder = "none"
hik_list:value("none")
hik_list:value("one-by-one",translate("one by one"))
hik_list:value("batch-add",translate("batch add"))
hik_list.default = "none"
hik_list.rmempty  = true

hik_addonebyone = s:taboption("nvr", DynamicList, "hikpush")
hik_addonebyone:depends( "hik_list", "one-by-one" )
hik_addonebyone.title = translate("camera ip address")
hik_addonebyone.datatype = "ipaddr"
hik_addonebyone.placeholder = "192.168.1.64"
hik_addonebyone.description = translate("click + to continue")

hik_batch_start=s:taboption("nvr", Value, "hik_batch_start", translate("start of the ip address"))
hik_batch_start:depends( "hik_list", "batch-add" )
hik_batch_start.datatype = "ipaddr"
hik_batch_start.placeholder = "192.168.1.64"
hik_batch_start.rmempty = true

hik_batch_end=s:taboption("nvr", Value, "hik_batch_end", translate("end of the ip address"))
hik_batch_end:depends( "hik_list", "batch-add" )
hik_batch_end.datatype = "ipaddr"
hik_batch_end.placeholder = "192.168.1.200"
hik_batch_end.rmempty = true

hik_user=s:taboption("nvr", Value, "hik_user", translate("camera username"))
hik_user:depends( "nvr_sourcelist", "hikvision" ) 
hik_user.datatype = "string"                                                      
hik_user.placeholder = "username"                                   
hik_user.rmempty = true

hik_pass=s:taboption("nvr", Value, "hik_pass", translate("camera password"))
hik_pass:depends( "nvr_sourcelist", "hikvision" )                                     
hik_pass.datatype = "string"                                                          
hik_pass.placeholder = "password"                                                           
hik_pass.rmempty = true 

tplink_list = s:taboption("nvr", ListValue, "tplink_list", translate("camera list"))
tplink_list:depends( "nvr_sourcelist", "tplink" )
tplink_list.placeholder = "none"
tplink_list:value("none")
tplink_list:value("one-by-one",translate("one by one"))
tplink_list:value("batch-add",translate("batch add"))
tplink_list.default = "none"
tplink_list.rmempty  = true

tplink_addonebyone = s:taboption("nvr", DynamicList, "tplinkpush")
tplink_addonebyone:depends( "tplink_list", "one-by-one" )
tplink_addonebyone.title = translate("camera ip address")
tplink_addonebyone.datatype = "ipaddr"
tplink_addonebyone.placeholder = "192.168.1.60"
tplink_addonebyone.description = translate("click + to continue")

tplink_batch_start=s:taboption("nvr", Value, "tplink_batch_start", translate("start of the ip address"))
tplink_batch_start:depends( "tplink_list", "batch-add" )
tplink_batch_start.datatype = "ipaddr"
tplink_batch_start.placeholder = "192.168.1.60"
tplink_batch_start.rmempty = true

tplink_batch_end=s:taboption("nvr", Value, "tplink_batch_end", translate("end of the ip address"))
tplink_batch_end:depends( "tplink_list", "batch-add" )
tplink_batch_end.datatype = "ipaddr"
tplink_batch_end.placeholder = "192.168.1.200"
tplink_batch_end.rmempty = true

tplink_user=s:taboption("nvr", Value, "tplink_user", translate("camera username"))
tplink_user:depends( "nvr_sourcelist", "tplink" ) 
tplink_user.datatype = "string"                                                      
tplink_user.placeholder = "username"                                   
tplink_user.rmempty = true

tplink_pass=s:taboption("nvr", Value, "tplink_pass", translate("camera password"))
tplink_pass:depends( "nvr_sourcelist", "tplink" )                                     
tplink_pass.datatype = "string"                                                          
tplink_pass.placeholder = "password"                                                           
tplink_pass.rmempty = true 

rtmpurl_add = s:taboption("nvr", DynamicList, "rtmppush")
rtmpurl_add:depends( "nvr_sourcelist", "rtmp-url" )
rtmpurl_add.title = translate("rtmp url address")
rtmpurl_add.datatype = "string"
rtmpurl_add.placeholder = "rtmp://ip:1935/live/camera001"
rtmpurl_add.description = translate("adding one by one")

multi_info1 = s:taboption("nvr", DummyValue, "multi_info1", translate("information"))
multi_info1:depends( "nvr_sourcelist", "multiple-types" )
multi_info1.description = translate("hikvision: rtsp://username:password@ip:554/h264/ch1/main/av_stream")
multi_info2 = s:taboption("nvr", DummyValue, "multi_info2", translate("information"))
multi_info2:depends( "nvr_sourcelist", "multiple-types" )
multi_info2.description = translate("tplink: rtsp://username:password@ip:554/stream1")

multi_add = s:taboption("nvr", DynamicList, "multipush")
multi_add:depends( "nvr_sourcelist", "multiple-types" )
multi_add.title = translate("rtsp/rtmp/http url address")
multi_add.datatype = "string"
multi_add.placeholder = "rtmp://ip:1935/live/camera001"
multi_add.description = translate("adding one by one")

storage_directory=s:taboption("nvr", Value, "storage_directory", translate("data storage directory"))
storage_directory.rmempty = false
storage_directory.datatype = "string"
storage_directory.placeholder = "/mnt/sda1/camera"
storage_directory.default = "/mnt/sda1/camera"

disk_name=s:taboption("nvr", Value, "disk_name", translate("storage disk name"))
disk_name.rmempty = false
disk_name.datatype = "string"
disk_name.placeholder = "sda1"

disk_usage=s:taboption("nvr", Value, "disk_usage", translate("set maximum disk space usage"))
disk_usage.rmempty = false
disk_usage.datatype = "string"
disk_usage.placeholder = "85%"

rec_time=s:taboption("nvr", Value, "rec_time", translate("single file duration"))
rec_time.rmempty = false
rec_time.datatype = "uinteger"
rec_time.placeholder = "300"
rec_time.default = "300"
rec_time.description = translate("in seconds")

storage_size=s:taboption("nvr", Value, "storage_size", translate("allocate total storage space"))
storage_size.rmempty = false
storage_size.datatype = "uinteger"
storage_size.placeholder = "1000"
storage_size.default = "1000"
storage_size.description = translate("in megabytes")

total_days=s:taboption("nvr", Value, "total_days", translate("total days of videos"))
total_days.rmempty = false
total_days.datatype = "uinteger"
total_days.placeholder = "30"
total_days.default = "30"

loop_write=s:taboption("nvr", Flag, "loop_write", translate("looping writting to disk"))
loop_write.rmempty = false

fulldisk=s:taboption("nvr", Flag, "fulldisk", translate("only detect disk space"))
fulldisk.rmempty = false

enable_audio=s:taboption("nvr", Flag, "enable_audio", translate("enable audio"))
enable_audio.rmempty = false

do_push=s:taboption("nvr", Flag, "do_push", translate("whether to push stream"))

rtmp_server_app=s:taboption("nvr", Value, "rtmp_server_app", translate("rtmp server application url"))
rtmp_server_app:depends( "do_push", "1" )
rtmp_server_app.rmempty = true
rtmp_server_app.datatype = "string"
rtmp_server_app.placeholder = "rtmp://ip:1935/application_name"

s:tab("action", translate("Action"))

recordaction=s:taboption("action", Button, "recoredaction", translate("One-click Record"))
recordaction.rmempty = true
recordaction.inputstyle = "apply"                
function recordaction.write(self, section)                                                                        
	luci.util.exec("/usr/nvr/nvrstart 2>&1 &")                                          
end  

recordstop=s:taboption("action", Button, "recordstop", translate("One-click STOP Record"))
recordstop.rmempty = true
recordstop.inputstyle = "apply"
function recordstop.write(self, section)
	luci.util.exec("/usr/nvr/nvrstop 2>&1 & ")
end

pushaction=s:taboption("action", Button, "pushaction", translate("One-click Push stream"))
pushaction:depends( "do_push", "1" )
pushaction.rmempty = true
pushaction.inputstyle = "apply"
function pushaction.write(self, section)
	luci.util.exec("/usr/nvr/nvrpush >/dev/null 2>&1 &")
end

pushstop = s:taboption("action", Button, "pushstop", translate("One-click STOP Push"))
pushstop:depends( "do_push", "1" )
pushstop.rmempty = true
pushstop.inputstyle = "apply"
function pushstop.write(self, section)
	luci.util.exec("kill -9 $(ps -w | grep 'f flv rtmp' | grep -v grep | awk '{print$1}' 2>&1 &)")
end

return m
