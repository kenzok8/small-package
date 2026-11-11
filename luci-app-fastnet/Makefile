# Copyright (C) 2016 Openwrt.org
#
# This is free software, licensed under the Apache License, Version 2.0 .
#

include $(TOPDIR)/rules.mk

LUCI_TITLE:=LuCI support for fastnet
LUCI_DEPENDS:=+fastnet +luci-lib-linkeaseauth +linkease-app-entry
# APK uses -rN; OPKG uses -N for runtime package releases.
LUCI_EXTRA_DEPENDS:=fastnet (>=0.8.9-$(if $(CONFIG_USE_APK),r)1)
LUCI_PKGARCH:=all
PKG_VERSION:=0.8.9-r1
PKG_RELEASE:=
# Preserve LuCI translation version ordering when upgrading older git-* packages.
PKG_PO_VERSION:=git-26.313.00000-082
LUCI_MINIFY_CSS:=0
LUCI_MINIFY_JS:=0

define Package/luci-app-fastnet/postinst
#!/bin/sh
set -e
"$${IPKG_INSTROOT}/usr/libexec/fastnet-card-register" install
if [ -z "$${IPKG_INSTROOT}" ]; then
	rm -f /tmp/luci-indexcache /tmp/luci-indexcache.*
	rm -rf /tmp/luci-modulecache/
	killall -HUP rpcd 2>/dev/null || true
fi
endef

define Package/luci-app-fastnet/prerm
#!/bin/sh
"$${IPKG_INSTROOT}/usr/libexec/fastnet-card-register" remove
endef

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
