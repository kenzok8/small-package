#
# Copyright (C) 2008-2019 Jerrykuku
#
# This is free software, licensed under the Apache License, Version 2.0 .
#

include $(TOPDIR)/rules.mk

LUCI_TITLE:=Argon Theme
LUCI_DEPENDS:=+wget +jsonfilter

PKG_VERSION:=2.4.3
PKG_RELEASE:=20250722

LUCI_MINIFY_CSS:=0

define Package/luci-theme-argon/conffiles
/etc/config/argon
/www/luci-static/argon/background/
endef

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
