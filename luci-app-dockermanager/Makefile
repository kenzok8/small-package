#
# Copyright (C) 2026 LinkEase Contributors
#
# This is free software, licensed under the Apache License, Version 2.0 .
#

include $(TOPDIR)/rules.mk

LUCI_TITLE:=LuCI support for Docker Manager
LUCI_DEPENDS:=+dockermanager +luci-lib-linkeaseauth +linkease-app-entry
# apps_compat/apps_openwrt are absent from the legacy 1.0.3 auth package.
LUCI_EXTRA_DEPENDS:=luci-lib-linkeaseauth (>=1.2.1)
LUCI_PKGARCH:=all

PKG_VERSION:=0.1.2-r2
# Keep the revision in PKG_VERSION for LuCI builders that clear PKG_RELEASE.
PKG_RELEASE:=

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
