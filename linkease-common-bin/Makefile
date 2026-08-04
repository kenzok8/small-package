#
# Copyright (C) 2015-2016 OpenWrt.org
# Copyright (C) 2020 jjm2473@gmail.com
#
# This is free software, licensed under the GNU General Public License v3.
#

include $(TOPDIR)/rules.mk

PKG_ARCH_LINKEASE:=$(ARCH)

PKG_NAME:=linkease-common-bin
PKG_SOURCE_DATE:=1.7.5
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
PKG_SOURCE:=linkease-binary-$(PKG_SOURCE_DATE).tar.gz
PKG_SOURCE_URL:=https://dl.istoreos.com/binary/LinkEase/LinuxStorage/
PKG_HASH:=f3ae319974d940f5741cd9fbd295a3a378164e7df82665defa99935608fe733a
PKG_BUILD_DIR:=$(BUILD_DIR)/linkease-binary-$(PKG_SOURCE_DATE)

PKG_BUILD_PARALLEL:=1
PKG_USE_MIPS16:=0

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	SECTION:=net
	CATEGORY:=Network
	SUBMENU:=Web Servers/Proxies
	TITLE:=LinkEase common binary tools
	DEPENDS:=@(arm||x86_64||aarch64)
	PKGARCH:=all
	URL:=https://www.linkease.com/
endef

define Package/$(PKG_NAME)/description
  Common LinkEase binary tools shared by LinkEase editions.
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/heif-converter.$(PKG_ARCH_LINKEASE) $(1)/usr/sbin/heif-converter
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/linkease-media.$(PKG_ARCH_LINKEASE) $(1)/usr/sbin/linkease-media
	$(INSTALL_BIN) ./files/linkease-config.sh $(1)/usr/sbin/linkease-config.sh
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
