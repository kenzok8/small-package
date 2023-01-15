# Copyright (C) 2019-2021  sirpdboy  https://github.com/sirpdboy/luci-app-autotimeset
# 
# This is free software, licensed under the Apache License, Version 2.0 .
#

include $(TOPDIR)/rules.mk

LUCI_TITLE:=LuCI support for Scheduled Time setting
LUCI_PKGARCH:=all

PKG_VERSION:=1.6
PKG_RELEASE:=20230115

define Package/$(PKG_NAME)/conffiles
/etc/config/autotimeset
endef

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature

