

include $(TOPDIR)/rules.mk

PKG_VERSION:=1.0.0-20240207
PKG_RELEASE:=

LUCI_TITLE:=LuCI support for OneAPI
LUCI_PKGARCH:=all
LUCI_DEPENDS:=+lsblk +zoneinfo-asia +docker +dockerd +luci-lib-taskd +luci-lib-docker

define Package/luci-app-oneapi/conffiles
/etc/config/oneapi
endef

define Package/luci-app-oneapi/prerm
#!/bin/sh
/usr/libexec/istorec/oneapi.sh stop
exit 0
endef

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
