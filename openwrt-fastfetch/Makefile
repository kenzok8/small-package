# SPDX-License-Identifier: MIT
#
# Copyright (C) 2025 Anya Lin <hukk1996@gmail.com>

include $(TOPDIR)/rules.mk

PKG_NAME:=fastfetch
PKG_VERSION:=2.56.0
PKG_RELEASE:=1

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://codeload.github.com/fastfetch-cli/fastfetch/tar.gz/$(PKG_VERSION)?
PKG_HASH:=8df6f21b168069dc35eb361eed47815650a5253f5e0f6948c5490faf375aad74

PKG_MAINTAINER:=Anya Lin <hukk1996@gmail.com>
PKG_LICENSE:=MIT
PKG_LICENSE_FILES:=LICENSE

PKG_BUILD_PARALLEL:=1
PKG_BUILD_FLAGS:=no-mips16

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/cmake.mk

define Package/fastfetch
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=Fetch and display system information
  URL:=https://github.com/fastfetch-cli/fastfetch
  DEPENDS+=
endef

define Package/fastfetch/description
  Fastfetch is a neofetch-like tool for fetching
  system information and displaying it prettily.
endef

define Package/fastfetch/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/fastfetch $(1)/usr/bin/
endef

$(eval $(call BuildPackage,fastfetch))
