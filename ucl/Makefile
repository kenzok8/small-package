#
# Copyright (C) 2019-2020 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#
include $(TOPDIR)/rules.mk

PKG_NAME:=ucl
PKG_VERSION:=1.04.2
PKG_RELEASE:=1

PKG_MAINTAINER:=Xingwang Liao <kuoruan@gmail.com>
PKG_LICENSE:=GPL-2.0-only
PKG_LICENSE_FILES:=COPYING

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://codeload.github.com/kenzok8/ucl/tar.gz/v$(PKG_VERSION)?
PKG_HASH:=ff65f04942e901d29d5237464d4706dc2a0cf66573a603c70345f4b1668b9708

PKG_BUILD_PARALLEL:=1
PKG_INSTALL:=1

HOST_BUILD_PARALLEL:=1

include $(INCLUDE_DIR)/host-build.mk
include $(INCLUDE_DIR)/package.mk

HOST_BUILD_PREFIX:=$(STAGING_DIR_HOST)

HOST_CFLAGS += -std=gnu89
TARGET_CFLAGS += -std=gnu89

CONFIGURE_ARGS += \
	--enable-static \
	--enable-shared \
	--disable-asm

define Package/libucl
  SECTION:=libs
  CATEGORY:=Libraries
  TITLE:=Portable lossless data compression library
  URL:=https://github.com/kenzok8/ucl
endef

define Package/libucl/description
UCL is a portable lossless data compression library written in ANSI C. UCL
implements a number of compression algorithms that achieve an excellent
compression ratio while allowing *very* fast decompression. Decompression
requires no additional memory.
endef

define Build/InstallDev
	$(INSTALL_DIR) $(1)/usr/include/ucl
	$(CP) $(PKG_INSTALL_DIR)/usr/include/ucl/ucl{,conf}.h $(1)/usr/include/ucl/

	$(INSTALL_DIR) $(1)/usr/lib
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/libucl.{a,so*} $(1)/usr/lib/
endef

define Package/libucl/install
	$(INSTALL_DIR) $(1)/usr/lib
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/libucl.so.* $(1)/usr/lib/
endef

$(eval $(call HostBuild))
$(eval $(call BuildPackage,libucl))
