#
# Copyright (C) 2026 jjm2473@gmail.com
#
# This is free software, licensed under the GNU General Public License v3.
#

include $(TOPDIR)/rules.mk

PKG_ARCH_BAIDUSDK:=$(ARCH)

PKG_NAME:=baidusdk
PKG_VERSION:=1.0.3
PKG_RELEASE:=
PKG_SOURCE:=$(PKG_NAME)-binary-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://github.com/linkease/istore-packages/releases/download/baidudrive/
PKG_HASH:=skip
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-binary-$(PKG_VERSION)

PKG_BUILD_PARALLEL:=1
PKG_USE_MIPS16:=0
STRIP:=true
RSTRIP:=:

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	SECTION:=net
	CATEGORY:=Network
	SUBMENU:=Web Servers/Proxies
	TITLE:=Baidu NAS SDK runtime
	DEPENDS:=@(x86_64||aarch64)
	URL:=https://github.com/linkease/istore-packages
endef

define Package/$(PKG_NAME)/description
  Baidu NAS SDK runtime files used by BaiduDrive.
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/lib/baidusdk
	$(CP) $(PKG_BUILD_DIR)/$(PKG_ARCH_BAIDUSDK)/usr/lib/baidusdk/. $(1)/usr/lib/baidusdk/
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
