# SPDX-License-Identifier: GPL-3.0-only
#
# Copyright (C) 2021-2025  sirpdboy  <herboy2008@gmail.com> 
# https://github.com/sirpdboy/luci-app-ddns-go 
# This is free software, licensed under the Apache License, Version 2.0 .
#

include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-netspeedtest

PKG_VERSION:=5.0.1
PKG_RELEASE:=20250512

LUCI_TITLE:=LuCI Support for netspeedtest
LUCI_DEPENDS:=+speedtest-cli +homebox +iperf3-ssl
LUCI_PKGARCH:=all
PKG_MAINTAINER:=sirpdboy  <herboy2008@gmail.com>


define Package/$(PKG_NAME)/conffiles
/etc/config/netspeedtest
endef

define Package/$(PKG_NAME)/postinst
endef


include $(TOPDIR)/feeds/luci/luci.mk


# call BuildPackage - OpenWrt buildroot signature
