include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-autoshell
PKG_VERSION:=1.2.3
PKG_RELEASE:=1

PKG_MAINTAINER:=Brukamen <169296793@qq.com>
PKG_LICENSE:=GPL-3.0-or-later

include $(INCLUDE_DIR)/package.mk

define Package/luci-app-autoshell
  SECTION:=luci
  CATEGORY:=LuCI
  SUBMENU:=3. Applications
  TITLE:=LuCI support for autoshell
  DEPENDS:=+curl
endef

define Build/Prepare
endef

define Build/Compile
endef

define Package/luci-app-autoshell/install
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_DATA) ./autoshell $(1)/etc/config/

	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/controller
	$(INSTALL_DATA) ./controller/autoshell.lua $(1)/usr/lib/lua/luci/controller/

	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/model/cbi/
	$(INSTALL_DATA) ./cbi/autoshell.lua $(1)/usr/lib/lua/luci/model/cbi/
	$(INSTALL_DATA) ./cbi/autoshell_log.lua $(1)/usr/lib/lua/luci/model/cbi/
	
	$(INSTALL_DIR) $(1)/etc/init.d/
	$(foreach file,$(wildcard ./init.d/*), \
		$(INSTALL_BIN) $(file) $(1)/etc/init.d/$(notdir $(file)); \
	)

	$(INSTALL_DIR) $(1)/etc
	$(INSTALL_BIN) ./etc/autoshells.sh $(1)/etc/
	chmod +x $(1)/etc/autoshells.sh
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
