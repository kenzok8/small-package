# SPDX-License-Identifier: Apache-2.0
#
# Copyright (C) 2023-2025 muink <https://github.com/muink>

include $(TOPDIR)/rules.mk

LUCI_NAME:=luci-app-dnsproxy

LUCI_TITLE:=LuCI Support for dnsproxy
LUCI_PKGARCH:=all
LUCI_DEPENDS:=+dnsproxy
LUCI_DESCRIPTION:=Simple DNS proxy with DoH, DoT, DoQ and DNSCrypt support

PKG_LICENSE:=Apache-2.0
PKG_MAINTAINER:=Anya Lin <hukk1996@gmail.com>

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
