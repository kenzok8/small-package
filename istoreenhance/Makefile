#
# Copyright (C) 2015-2016 OpenWrt.org
# Copyright (C) 2020 jjm2473@gmail.com
#
# This is free software, licensed under the GNU General Public License v3.
#

include $(TOPDIR)/rules.mk

PKG_ARCH_ISTOREENHANCE:=$(ARCH)

PKG_NAME:=istoreenhance
# use PKG_SOURCE_DATE instead of PKG_VERSION for compitable
PKG_SOURCE_DATE:=0.7.16
PKG_RELEASE:=1
ARCH_HEXCODE:=
ifeq ($(ARCH),x86_64)
ARCH_HEXCODE=8664
else ifeq ($(ARCH),aarch64)
ARCH_HEXCODE=aa64
else ifeq ($(ARCH),arm)
ARCH_HEXCODE=aa32
else ifeq ($(ARCH),mipsel)
ARCH_HEXCODE=1b0c
endif
PKG_SOURCE_VERSION:=$(ARCH_HEXCODE)
PKG_SOURCE:=iStoreEnhance-binary-$(PKG_SOURCE_DATE).tar.gz
PKG_SOURCE_URL:=https://github.com/kspeeder/docker_kspeeder/releases/download/v$(PKG_SOURCE_DATE)/
PKG_HASH:=d6fffad59a2a496e64cfe4d883ec042daccb0a4b123c964cc3084860e98bf179

PKG_BUILD_DIR:=$(BUILD_DIR)/iStoreEnhance-binary-$(PKG_SOURCE_DATE)
KSPEEDER_WEB_ROOT:=$(PKG_BUILD_DIR)/wwwroot

PKG_BUILD_PARALLEL:=1
PKG_USE_MIPS16:=0

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	SECTION:=net
	CATEGORY:=Network
	SUBMENU:=Web Servers/Proxies
	TITLE:=iStoreEnhance - Fix some net issues for istore
	DEPENDS:=@(arm||x86_64||aarch64)
	PKGARCH:=all
	URL:=https://www.kspeeder.com/
endef

define Package/$(PKG_NAME)/description
  Fix some net issues for istore
endef

define Package/$(PKG_NAME)/conffiles
/etc/config/istoreenhance
endef

define Package/$(PKG_NAME)/postinst
#!/bin/sh
if [ -z "$${IPKG_INSTROOT}" ]; then
	[ -f /etc/uci-defaults/istoreenhance ] && /etc/uci-defaults/istoreenhance && rm -f /etc/uci-defaults/istoreenhance
	exit 0
fi
endef

define Package/$(PKG_NAME)/prerm
#!/bin/sh
if [ "$${IPKG_INSTROOT}" = "" ]; then
	if [ "$$(readlink /usr/share/linkeasefull/desktop-apps.d/20-kspeeder.json 2>/dev/null)" = "/usr/share/kspeeder/kspeeder-plugin.json" ]; then
		rm -f /usr/share/linkeasefull/desktop-apps.d/20-kspeeder.json
	fi
fi
exit 0
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/sbin $(1)/etc/config $(1)/etc/init.d $(1)/etc/uci-defaults $(1)/usr/share/kspeeder/www $(1)/usr/share/linkeasefull/desktop-apps.d
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/iStoreEnhance.$(PKG_ARCH_ISTOREENHANCE) $(1)/usr/sbin/iStoreEnhance
	$(INSTALL_CONF) ./files/istoreenhance.config $(1)/etc/config/istoreenhance
	$(INSTALL_BIN) ./files/istoreenhance.init $(1)/etc/init.d/istoreenhance
	$(INSTALL_BIN) ./files/istoreenhance.uci-default $(1)/etc/uci-defaults/istoreenhance
	$(INSTALL_DATA) ./files/kspeeder-plugin.json $(1)/usr/share/kspeeder/kspeeder-plugin.json
	if [ -d "$(KSPEEDER_WEB_ROOT)" ] && [ -f "$(KSPEEDER_WEB_ROOT)/desktop-entry.js" ]; then \
		$(CP) $(KSPEEDER_WEB_ROOT)/* $(1)/usr/share/kspeeder/www/; \
	else \
		$(INSTALL_DATA) ./files/www/desktop-entry.js $(1)/usr/share/kspeeder/www/desktop-entry.js; \
		$(INSTALL_DATA) ./files/www/index.html $(1)/usr/share/kspeeder/www/index.html; \
	fi
	$(INSTALL_DATA) ../app-meta-istoreenhance/logo.png $(1)/usr/share/kspeeder/www/logo.png
	ln -sf /usr/share/kspeeder/kspeeder-plugin.json $(1)/usr/share/linkeasefull/desktop-apps.d/20-kspeeder.json
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
