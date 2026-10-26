# Copyright (C) 2016 Openwrt.org
#
# This is free software, licensed under the Apache License, Version 2.0 .
#

include $(TOPDIR)/rules.mk

LUCI_TITLE:=LuCI support for fastnet
LUCI_DEPENDS:=+fastnet +luci-lib-linkeaseauth +linkease-app-entry
LUCI_PKGARCH:=all
PKG_VERSION:=0.7.8-r5
PKG_RELEASE:=
LUCI_MINIFY_CSS:=0
LUCI_MINIFY_JS:=0

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
