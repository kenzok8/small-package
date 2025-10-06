# SPDX-License-Identifier: GPL-2.0-only
#
# Copyright (C) 2025 ImmortalWrt.org

include $(TOPDIR)/rules.mk

PKG_NAME:=pcat-mgr
PKG_RELEASE:=1

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://gitlab.com/CoiaPrant/pcat-mgr.git
PKG_SOURCE_DATE:=2025-08-01
PKG_SOURCE_VERSION:=754b4f0b783a44d48d91e2dbd6c1dfca667a3049
PKG_MIRROR_HASH:=04f610b2dd55a7f355752c46c61fe6d8e25c643f146c8cfb503c75d8d2505df7

PKG_LICENSE:=GPL-3.0-or-later
PKG_LICENSE_FILES:=LICENSE
PKG_MAINTAINER:=Tianling Shen <cnsztl@immortalwrt.org>

PKG_FLAGS:=nonshared
PKG_BUILD_DEPENDS:=golang/host
PKG_BUILD_PARALLEL:=1
PKG_BUILD_FLAGS:=no-mips16

GO_PKG:=pcat-mgr

include $(INCLUDE_DIR)/package.mk
include $(TOPDIR)/feeds/packages/lang/golang/golang-package.mk

define Package/pcat-mgr
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=Photonicat Manager (Go Edition)
  URL:=https://gitlab.com/CoiaPrant/pcat-mgr
  DEPENDS:=$(GO_ARCH_DEPENDS) @TARGET_rockchip_armv8 +fuse-utils
  CONFLICTS:=pcat-manager
endef

define Package/pcat-mgr/install
	$(call GoPackage/Package/Install/Bin,$(PKG_INSTALL_DIR))
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/bin/pcat-mgr $(1)/usr/sbin/pcat-mgr

	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/pcat-mgr.init $(1)/etc/init.d/pcat-mgr
endef

$(eval $(call GoBinPackage,pcat-mgr))
$(eval $(call BuildPackage,pcat-mgr))
