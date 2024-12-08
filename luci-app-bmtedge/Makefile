

include $(TOPDIR)/rules.mk

PKG_VERSION:=1.0.2-20241208
PKG_RELEASE:=

LUCI_TITLE:=LuCI support for bmtedge
LUCI_PKGARCH:=all
LUCI_DEPENDS:=+lsblk +docker +dockerd +luci-lib-taskd

define Package/luci-app-bmtedge/conffiles
/etc/config/bmtedge
endef

# prerm
# postrm
define Package/luci-app-bmtedge/prerm
#!/bin/sh
docker rm -f bmtedge
exit 0
endef

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
