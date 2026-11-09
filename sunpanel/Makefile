#
# Copyright (C) 2015-2016 OpenWrt.org
# Copyright (C) 2024 xiaobao@linkease.com
#
# This is free software, licensed under the GNU General Public License v3.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=sunpanel
PKG_VERSION:=1.8.1
PKG_RELEASE:=1

# v1.8.1 official release assets are per-arch (linux musl static binary)
ifeq ($(ARCH),x86_64)
  GO_ARCH:=amd64
else ifeq ($(ARCH),aarch64)
  GO_ARCH:=arm64
endif

PKG_SOURCE:=sun-panel_v$(PKG_VERSION)_linux_musl_$(GO_ARCH).tar.gz
PKG_SOURCE_URL:=https://github.com/hslr-s/sun-panel/releases/download/v$(PKG_VERSION)
PKG_HASH:=$(if $(filter x86_64,$(ARCH)),c1f03fbb97b2bd801768474bb20f736fc699dd822b6330c545edb5356b12b07c,6821facee03bd56d8be0f50da9ee05fd664b11064acdfee6dacba73c77e25cd2)

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)

PKG_BUILD_PARALLEL:=1
PKG_USE_MIPS16:=0

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	SECTION:=net
	CATEGORY:=Network
	SUBMENU:=Web Servers/Proxies
	TITLE:=SunPanel, NAS navigation panel.
	DEPENDS:=@(x86_64||aarch64) +ubus +uci +bash
	URL:=https://sun-panel-doc.enianteam.com/
endef

define Package/$(PKG_NAME)/description
  Server, NAS navigation panel, Homepage, Browser homepage.
endef

define Package/$(PKG_NAME)/conffiles
/etc/config/sunpanel
endef

define Package/$(PKG_NAME)/postinst
#!/bin/sh
if [ -z "$${IPKG_INSTROOT}" ]; then
	[ -f /etc/uci-defaults/sunpanel ] && /etc/uci-defaults/sunpanel && rm -f /etc/uci-defaults/sunpanel
	exit 0
fi
endef

# The official tarball has one top-level dir, strip it so files land in PKG_BUILD_DIR
#define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	$(TAR) --strip-components=1 -xzf $(DL_DIR)/$(PKG_SOURCE) -C $(PKG_BUILD_DIR)
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/sbin $(1)/etc/init.d $(1)/etc/config $(1)/usr/libexec/istorec $(1)/usr/share/sunpanel $(1)/etc/uci-defaults $(1)/www/luci-static
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/sun-panel $(1)/usr/sbin/sunpanelbin
	$(CP) $(PKG_BUILD_DIR)/web $(1)/www/luci-static/sunpanel
	$(INSTALL_BIN) ./files/sunpanel.init $(1)/etc/init.d/sunpanel
	$(CP) ./files/sunpanel_conf.lua $(1)/usr/libexec/istorec/
	$(CP) ./files/conf.temp $(1)/usr/share/sunpanel/
	$(INSTALL_CONF) ./files/sunpanel.config $(1)/etc/config/sunpanel
	$(INSTALL_BIN) ./files/sunpanel.uci-default $(1)/etc/uci-defaults/sunpanel
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
