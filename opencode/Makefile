#
# Copyright (C) 2015-2016 OpenWrt.org
# Copyright (C) 2020 jjm2473@gmail.com
#
# This is free software, licensed under the GNU General Public License v3.
#

include $(TOPDIR)/rules.mk

PKG_ARCH_opencode:=$(ARCH)

PKG_NAME:=opencode
PKG_VERSION:=1.0.119
PKG_RELEASE:=3
PKG_SOURCE:=opencode-binary-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://github.com/Carseason/openwrt-packages/releases/download/prebuilt/
PKG_HASH:=0f57205d24428d3fddf2d7a6b0958901c7930ca8dd7ec706ed7903901b67ec3a
PKG_BUILD_DIR:=$(BUILD_DIR)/opencode-binary-$(PKG_VERSION)

PKG_BUILD_PARALLEL:=1
PKG_USE_MIPS16:=0

RSTRIP:=:
STRIP:=:

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	SECTION:=net
	CATEGORY:=System
	SUBMENU:=
	TITLE:=OpenCode
	DEPENDS:=+libstdcpp
	URL:=https://github.com/Carseason/openwrt-packages
endef

define Package/$(PKG_NAME)/description
  OpenCode
endef

define Package/$(PKG_NAME)/postinst
endef

define Build/Configure
endef

define Build/Compile
	$(STAGING_DIR_HOST)/bin/patchelf --remove-needed libc.musl-x86_64.so.1 --remove-needed libc.musl-aarch64.so.1 $(PKG_BUILD_DIR)/opencode.$(PKG_ARCH_opencode)
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/opencode.$(PKG_ARCH_opencode) $(1)/usr/sbin/opencode
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
