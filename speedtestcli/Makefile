#
# Copyright (C) 2015-2016 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v3.
#

include $(TOPDIR)/rules.mk

PKG_ARCH_SPEEDTEST:=$(ARCH)

PKG_NAME:=speedtestcli
PKG_VERSION:=1.2.0
PKG_RELEASE:=$(PKG_ARCH_SPEEDTEST)-1
PKG_SOURCE:=$(PKG_NAME)-binary-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=http://fw.koolcenter.com/binary/SpeedTestCli/
PKG_HASH:=a7c24e1594251b376684d221c64cc0e717726c7229944eab9b3b5b74ec64238f

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-binary-$(PKG_VERSION)

PKG_BUILD_PARALLEL:=1
PKG_USE_MIPS16:=0

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	SECTION:=net
	CATEGORY:=Network
	SUBMENU:=Web Servers/Proxies
	TITLE:=SpeedTestCli - network speed test
	PKGARCH:=all
	URL:=https://www.speedtest.net
endef

define Package/$(PKG_NAME)/description
  SpeedTestCli is a network speed test command
endef

define Package/$(PKG_NAME)/conffiles
endef

define Package/$(PKG_NAME)/postinst
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/speedtest.$(PKG_ARCH_SPEEDTEST) $(1)/usr/bin/speedtest
endef

$(eval $(call BuildPackage,$(PKG_NAME)))

