#
# Copyright (C) 2026 LinkEase Contributors
#
# This is free software, licensed under the Apache License, Version 2.0 .
#

include $(TOPDIR)/rules.mk

LUCI_TITLE:=LuCI support for Docker Manager
LUCI_DEPENDS:=+dockermanager +luci-lib-linkeaseauth
LUCI_PKGARCH:=all

PKG_VERSION:=0.1.1
PKG_RELEASE:=1

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
