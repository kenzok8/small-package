# Copyright (C) 2020-2026 Hyy2001X <https://github.com/Hyy2001X>

include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-iperf3-server
PKG_VERSION:=3.0.0
PKG_RELEASE:=3

PKG_LICENSE:=GPL-3.0-or-later

LUCI_TITLE:=LuCI support for iPerf3 Server
LUCI_DESCRIPTION:=Configure and manage multiple iperf3 server instances with LuCI status/actions.
LUCI_DEPENDS:=+iperf3

LUCI_PKGARCH:=all

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
