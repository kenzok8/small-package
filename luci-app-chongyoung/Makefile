#
# Copyright (C) 2008-2014 The LuCI Team <luci@lists.subsignal.org>
#
# This is free software, licensed under the Apache License, Version 2.0 .
#

include $(TOPDIR)/rules.mk

LUCI_TITLE:=chongyoung for luci
LUCI_DEPENDS:=
LUCI_PKGARCH:=all
PKG_VERSION:=4.1.1
PKG_RELEASE:=4

define Package/luci-app-chongyoung/postinst
#!/bin/sh
chmod +x $(1)/etc/init.d/*
exit 0
endef

include $(TOPDIR)/feeds/luci/luci.mk
# call BuildPackage - OpenWrt buildroot signature
