include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-suselogin
PKG_VERSION=2.1
PKG_RELEASE:=5

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/luci-app-suselogin
	SECTION:=luci
	CATEGORY:=LuCI
	SUBMENU:=3. Applications
	TITLE:=SUSE Login for LuCI
	PKGARCH:=all
	DEPENDS:=+curl
endef

define Package/luci-app-suselogin/description
	SUSE Login for LuCI.
endef

define Build/Prepare
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/luci-app-suselogin/install
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/model/cbi
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/controller
	$(INSTALL_DIR) $(1)/etc/hotplug.d/iface
	$(INSTALL_DIR) $(1)/usr/lib/suselogin
	
	$(INSTALL_CONF) ./files/root/etc/config/suselogin $(1)/etc/config/suselogin
	$(INSTALL_BIN) ./files/root/etc/init.d/suselogin $(1)/etc/init.d/suselogin
	$(INSTALL_BIN) ./files/root/etc/hotplug.d/iface/100-suselogin $(1)/etc/hotplug.d/iface/100-suselogin
	$(INSTALL_BIN) ./login.sh $(1)/usr/lib/suselogin/login.sh

	$(INSTALL_DATA) ./files/root/usr/lib/lua/luci/controller/suselogin.lua $(1)/usr/lib/lua/luci/controller/suselogin.lua
	$(INSTALL_DATA) ./files/root/usr/lib/lua/luci/model/cbi/suselogin.lua $(1)/usr/lib/lua/luci/model/cbi/suselogin.lua
	$(INSTALL_DATA) ./files/root/usr/lib/lua/luci/model/cbi/suseloginlog.lua $(1)/usr/lib/lua/luci/model/cbi/suseloginlog.lua
endef

$(eval $(call BuildPackage,luci-app-suselogin))
