#
# Copyright (C) 2015-2016 OpenWrt.org
# Copyright (C) 2020 jjm2473@gmail.com
#
# This is free software, licensed under the GNU General Public License v3.
#

include $(TOPDIR)/rules.mk

PKG_ARCH_LINKEASE:=$(ARCH)

PKG_NAME:=linkease
PKG_VERSION:=1.6.8
PKG_RELEASE:=$(PKG_ARCH_LINKEASE)-2
PKG_SOURCE:=$(PKG_NAME)-binary-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=http://fw0.koolcenter.com/binary/LinkEase/LinuxStorage/
PKG_HASH:=3a014182bb29701d0ad3eacfcd0c23958d9f1a4e4e7390ec745d6a883498a2a8

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-binary-$(PKG_VERSION)

PKG_BUILD_PARALLEL:=1
PKG_USE_MIPS16:=0

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	SECTION:=net
	CATEGORY:=Network
	SUBMENU:=Web Servers/Proxies
	TITLE:=LinkEase - the file cloud
	DEPENDS:=@(arm||x86_64||aarch64) +linkmount
	PKGARCH:=all
	URL:=https://www.linkease.com/
endef

define Package/$(PKG_NAME)/description
  LinkEase is a file cloud
endef

define Package/$(PKG_NAME)/conffiles
/etc/config/linkease
endef

define Package/$(PKG_NAME)/postinst
#!/bin/sh
if [ -z "$${IPKG_INSTROOT}" ]; then
	[ -f /etc/uci-defaults/linkease ] && /etc/uci-defaults/linkease && rm -f /etc/uci-defaults/linkease
	exit 0
fi
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/sbin/linkease-plugins $(1)/etc/config $(1)/etc/init.d $(1)/etc/uci-defaults
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/linkease.$(PKG_ARCH_LINKEASE) $(1)/usr/sbin/linkease
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/heif-converter.$(PKG_ARCH_LINKEASE) $(1)/usr/sbin/heif-converter
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/linkease-media.$(PKG_ARCH_LINKEASE) $(1)/usr/sbin/linkease-media
	$(INSTALL_BIN) ./files/linkease-config.sh $(1)/usr/sbin/linkease-config.sh
	$(INSTALL_CONF) ./files/linkease.config $(1)/etc/config/linkease
	$(INSTALL_BIN) ./files/linkease.init $(1)/etc/init.d/linkease
	$(INSTALL_BIN) ./files/linkease.uci-default $(1)/etc/uci-defaults/linkease
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
