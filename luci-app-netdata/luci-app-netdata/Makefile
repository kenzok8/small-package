# SPDX-License-Identifier: GPL-3.0
#
# Copyright (C) 2021-2025  sirpdboy  <herboy2008@gmail.com> https://github.com/sirpdboy/luci-app-netdata
#
# This is free software, licensed under the Apache License, Version 2.0 .
#
include $(TOPDIR)/rules.mk

LUCI_NAME:=luci-app-netdata


PKG_NAME:=luci-app-Netdata
PKG_VERSION:=2.0.1
PKG_RELEASE:=20251029


LUCI_TITLE:=Grant UCI access for netdata

LUCI_DEPENDS:=+!netdata-ssl:netdata
LUCI_PKGARCH:=all

PKG_LICENSE:=GPL-3.0


include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
