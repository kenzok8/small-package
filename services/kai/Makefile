#
# Copyright (C) 2015-2016 OpenWrt.org
# Copyright (C) 2020 jjm2473@gmail.com
#
# This is free software, licensed under the GNU General Public License v3.
#

include $(TOPDIR)/rules.mk

PKG_ARCH_kai:=$(ARCH)

PKG_NAME:=kai
PKG_VERSION:=0.0.1
PKG_RELEASE:=2
PKG_SOURCE:=$(PKG_NAME)-binary-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://github.com/Carseason/openwrt-packages/releases/download/prebuilt/
PKG_HASH:=51b20a41da99dc1b6ab616e203cba824bf644699813316f858055fa6e1343860
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-binary-$(PKG_VERSION)

PKG_BUILD_PARALLEL:=1
PKG_USE_MIPS16:=0

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	SECTION:=net
	CATEGORY:=System
	SUBMENU:=
	TITLE:=KAI
	URL:=https://github.com/Carseason/openwrt-packages
endef

define Package/$(PKG_NAME)/description
  KAI is a dashboard & user guide
endef

define Package/$(PKG_NAME)/conffiles
/etc/config/kai
endef

define Package/$(PKG_NAME)/postinst
#!/bin/sh
if [ -z "$${IPKG_INSTROOT}" ]; then
	if [ -f /etc/uci-defaults/09-kai ]; then
		chmod 755 /etc/uci-defaults/09-kai
		/etc/uci-defaults/09-kai && rm -f /etc/uci-defaults/09-kai
	fi
fi
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/sbin $(1)/etc/init.d $(1)/etc/uci-defaults $(1)/etc/config
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/kai.$(PKG_ARCH_kai) $(1)/usr/sbin/kai_bin
	$(INSTALL_BIN) ./files/kai.init $(1)/etc/init.d/kai
	$(INSTALL_BIN) ./files/kai.uci-default $(1)/etc/uci-defaults/09-kai
	$(INSTALL_CONF) ./files/kai.config $(1)/etc/config/kai
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
