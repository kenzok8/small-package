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
PKG_SOURCE_DATE:=0.5.0
PKG_RELEASE:=5
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
PKG_SOURCE_URL:=http://dl.istoreos.com/binary/iStoreEnhance/
PKG_HASH:=e871447d6522f27881a25b59fb44d3f1582af73b06803704e3cab43b456d8894

PKG_BUILD_DIR:=$(BUILD_DIR)/iStoreEnhance-binary-$(PKG_SOURCE_DATE)

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

define Build/Configure
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/sbin $(1)/etc/config $(1)/etc/init.d $(1)/etc/uci-defaults
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/iStoreEnhance.$(PKG_ARCH_ISTOREENHANCE) $(1)/usr/sbin/iStoreEnhance
	$(INSTALL_CONF) ./files/istoreenhance.config $(1)/etc/config/istoreenhance
	$(INSTALL_BIN) ./files/istoreenhance.init $(1)/etc/init.d/istoreenhance
	$(INSTALL_BIN) ./files/istoreenhance.uci-default $(1)/etc/uci-defaults/istoreenhance
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
