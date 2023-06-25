# Copyright (C) 2020-2021 Hyy2001X <https://github.com/Hyy2001X>

include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-webd
PKG_VERSION:=1.3
PKG_RELEASE:=3

LUCI_TITLE:=LuCI support for Webd Netdisk
LUCI_PKGARCH:=all

LUCI_DEPENDS:= \
	+PACKAGE_$(PKG_NAME)_INCLUDE_WEBD_BINARY:webd

define Package/$(PKG_NAME)/config

config PACKAGE_$(PKG_NAME)_INCLUDE_WEBD_BINARY
	bool "Include webd Binary"
	default y

endef

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
