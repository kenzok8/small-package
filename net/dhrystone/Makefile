#
# Copyright (C) 2006-2009 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=dhrystone
PKG_VERSION:=2.1
PKG_RELEASE:=1

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/siasjack/dhrystone4OP.git
PKG_SOURCE_VERSION:=e9053fbb0ebd8ad2e60375639f93268dc259a995
PKG_MIRROR_HASH:=9bbaf8eb345f2973849ccc711d26ccd67d4129d3a1a7a5ce06575692c187f735

MAKE_PATH:=src

include $(INCLUDE_DIR)/package.mk

define Package/dhrystone
  SECTION:=utils
  CATEGORY:=Utilities
  URL:=https://github.com/siasjack/dhrystone4OP
  TITLE:=Dhrystone Benchmark Program
endef

define Package/dhrystone/description
  Dhrystone 2.1 Benchmark Program by Reinhold P. Weicker
endef

define Package/dhrystone/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/src/gcc_dry2 $(1)/usr/bin/dhrystone
endef

$(eval $(call BuildPackage,dhrystone))
