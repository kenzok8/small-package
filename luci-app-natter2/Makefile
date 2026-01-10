# Copyright (C) 2020-2024 Hyy2001X <https://github.com/Hyy2001X>

include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-natter2
PKG_VERSION:=1.0
PKG_RELEASE:=4

LUCI_TITLE:=LuCI Support for Natter v2.2.1
LUCI_PKGARCH:=all
LUCI_DEPENDS:=+natter2 +coreutils-nohup

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
