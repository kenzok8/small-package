# Copyright (C) 2016 Openwrt.org
#
# This is free software, licensed under the Apache License, Version 2.0 .
#

include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-airconnect
PKG_VERSION:=1.0.2
PKG_RELEASE:=1

LUCI_TITLE:=LuCI support for AirConnect
LUCI_DEPENDS:=+airconnect
LUCI_PKGARCH:=all

PKG_MAINTAINER:=sbwml <admin@cooluc.com>

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
