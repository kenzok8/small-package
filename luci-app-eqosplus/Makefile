#
# Copyright (C) 2006-2017 OpenWrt.org
# Copyright (C) 2022-2025 sirpdboy <herboy2008@gmail.com>
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

THEME_NAME:=eqosplus
PKG_NAME:=luci-app-$(THEME_NAME)

PKG_LICENSE:=Apache-2.0

LUCI_TITLE:=LuCI support for eqosplus.
LUCI_DESCRIPTION:=LuCI support for Easy eqosplus(Support speed limit based on IP address).
LUCI_DEPENDS:=+bash +tc +kmod-sched-core +kmod-ifb +kmod-sched +iptables-mod-filter +iptables-mod-nat-extra
LUCI_PKGARCH:=all

PKG_VERSION:=1.2.8
PKG_RELEASE:=20250723
PKG_MAINTAINER:=sirpdboy <herboy2008@gmail.com>

define Build/Compile
endef

define Package/$(PKG_NAME)/postinst
#!/bin/sh
rm -f /tmp/luci-*
endef

define Package/$(PKG_NAME)/conffiles
/etc/config/eqosplus
endef

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature

