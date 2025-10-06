#
# Copyright (C) 2015 OVH
# Copyright (C) 2017-2025 Ycarus (Yannick Chabanois) <ycarus@zugaina.org>
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=glorytun
PKG_RELEASE:=10
PKG_SOURCE_PROTO:=git
PKG_SOURCE_VERSION:=95fa5ead2154adb546bcdb454c56c876e9f60bb5
PKG_SOURCE:=glorytun-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://github.com/Ysurac/glorytun.git
PKG_VERSION:=0.0.35
PKG_LICENSE:=BSD-2-Clause
PKG_LICENSE_FILES:=LICENSE

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
SECTION:=net
CATEGORY:=Network
DEPENDS:=+kmod-tun +libsodium +librt
TITLE:=Glorytun
URL:=https://github.com/angt/glorytun
SUBMENU:=VPN
endef

define Package/$(PKG_NAME)/description
 A small, simple and secure VPN
endef

# not everything groks --disable-nls
DISABLE_NLS:=
TARGET_CFLAGS += -std=c17 -D_GNU_SOURCE

define Package/$(PKG_NAME)/conffiles
/etc/config/glorytun
endef

define Build/Configure
	cd $(PKG_BUILD_DIR); \
		$(AM_TOOL_PATHS) ./bootstrap.sh
	$(call Build/Configure/Default)
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/glorytun $(1)/usr/sbin/$(PKG_NAME)
	$(INSTALL_BIN) files/glorytun-irq-affinity.sh $(1)/usr/sbin/glorytun-irq-affinity.sh
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) init $(1)/etc/init.d/$(PKG_NAME)
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_DATA) glorytun.config $(1)/etc/config/glorytun
	$(INSTALL_DIR) $(1)/etc/glorytun
	$(INSTALL_DATA) files/glorytun-sysctl.conf $(1)/etc/glorytun/glorytun-sysctl.conf
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
