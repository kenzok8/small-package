# SPDX-License-Identifier: GPL-3.0-only
#
# Copyright (C) 2021-2023 ImmortalWrt.org

include $(TOPDIR)/rules.mk

PKG_NAME:=brook
PKG_VERSION:=20250808
PKG_RELEASE:=1

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://codeload.github.com/txthinking/brook/tar.gz/v$(PKG_VERSION)?
PKG_HASH:=d78e8066ba5377c3841c8b6dcc6949cccbc04f3e475a3ac34587721438cde494

PKG_MAINTAINER:=Tianling Shen <cnsztl@immortalwrt.org>
PKG_LICENSE:=GPL-3.0
PKG_LICENSE_FILES:=LICENSE

PKG_BUILD_DEPENDS:=golang/host
PKG_BUILD_PARALLEL:=1
PKG_USE_MIPS16:=0
PKG_BUILD_FLAGS:=no-mips16

GO_PKG:=github.com/txthinking/brook
GO_PKG_BUILD_PKG:=$(GO_PKG)/cli/brook

include $(INCLUDE_DIR)/package.mk
include $(TOPDIR)/feeds/packages/lang/golang/golang-package.mk

define Package/brook
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=Web Servers/Proxies
  TITLE:=A cross-platform proxy software
  DEPENDS:=$(GO_ARCH_DEPENDS) +ca-bundle
  URL:=https://github.com/txthinking/brook
endef

define Package/brook/description
  Brook is a cross-platform strong encryption and not detectable proxy.
  Zero-Configuration.
endef

$(eval $(call GoBinPackage,brook))
$(eval $(call BuildPackage,brook))
