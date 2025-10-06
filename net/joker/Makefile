# SPDX-Identifier-License: GPL-3.0-only
#
# Copyright (C) 2021 ImmortalWrt.org

include $(TOPDIR)/rules.mk

PKG_NAME:=joker
PKG_VERSION:=20231110
PKG_RELEASE:=1

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://codeload.github.com/txthinking/joker/tar.gz/v$(PKG_VERSION)?
PKG_HASH:=2f11dff3114e1d22b77e810c1f5e33dd0198574bcef6f023caae74301e63a1ae

PKG_LICENSE:=GPL-3.0-only
PKG_LICENSE_FILES:=LICENSE
PKG_MAINTAINER:=Tianling Shen <cnsztl@immortalwrt.org>

include $(INCLUDE_DIR)/package.mk

define Package/joker
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=Run command as daemon
  URL:=https://github.com/txthinking/joker
  DEPENDS:=+libc
endef

define Package/joker/description
  Joker can turn process into daemon. Zero-Configuration.
endef

define Build/Compile
	$(TARGET_CC) $(TARGET_CFLAGS) $(TARGET_LDFLAGS) \
		$(PKG_BUILD_DIR)/{main,run}.c -o $(PKG_BUILD_DIR)/joker
endef

define Package/joker/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/joker $(1)/usr/bin/
endef
$(eval $(call BuildPackage,joker))
