# Copyright (C) 2016 Openwrt.org
#
# This is free software, licensed under the Apache License, Version 2.0 .
#

include $(TOPDIR)/rules.mk

LUCI_TITLE:=LuCI support for fastnet
LUCI_DEPENDS:=+fastnet +luci-lib-linkeaseauth
LUCI_PKGARCH:=all
PKG_VERSION:=0.7.7
PKG_RELEASE:=3
LUCI_MINIFY_CSS:=0
LUCI_MINIFY_JS:=0

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
