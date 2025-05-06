# SPDX-License-Identifier: GPL-3.0-only
#
# Copyright (C) 2022 ImmortalWrt.org

include $(TOPDIR)/rules.mk

PKG_NAME:=upx
PKG_VERSION:=5.0.1
PKG_RELEASE:=1

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION)-src.tar.xz
PKG_SOURCE_URL:=https://github.com/upx/upx/releases/download/v$(PKG_VERSION)
PKG_HASH:=2b11323a9f6c7f0247a4936deee35afb486a2fdf808a5bc4abf10a085ec884d9

PKG_LICENSE:=GPL-2.0-or-later
PKG_LICENSE_FILES:=COPYING LICENSE
PKG_MAINTAINER:=Tianling Shen <cnsztl@immortalwrt.org>

HOST_BUILD_DIR:=$(BUILD_DIR_HOST)/$(PKG_NAME)-$(PKG_VERSION)-src
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)-src
CMAKE_BINARY_SUBDIR:=openwrt-build

PKG_BUILD_FLAGS:=no-mips16

include $(INCLUDE_DIR)/host-build.mk
include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/cmake.mk

define Package/upx
  SECTION:=utils
  CATEGORY:=Utilities
  SUBMENU:=Compression
  TITLE:=The Ultimate Packer for eXecutables
  URL:=https://upx.github.io
  DEPENDS:=+libstdcpp
endef

CMAKE_OPTS:= \
	-DUPX_CONFIG_DISABLE_GITREV=ON \
	-DUPX_CONFIG_DISABLE_SELF_PACK_TEST=ON
CMAKE_HOST_OPTIONS+= $(CMAKE_OPTS)
CMAKE_OPTIONS+= $(CMAKE_OPTS)

define Package/upx/description
  UPX is an advanced executable file compressor. UPX will typically
  reduce the file size of programs and DLLs by around 50%-70%, thus
  reducing disk space, network load times, download times and
  other distribution and storage costs.
endef

define Package/upx/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/bin/upx $(1)/usr/bin/
endef

$(eval $(call HostBuild))
$(eval $(call BuildPackage,upx))
