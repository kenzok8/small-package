--- a/luci-app-cifs/luasrc/model/cbi/cifs.lua
+++ b/luci-app-cifs/luasrc/model/cbi/cifs.lua
@@ -7,7 +7,7 @@ local fs = require "nixio.fs"
 m = Map("cifs", translate("Mounting NAT drives"))
 m.description = translate("Allows you mounting Nat drives")
 
-m:section(SimpleSection).template  = "cifs/cifs_status"
+m:section(SimpleSection).template  = "cifs_status"
 
 s = m:section(TypedSection, "cifs", "Cifs")
 s.anonymous = true
 
