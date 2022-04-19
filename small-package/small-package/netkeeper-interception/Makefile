# Copyright (C) 2019 CCnut
#
# This is free software, licensed under the GNU General Public License v2.
#
include $(TOPDIR)/rules.mk

PKG_NAME:=netkeeper-interception
PKG_RELEASE:=1
PKG_VERSION:=0.2

include $(INCLUDE_DIR)/package.mk


define Package/netkeeper-interception
  SECTION:=net
  CATEGORY:=Network
  TITLE:=Netkeeper Account Dump Plugin
  DEPENDS:=ppp +rp-pppoe-server
endef

define Package/netkeeper-interception/conffiles
/etc/netkeeper-interception/pppoe-server-options
/etc/config/netkeeper-interception
endef

PPPD_VER := $(shell grep 'PKG_RELEASE_VERSION:=' $(TOPDIR)/package/network/services/ppp/Makefile | awk -F'=' '{print $$2}')

PLUGIN_PATH := "plugin /usr/lib/pppd/$(PPPD_VER)/netkeeper-interception-s.so"

TARGET_CFLAGS += -fPIC -DPPPOE_VER='\"$(PPPD_VER)\"'
TARGET_CFLAGS += -isystem $(PKG_BUILD_DIR)/missing-headers


define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)/missing-headers/net

	$(CP) ./src/* $(PKG_BUILD_DIR)/
	$(CP) ./files/ppp_defs.h $(PKG_BUILD_DIR)/missing-headers/net/
endef

define Package/netkeeper-interception/install
	$(INSTALL_DIR) $(1)/usr/lib/pppd/$(PPPD_VER)
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/builds/*.so $(1)/usr/lib/pppd/$(PPPD_VER)/
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/netkeeper-interception.init $(1)/etc/init.d/netkeeper-interception
	$(INSTALL_DIR) $(1)/etc/netkeeper-interception
	$(INSTALL_CONF) ./files/etc/netkeeper-interception/pppoe-server-options $(1)/etc/netkeeper-interception/pppoe-server-options
	$(shell) echo $(PLUGIN_PATH) >> $(1)/etc/netkeeper-interception/pppoe-server-options
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) ./files/etc/config/netkeeper-interception $(1)/etc/config/netkeeper-interception
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
