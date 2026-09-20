# Copyright (C) 2016 Openwrt.org
#
# This is free software, licensed under the Apache License, Version 2.0 .
#

include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-honk
PKG_VERSION:=1.1.0
PKG_RELEASE:=1

LUCI_TITLE:=LuCI support for honk
LUCI_PKGARCH:=all
LUCI_DEPENDS:=+honk +luci-base +rpcd-mod-ucode

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature

