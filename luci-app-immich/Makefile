

include $(TOPDIR)/rules.mk

PKG_VERSION:=1.0.2-20250321
PKG_RELEASE:=

LUCI_TITLE:=LuCI support for Immich
LUCI_PKGARCH:=all
LUCI_DEPENDS:=+lsblk +docker +dockerd +luci-lib-taskd +luci-lib-docker +docker-compose

define Package/luci-app-immich/conffiles
/etc/config/immich
endef

define Package/luci-app-immich/prerm
#!/bin/sh
/usr/libexec/istorec/immich.sh stop
exit 0
endef

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
