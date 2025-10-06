#
# Copyright (C) 2015 OVH
# Copyright (C) 2018-2025 Ycarus (Yannick Chabanois) <ycarus@zugaina.org> for OpenMPTCProuter project
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/ysurac/glorytun.git
PKG_SOURCE_VERSION:=203c5f2223d7d5146d659b51159b2f02c2480d15
PKG_NAME:=glorytun-udp
PKG_VERSION:=0.3.4
PKG_RELEASE:=25
PKG_LICENSE:=BSD-2-Clause
PKG_LICENSE_FILES:=LICENSE

#PKG_FIXUP:=autoreconf

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
SECTION:=net
CATEGORY:=Network
DEPENDS:=+kmod-tun +libsodium +librt
TITLE:=Glorytun
URL:=https://github.com/angt/glorytun
SUBMENU:=VPN
endef

#TARGET_CFLAGS += -std=c99 -D_GNU_SOURCE -DGT_RUNDIR=\"\\\"/tmp\"\\\"
TARGET_CFLAGS += -DGT_RUNDIR=\"\\\"/tmp\"\\\"

define Package/$(PKG_NAME)/conffiles
/etc/config/glorytun
endef

define Build/Prepare
	$(call Build/Prepare/Default)
	echo "$(PKG_VERSION)" > $(PKG_BUILD_DIR)/VERSION
endef

define Build/Configure
	cd $(PKG_BUILD_DIR); \
	    $(AM_TOOL_PATHS) ./bootstrap.sh
	$(call Build/Configure/Default)
endef

#define Build/Configure
#	( cd $(PKG_BUILD_DIR); autoupdate; aclocal; libtoolize; autoreconf; );
#	$(call Build/Configure/Default)
#endef



define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/glorytun $(1)/usr/sbin/$(PKG_NAME)
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) init $(1)/etc/init.d/$(PKG_NAME)
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_DATA) glorytun-udp.config $(1)/etc/config/glorytun-udp
endef

$(eval $(call BuildPackage,$(PKG_NAME)))

