
# Copyright (C) 2020-2021 sirpdboy <herboy2008@gmail.com>
#
# This is free software, licensed under the GNU General Public License v3.
# 

include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-netspeedtest

LUCI_TITLE:=LuCI Support for netspeedtest
LUCI_DEPENDS:=+python3 +iperf3 +speedtest-web
LUCI_PKGARCH:=all
PKG_VERSION:=2.0.4
PKG_RELEASE:=20221023
PKG_MAINTAINER:=<https://github.com/sirpdboy/netspeedtest>

include $(TOPDIR)/feeds/luci/luci.mk


# call BuildPackage - OpenWrt buildroot signature
