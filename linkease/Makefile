#
# Copyright (C) 2015-2016 OpenWrt.org
# Copyright (C) 2020 jjm2473@gmail.com
#
# This is free software, licensed under the GNU General Public License v3.
#

include $(TOPDIR)/rules.mk

PKG_ARCH_LINKEASE:=$(ARCH)

PKG_NAME:=linkease
# use PKG_SOURCE_DATE instead of PKG_VERSION for compitable
PKG_SOURCE_DATE:=1.7.7
PKG_RELEASE:=1

ARCH_HEXCODE:=
ifeq ($(ARCH),x86_64)
ARCH_HEXCODE=8664
PKG_HASH:=0f56ffca8039c268929c6f1a1032f023cb38bc9b47873b9e9f8304f90edaa7ae
else ifeq ($(ARCH),aarch64)
ARCH_HEXCODE=aa64
PKG_HASH:=2043801361c425e180e78eec4287444ef29cb7154e5f2664b69d87287786cbd2
else ifeq ($(ARCH),arm)
ARCH_HEXCODE=aa32
PKG_HASH:=a2eebc616210e0fcb2011bd91185d484dc91c707b8e49a024df0fcb147904e8b
else ifeq ($(ARCH),mipsel)
ARCH_HEXCODE=1b0c
endif

PKG_SOURCE_VERSION:=$(ARCH_HEXCODE)
PKG_SOURCE:=linkease-bin-$(PKG_SOURCE_DATE)-linux-$(PKG_ARCH_LINKEASE).tar.gz
PKG_SOURCE_URL:=https://github.com/istoreos/istoreos-app-hub/releases/download/linkease-runtime-v$(PKG_SOURCE_DATE)/
PKG_BUILD_DIR:=$(BUILD_DIR)/linkease-bin-$(PKG_SOURCE_DATE)-linux-$(PKG_ARCH_LINKEASE)

PKG_BUILD_PARALLEL:=1
PKG_USE_MIPS16:=0

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	SECTION:=net
	CATEGORY:=Network
	SUBMENU:=Web Servers/Proxies
	TITLE:=LinkEase - the file cloud
	DEPENDS:=@(arm||x86_64||aarch64) +linkease-common-bin
	EXTRA_DEPENDS:=linkease-common-bin (>=1.7.6~0)
	PKGARCH:=all
	URL:=https://www.linkease.com/
endef

define Package/$(PKG_NAME)/description
  LinkEase is a file cloud
endef

define Package/$(PKG_NAME)/conffiles
/etc/config/linkease
endef

define Package/$(PKG_NAME)/postinst
#!/bin/sh
if [ -z "$${IPKG_INSTROOT}" ]; then
	[ -f /etc/uci-defaults/linkease ] && /etc/uci-defaults/linkease && rm -f /etc/uci-defaults/linkease
	exit 0
fi
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/sbin/linkease-plugins $(1)/etc/config $(1)/etc/init.d $(1)/etc/uci-defaults
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/linkease $(1)/usr/sbin/linkease
	$(INSTALL_CONF) ./files/linkease.config $(1)/etc/config/linkease
	$(INSTALL_BIN) ./files/linkease.init $(1)/etc/init.d/linkease
	$(INSTALL_BIN) ./files/linkease.uci-default $(1)/etc/uci-defaults/linkease
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
