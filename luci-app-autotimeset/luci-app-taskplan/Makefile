#
# Copyright 2019-2025 sirpdboy 
#
# This is free software, licensed under the Apache License, Version 2.0 .
#

include $(TOPDIR)/rules.mk

NAME:=taskplan
PKG_NAME:=luci-app-$(NAME)
LUCI_TITLE:=LuCI support for Task Plan setting
LUCI_PKGARCH:=all

PKG_VERSION:=2.2.2
PKG_RELEASE:=20250409


define Package/$(PKG_NAME)/conffiles
/etc/config/taskplan
endef

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature

