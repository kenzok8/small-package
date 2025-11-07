# SPDX-License-Identifier: GPL-3.0-only
#
# Copyright (C) 2021-2025  sirpdboy  <herboy2008@gmail.com> 
# https://github.com/sirpdboy/luci-app-netspeedtest
# This is free software, licensed under the Apache License, Version 2.0 .
#

include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-netspeedtest

PKG_VERSION:=5.1.0
PKG_RELEASE:=20251108

LUCI_TITLE:=LuCI Support for netspeedtest
LUCI_DEPENDS:=+speedtest-cli +homebox +netspeedtest $(if $(find_package iperf3-ssl),+iperf3-ssl,+iperf3)
LUCI_PKGARCH:=all
PKG_MAINTAINER:=sirpdboy  <herboy2008@gmail.com>

include $(TOPDIR)/feeds/luci/luci.mk


# call BuildPackage - OpenWrt buildroot signature
