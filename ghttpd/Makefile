#
# Copyright (C) 2015-2016 OpenWrt.org
# Copyright (C) 2020 jjm2473@gmail.com
#
# This is free software, licensed under the GNU General Public License v3.
#

include $(TOPDIR)/rules.mk

PKG_ARCH_ghttpd:=$(ARCH)

PKG_NAME:=ghttpd
PKG_VERSION:=0.0.3
PKG_RELEASE:=1
PKG_SOURCE:=$(PKG_NAME)-binary-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://github.com/Carseason/openwrt-packages/releases/download/prebuilt/
PKG_HASH:=a5d6815f506002cb2f3b9cf297cc6213fc8a6b69abc128f73c7904896154e0dd
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-binary-$(PKG_VERSION)

PKG_BUILD_PARALLEL:=1
PKG_USE_MIPS16:=0

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	SECTION:=net
	CATEGORY:=Network
	SUBMENU:=Web Servers/Proxies
	TITLE:=ghttpd
	DEPENDS:=@(x86_64||aarch64||arm) +docker
	URL:=https://github.com/Carseason/openwrt-packages
endef

define Package/$(PKG_NAME)/description
  ghttpd is a dashboard & user guide
endef

define Package/$(PKG_NAME)/conffiles
/etc/config/ghttpd
endef

define Package/$(PKG_NAME)/postinst
#!/bin/sh
if [ -z "$${IPKG_INSTROOT}" ]; then
	if [ -f /etc/uci-defaults/09-ghttpd ]; then
		chmod 755 /etc/uci-defaults/09-ghttpd
		/etc/uci-defaults/09-ghttpd && rm -f /etc/uci-defaults/09-ghttpd
	fi
fi
endef

define Package/$(PKG_NAME)/postrm
#!/bin/sh
for service in uhttpd nginx; do
	[ -x "/etc/init.d/$$service" ] || continue
	"/etc/init.d/$$service" enabled && "/etc/init.d/$$service" restart
done
exit 0
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/sbin $(1)/etc/init.d $(1)/etc/uci-defaults $(1)/etc/config
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/ghttpd.$(PKG_ARCH_ghttpd) $(1)/usr/sbin/ghttpd
	$(INSTALL_BIN) ./files/ghttpd.init $(1)/etc/init.d/ghttpd
	$(INSTALL_BIN) ./files/ghttpd.uci-default $(1)/etc/uci-defaults/09-ghttpd
	$(INSTALL_CONF) ./files/ghttpd.config $(1)/etc/config/ghttpd
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
