# This is free software, licensed under the Apache License, Version 2.0

include $(TOPDIR)/rules.mk

# luci-app-natmap_git-23.208.32967-01d4ecb_all.ipk
# https://t.me/ctcgfw_openwrt_discuss/1029229
PKG_VERSION:=zzz-99.999.99999-1.0.2
PKG_PO_VERSION:=$(PKG_VERSION)

LUCI_TITLE:=LuCI Support for natmap
LUCI_DEPENDS:=+natmap
PKG_LICENSE:=Apache-2.0
PKG_MAINTAINER:=Richard Yu <yurichard3839@gmail.com>

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
