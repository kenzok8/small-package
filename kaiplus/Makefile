#
# Copyright (C) 2026 KaiPlus Contributors
#
# This is free software, licensed under the GNU General Public License v3.
#

include $(TOPDIR)/rules.mk

PKG_ARCH_kaiplus:=$(ARCH)

PKG_NAME:=kaiplus
PKG_VERSION:=1.0.5
PKG_RELEASE:=1
PKG_SOURCE:=$(PKG_NAME)-binary-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://github.com/linkease/istore-packages/releases/download/kaiplus/
PKG_HASH:=58e480a191e8e3c08ed7814df368c79109d2def1fd1b0734d9054fd5b364ee99
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-binary-$(PKG_VERSION)

PKG_BUILD_PARALLEL:=1
PKG_USE_MIPS16:=0

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	SECTION:=net
	CATEGORY:=System
	SUBMENU:=
	TITLE:=KaiPlus
	URL:=https://github.com/linkease/istore-packages
endef

define Package/$(PKG_NAME)/description
  KaiPlus is a single-process AI workspace and session service.
endef

define Package/$(PKG_NAME)/conffiles
/etc/config/kaiplus
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/sbin $(1)/usr/share/kaiplus/www $(1)/usr/share/kaiplus/defaults $(1)/usr/share/kaiplus/helpers $(1)/etc/init.d $(1)/etc/config
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/kaiplus_bin.$(PKG_ARCH_kaiplus) $(1)/usr/sbin/kaiplus_bin
	$(CP) $(PKG_BUILD_DIR)/www/* $(1)/usr/share/kaiplus/www/
	$(CP) $(PKG_BUILD_DIR)/defaults/* $(1)/usr/share/kaiplus/defaults/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/helpers/kaiplus_workspace_tool.* $(1)/usr/share/kaiplus/helpers/
	$(INSTALL_BIN) ./files/kaiplus.init $(1)/etc/init.d/kaiplus
	$(INSTALL_CONF) ./files/kaiplus.config $(1)/etc/config/kaiplus
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
