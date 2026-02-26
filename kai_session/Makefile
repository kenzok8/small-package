#
# Copyright (C) 2015-2016 OpenWrt.org
# Copyright (C) 2020 jjm2473@gmail.com
#
# This is free software, licensed under the GNU General Public License v3.
#

include $(TOPDIR)/rules.mk

PKG_ARCH_kai_session:=$(ARCH)

PKG_NAME:=kai_session
PKG_VERSION:=0.0.3
PKG_RELEASE:=0
PKG_SOURCE:=$(PKG_NAME)-binary-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://github.com/linkease/istore-packages/releases/download/prebuilt/
PKG_HASH:=40b0fe38b90d3630b8e3cb945afbeed9e1466141b85d389a1afffc138a45eead
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-binary-$(PKG_VERSION)

PKG_BUILD_PARALLEL:=1
PKG_USE_MIPS16:=0

RSTRIP:=:
STRIP:=:

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	SECTION:=net
	CATEGORY:=System
	SUBMENU:=
	TITLE:=KAI_SESSION
	DEPENDS:=+libstdcpp
	URL:=https://github.com/Carseason/openwrt-packages
endef

define Package/$(PKG_NAME)/description
  KAI
endef

define Package/$(PKG_NAME)/conffiles
endef

define Package/$(PKG_NAME)/postinst
endef

define Build/Configure
endef

define Build/Compile
	$(STAGING_DIR_HOST)/bin/patchelf --remove-needed libc.musl-x86_64.so.1 --remove-needed libc.musl-aarch64.so.1 $(PKG_BUILD_DIR)/kai_session.$(PKG_ARCH_kai_session)
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/kai_session.$(PKG_ARCH_kai_session) $(1)/usr/sbin/kai_session
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
