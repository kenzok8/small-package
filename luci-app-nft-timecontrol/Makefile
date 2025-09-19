#
# Copyright (C) 2006-2017 OpenWrt.org
# Copyright (C) 2022-2025 sirpdboy <herboy2008@gmail.com>
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

THEME_NAME:=nft-timecontrol
PKG_NAME:=luci-app-$(THEME_NAME)

PKG_LICENSE:=Apache-2.0

LUCI_TITLE:=LuCI support for timecontrol for nftables
LUCI_DESCRIPTION:=LuCI support for Easy timecontrol for nftables(Internet time control).
LUCI_DEPENDS:=+bc +nftables +bash
LUCI_PKGARCH:=all

PKG_VERSION:=3.1.4
PKG_RELEASE:=20250722
PKG_MAINTAINER:=sirpdboy <herboy2008@gmail.com>

define Build/Compile
endef

define Package/$(PKG_NAME)/postinst
#!/bin/sh
rm -f /tmp/luci-*
endef

define Package/$(PKG_NAME)/conffiles
/etc/config/timecontrol
endef

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature

