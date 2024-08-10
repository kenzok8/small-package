# Copyright (C) 2019 Openwrt.org
#
# This is free software, licensed under the Apache License, Version 2.0 .
#

include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-qbittorrent
PKG_VERSION:=1.0.1
PKG_RELEASE:=1

LUCI_TITLE:=LuCI support for qBittorrent
LUCI_PKGARCH:=all
LUCI_DEPENDS:=+qbittorrent

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
