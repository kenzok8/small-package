

include $(TOPDIR)/rules.mk

PKG_VERSION:=1.1.7-20241211
PKG_RELEASE:=

LUCI_TITLE:=LuCI support for istoredup
LUCI_PKGARCH:=all
LUCI_DEPENDS:=+lsblk +docker +dockerd +luci-lib-taskd +vmease

define Package/luci-app-istoredup/conffiles
/etc/config/istoredup
endef

define Package/luci-app-istoredup/prerm
#!/bin/sh
/usr/libexec/istorec/istoredup.sh stop
exit 0
endef

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
