include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-xray-status
PKG_VERSION:=3.4.1
PKG_RELEASE:=1

PKG_LICENSE:=MPLv2
PKG_LICENSE_FILES:=LICENSE
PKG_MAINTAINER:=yichya <mail@yichya.dev>
PKG_BUILD_PARALLEL:=1

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	SECTION:=Custom
	CATEGORY:=Extra packages
	TITLE:=LuCI Support for Xray (status page)
	DEPENDS:=luci-app-xray +wget
	PKGARCH:=all
endef

define Package/$(PKG_NAME)/description
	LuCI Support for Xray (Client-side Rendered) (status page).
endef

define Build/Compile
	echo "luci-app-xray $(PKG_VERSION)-$(PKG_RELEASE) `git rev-parse HEAD` `date +%s`" > $(PKG_BUILD_DIR)/version.txt
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/www/luci-static/resources/view/xray
	$(INSTALL_DATA) ./root/www/luci-static/resources/view/xray/status.js $(1)/www/luci-static/resources/view/xray/status.js
	$(INSTALL_DIR) $(1)/usr/share/luci/menu.d
	$(INSTALL_DATA) ./root/usr/share/luci/menu.d/luci-app-xray-status.json $(1)/usr/share/luci/menu.d/luci-app-xray-status.json
	$(INSTALL_DIR) $(1)/usr/share/rpcd/acl.d
	$(INSTALL_DATA) ./root/usr/share/rpcd/acl.d/luci-app-xray-status.json $(1)/usr/share/rpcd/acl.d/luci-app-xray-status.json
	$(INSTALL_DIR) $(1)/usr/share/xray
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/version.txt $(1)/usr/share/xray/version.txt
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
