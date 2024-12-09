#
# Copyright (C) 2024 jjm2473 <jjm2473@gmail.com>
#
# This is free software, licensed under the MIT License.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=floatip
PKG_VERSION:=1.0.8
PKG_RELEASE:=1
PKG_MAINTAINER:=jjm2473 <jjm2473@gmail.com>

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	SECTION:=net
	CATEGORY:=Network
	SUBMENU:=IP Addresses and Names
	TITLE:=Float IP
	DEPENDS:=+curl
	PKGARCH:=all
endef

define Package/$(PKG_NAME)/description
	Auto setup an IP if some host down
endef

define Package/$(PKG_NAME)/conffiles
/etc/config/floatip
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/libexec $(1)/etc/init.d $(1)/etc/config $(1)/etc/uci-defaults
	$(INSTALL_BIN) ./files/floatip.sh $(1)/usr/libexec/floatip.sh
	$(INSTALL_BIN) ./files/floatip.init $(1)/etc/init.d/floatip
	$(INSTALL_CONF) ./files/floatip.config $(1)/etc/config/floatip
	$(INSTALL_BIN) ./files/floatip.uci-default $(1)/etc/uci-defaults/floatip
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
