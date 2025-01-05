

include $(TOPDIR)/rules.mk

PKG_VERSION:=8.3.2-20250105
PKG_RELEASE:=

LUCI_TITLE:=LuCI support for pve
LUCI_PKGARCH:=all
LUCI_DEPENDS:=+lsblk +docker +dockerd +luci-lib-taskd +vmease

define Package/luci-app-pve/conffiles
/etc/config/pve
endef

define Package/luci-app-pve/prerm
#!/bin/sh
/usr/libexec/istorec/pve.sh stop
exit 0
endef

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
