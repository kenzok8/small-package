#
# Copyright (C) 2006-2023 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=msd_lite
PKG_RELEASE:=1

PKG_SOURCE_PROTO:=git
PKG_SOURCE_DATE:=2025-05-02
PKG_SOURCE_URL:=https://github.com/rozhuk-im/msd_lite.git
PKG_SOURCE_VERSION:=79a6c62c8fced6128a5e445ee110709b3b51bb78
PKG_MIRROR_HASH:=bda05ff715a405939e14af1cddb5a892c8f85565942eeff079b613cb38827343

PKG_LICENSE:=BSD-2-Clause
PKG_LICENSE_FILES:=LICENSE

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/cmake.mk

define Package/msd_lite
  SECTION:=net
  CATEGORY:=Network
  TITLE:=Program for IP TV streaming on the network via HTTP
  URL:=https://netlab.dhis.org/wiki/software:msd:lite
  DEPENDS:= +libpthread
endef

define Package/msd_lite/description
  msd_lite - Multi stream daemon lite. This lightweight version of 
  Multi Stream daemon (msd) Program for organizing IP TV streaming 
  on the network via HTTP.
endef

define Package/msd_lite/conffiles
/etc/msd_lite/msd_lite.conf
endef

CMAKE_OPTIONS += \
	-DCONFDIR=/etc/msd_lite

define Package/msd_lite/install
	$(INSTALL_DIR) $(1)/etc/msd_lite $(1)/usr/bin
	$(INSTALL_CONF) $(PKG_BUILD_DIR)/conf/msd_lite.conf $(1)/etc/msd_lite/
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/bin/msd_lite $(1)/usr/bin/
endef

$(eval $(call BuildPackage,msd_lite))
