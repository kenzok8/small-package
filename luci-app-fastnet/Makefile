# Copyright (C) 2016 Openwrt.org
#
# This is free software, licensed under the Apache License, Version 2.0 .
#

include $(TOPDIR)/rules.mk

LUCI_TITLE:=LuCI support for fastnet
LUCI_DEPENDS:=+fastnet +luci-lib-linkeaseauth +linkease-app-entry
# APK uses -rN; OPKG uses -N for runtime package releases.
LUCI_EXTRA_DEPENDS:=fastnet (>=0.8.10-$(if $(CONFIG_USE_APK),r)4)
LUCI_PKGARCH:=all
PKG_VERSION:=0.8.10-r2
PKG_RELEASE:=
LUCI_MINIFY_CSS:=0
LUCI_MINIFY_JS:=0

define Package/luci-app-fastnet/postinst
#!/bin/sh
"$${IPKG_INSTROOT}/usr/libexec/fastnet-card-register" install || \
	printf '%s\n' 'luci-app-fastnet: unable to register the Quickstart card.' >&2
if [ -z "$${IPKG_INSTROOT}" ]; then
	rm -f /tmp/luci-indexcache /tmp/luci-indexcache.*
	rm -rf /tmp/luci-modulecache/
	killall -HUP rpcd 2>/dev/null || true
fi
exit 0
endef

define Package/luci-app-fastnet/prerm
#!/bin/sh
"$${IPKG_INSTROOT}/usr/libexec/fastnet-card-register" remove || \
	printf '%s\n' 'luci-app-fastnet: unable to remove the Quickstart card.' >&2
exit 0
endef

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
