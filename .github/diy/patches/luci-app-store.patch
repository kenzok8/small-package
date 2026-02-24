--- a/luci-app-store/src/compat.conf
+++ b/luci-app-store/src/compat.conf
@@ -1 +1 @@
-src/gz istore_compat https://istore.istoreos.com/repo/all/compat
\ No newline at end of file
+# src/gz istore_compat https://istore.istoreos.com/repo/all/compat

--- a/luci-app-store/Makefile
+++ b/luci-app-store/Makefile
@@ -7,7 +7,7 @@ include $(TOPDIR)/rules.mk
 
 LUCI_TITLE:=LuCI based ipk store
 LUCI_DESCRIPTION:=luci-app-store is a ipk store developed by LinkEase team
-LUCI_DEPENDS:=+curl +opkg +luci-lib-ipkg +tar +libuci-lua +mount-utils +luci-lib-taskd
+LUCI_DEPENDS:=@(x86_64||aarch64) +curl +opkg +luci-lib-ipkg +tar +libuci-lua +mount-utils +luci-lib-taskd
 LUCI_EXTRA_DEPENDS:=luci-lib-taskd (>=1.0.19)
 LUCI_PKGARCH:=all
 

--- a/luci-app-store/luasrc/view/store/main.htm
+++ b/luci-app-store/luasrc/view/store/main.htm
@@ -26,6 +26,8 @@ <h2 name="content"><%:iStore%>
     <a onclick="void(0)" href="https://github.com/linkease/istore/issues/22" target="_blank" style="text-decoration: none;">
         v<%=id.version%>
     </a>
+	<br/>
+	<span style="font-weight:normal;font-size:70%; color:orangered">更多插件, 请使用 <a href="/cgi-bin/luci/admin/system/package-manager" style="text-decoration: none;">系统->软件包</a> </span>
 </h2>
 <link rel="stylesheet" href="/luci-static/istore/style.css?v=<%=id.version%>">
 <div id="app">
