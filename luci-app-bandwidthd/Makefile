include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-bandwidthd
PKG_VERSION=1
PKG_RELEASE:=1
PKG_MAINTAINER:=Alex Zhuo <1886090@gmail.com>

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	CATEGORY:=Network
	SUBMENU:=Luci
	PKGARCH:=all
	TITLE:=luci for bandwidthd
	DEPENDS:=+bandwidthd
endef

define Package/$(PKG_NAME)/description
    A luci app for bandwidthd
endef

define Package/$(PKG_NAME)/postinst
#!/bin/sh
rm -rf /tmp/luci*

endef

define Build/Prepare
	$(foreach po,$(wildcard ${CURDIR}/i18n/zh-cn/*.po), \
		po2lmo $(po) $(PKG_BUILD_DIR)/$(patsubst %.po,%.lmo,$(notdir $(po)));)
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/i18n
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/*.*.lmo $(1)/usr/lib/lua/luci/i18n/
	$(CP) ./files/* $(1)/

endef

$(eval $(call BuildPackage,$(PKG_NAME)))
