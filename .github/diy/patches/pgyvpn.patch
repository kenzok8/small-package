--- a/pgyvpn/Makefile
+++ b/pgyvpn/Makefile
@@ -78,7 +78,7 @@ define Package/pgyvpn/install
 	$(INSTALL_DIR) $(1)/usr/sbin
 	$(INSTALL_DIR) $(1)/usr/share/pgyvpn
 
-	$(CP) $(PKG_BUILD_DIR)/{pgyvpn_oraysl,pgyvpnsvr} $(1)/usr/sbin
+	$(CP) $(PKG_BUILD_DIR)/pgyvpn_oraysl $(1)/usr/sbin
 	$(INSTALL_BIN) ./files/etc/init.d/* $(1)/etc/init.d
 	$(INSTALL_CONF) ./files/etc/config/* $(1)/etc/config
 	$(INSTALL_BIN) ./files/etc/hotplug.d/iface/* $(1)/etc/hotplug.d/iface
