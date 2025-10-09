

include $(TOPDIR)/rules.mk

# Updated: 2025-10-09
PKG_VERSION:=1.0.0-20251009
PKG_RELEASE:=

LUCI_TITLE:=LuCI support for DPanel
LUCI_PKGARCH:=all
LUCI_DEPENDS:=+lsblk +zoneinfo-asia +docker +dockerd +luci-lib-taskd +luci-lib-docker

define Package/luci-app-dpanel/conffiles
/etc/config/dpanel
endef

define Package/luci-app-dpanel/prerm
#!/bin/sh
/usr/libexec/istorec/dpanel.sh stop
exit 0
endef

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
