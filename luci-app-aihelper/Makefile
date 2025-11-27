#
# Copyright (C) 2008-2014 The LuCI Team <luci@lists.subsignal.org>
#
# This is free software, licensed under the Apache License, Version 2.0 .
#

include $(TOPDIR)/rules.mk

LUCI_TITLE:=aihelper
PKG_VERSION:=1.0.0
PKG_RELEASE:=4
LUCI_DEPENDS:=+aihelper +opencode
LUCI_MINIFY_CSS:=0
LUCI_MINIFY_JS:=0

define Package/luci-app-aihelper/conffiles
/etc/config/aihelper
endef

define Package/luci-nginxer/postrm
#!/bin/sh
rm -f /tmp/luci-indexcache
exit 0
endef

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature