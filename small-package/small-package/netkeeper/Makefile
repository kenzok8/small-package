# Copyright (C) 2019 CCnut
#
# This is free software, licensed under the GNU General Public License v2.
#
include $(TOPDIR)/rules.mk

PKG_NAME:=netkeeper
PKG_RELEASE:=2
PKG_VERSION:=3

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/netkeeper
	SECTION:=utils
	CATEGORY:=Utilities
	TITLE:=Netkeeper
	DEPENDS:=+ppp-mod-pppoe
endef

PPPD_VER := $(shell grep 'PKG_RELEASE_VERSION:=' $(TOPDIR)/package/network/services/ppp/Makefile | awk -F'=' '{print $$2}')

TARGET_CFLAGS += -fPIC -DPPPOE_VER='\"$(PPPD_VER)\"'
TARGET_CFLAGS += -isystem $(PKG_BUILD_DIR)/missing-headers

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)/missing-headers/net
	
	$(CP) ./src/* $(PKG_BUILD_DIR)/
	$(CP) ./files/ppp_defs.h $(PKG_BUILD_DIR)/missing-headers/net/
endef

define Package/netkeeper/install
	$(INSTALL_DIR) $(1)/usr/lib/pppd/$(PPPD_VER)
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/builds/*.so $(1)/usr/lib/pppd/$(PPPD_VER)
	$(INSTALL_DIR) $(1)/lib/netifd/proto
	$(INSTALL_BIN) ./files/netkeeper.sh $(1)/lib/netifd/proto/
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
