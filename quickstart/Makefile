#
# Copyright (C) 2015-2016 OpenWrt.org
# Copyright (C) 2020 jjm2473@gmail.com
#
# This is free software, licensed under the GNU General Public License v3.
#

include $(TOPDIR)/rules.mk

PKG_ARCH_quickstart:=$(ARCH)

PKG_NAME:=quickstart
PKG_VERSION:=0.4.9
PKG_RELEASE:=1
PKG_SOURCE:=$(PKG_NAME)-binary-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://fw.koolcenter.com/binary/quickstart/
PKG_HASH:=6f8b5a1281a35d9832fe6fb8c797313020ddada99f0043cfa041f3c6f9950f54

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-binary-$(PKG_VERSION)

PKG_BUILD_PARALLEL:=1
PKG_USE_MIPS16:=0

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	SECTION:=net
	CATEGORY:=Network
	SUBMENU:=Web Servers/Proxies
	TITLE:=Quickstart, the quick start.
	DEPENDS:=@(x86_64||aarch64) +shadow-utils +shadow-useradd +mount-utils +lsblk +e2fsprogs +parted
	URL:=https://easepi.linkease.com/
endef

define Package/$(PKG_NAME)/description
  Quickstart is a dashboard & user guide
endef



define Package/$(PKG_NAME)/postinst
#!/bin/sh
if [ -z "$${IPKG_INSTROOT}" ]; then
	[ -f /etc/uci-defaults/quickstart ] && /etc/uci-defaults/quickstart && rm -f /etc/uci-defaults/quickstart
fi
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/sbin $(1)/etc/init.d $(1)/etc/uci-defaults
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/quickstart.$(PKG_ARCH_quickstart) $(1)/usr/sbin/quickstart
	$(INSTALL_BIN) ./files/quickstart.init $(1)/etc/init.d/quickstart
	$(INSTALL_BIN) ./files/quickstart.uci-default $(1)/etc/uci-defaults/quickstart
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
