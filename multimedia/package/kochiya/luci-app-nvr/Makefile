include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-nvr
PKG_VERSION:=20230818

include $(INCLUDE_DIR)/package.mk

define Package/luci-app-nvr
 	SECTION:=luci
	CATEGORY:=LuCI
	SUBMENU:=3. Applications
	TITLE:=LuCI Support for Network Video Recorder
	PKGARCH:=all
	DEPENDS:=+ffmpeg
endef

define Build/Prepare
	$(foreach po,$(wildcard ${CURDIR}/luasrc/i18n/*.po), \
		po2lmo $(po) $(PKG_BUILD_DIR)/$(patsubst %.po,%.lmo,$(notdir $(po)));)
endef

define Build/Compile
endef

define Package/luci-app-nvr/install
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci
	cp -pR ./luasrc/* $(1)/usr/lib/lua/luci
	$(INSTALL_DIR) $(1)/usr/nvr
	$(INSTALL_BIN) ./files/nvr/* $(1)/usr/nvr
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) ./files/nvr.conf $(1)/etc/config/nvr
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/nvr.init $(1)/etc/init.d/nvr
endef

$(eval $(call BuildPackage,luci-app-nvr))
