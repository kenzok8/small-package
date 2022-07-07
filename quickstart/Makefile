#
# Copyright (C) 2015-2016 OpenWrt.org
# Copyright (C) 2020 jjm2473@gmail.com
#
# This is free software, licensed under the GNU General Public License v3.
#

include $(TOPDIR)/rules.mk

PKG_ARCH_quickstart:=$(ARCH)

PKG_NAME:=quickstart
PKG_VERSION:=0.5.1
PKG_RELEASE:=1
PKG_SOURCE:=$(PKG_NAME)-binary-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://fw.koolcenter.com/binary/quickstart/
PKG_HASH:=8899a306a3eb19c050a81c5101d40426083232d2487198d8ac2a8c67a55b1f67

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-binary-$(PKG_VERSION)

PKG_BUILD_PARALLEL:=1
PKG_USE_MIPS16:=0

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	SECTION:=net
	CATEGORY:=Network
	SUBMENU:=Web Servers/Proxies
	TITLE:=Quickstart, the quick start.
	DEPENDS:=@(x86_64||aarch64) +shadow-utils +shadow-useradd +mount-utils +lsblk +e2fsprogs +parted +smartmontools +smartd +mdadm
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
	$(INSTALL_DIR) $(1)/usr/sbin $(1)/etc/init.d $(1)/etc/uci-defaults $(1)/etc/hotplug.d/block $(1)/etc/config
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/quickstart.$(PKG_ARCH_quickstart) $(1)/usr/sbin/quickstart
	$(INSTALL_BIN) ./files/quickstart.init $(1)/etc/init.d/quickstart
	$(INSTALL_BIN) ./files/quickstart.uci-default $(1)/etc/uci-defaults/quickstart
	$(INSTALL_BIN) ./files/quickstart.hotplug $(1)/etc/hotplug.d/block/11-quickstart
	$(INSTALL_BIN) ./files/quickstart.config $(1)/etc/config/quickstart
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
