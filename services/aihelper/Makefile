#
# Copyright (C) 2015-2016 OpenWrt.org
# Copyright (C) 2020 jjm2473@gmail.com
#
# This is free software, licensed under the GNU General Public License v3.
#

include $(TOPDIR)/rules.mk

PKG_ARCH_aihelper:=$(ARCH)

PKG_NAME:=aihelper
PKG_VERSION:=0.0.1
PKG_RELEASE:=2
PKG_SOURCE:=$(PKG_NAME)-binary-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://github.com/Carseason/openwrt-packages/releases/download/prebuilt/
PKG_HASH:=ac0f198049f3a9c0483c88d5bd48531b3ca0d85a7320291e94d7054afd4ea412
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-binary-$(PKG_VERSION)

PKG_BUILD_PARALLEL:=1
PKG_USE_MIPS16:=0

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	SECTION:=net
	CATEGORY:=System
	SUBMENU:=
	TITLE:=AiHelper
	URL:=https://github.com/Carseason/openwrt-packages
endef

define Package/$(PKG_NAME)/description
  AiHelper is a dashboard & user guide
endef

define Package/$(PKG_NAME)/conffiles
/etc/config/aihelper
endef

define Package/$(PKG_NAME)/postinst
#!/bin/sh
if [ -z "$${IPKG_INSTROOT}" ]; then
	if [ -f /etc/uci-defaults/09-aihelper ]; then
		chmod 755 /etc/uci-defaults/09-aihelper
		/etc/uci-defaults/09-aihelper && rm -f /etc/uci-defaults/09-aihelper
	fi
fi
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/sbin $(1)/etc/init.d $(1)/etc/uci-defaults $(1)/etc/config
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/aihelper.$(PKG_ARCH_aihelper) $(1)/usr/sbin/aihelper
	$(INSTALL_BIN) ./files/aihelper.init $(1)/etc/init.d/aihelper
	$(INSTALL_BIN) ./files/aihelper.uci-default $(1)/etc/uci-defaults/09-aihelper
	$(INSTALL_CONF) ./files/aihelper.config $(1)/etc/config/aihelper
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
