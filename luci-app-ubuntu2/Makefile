

include $(TOPDIR)/rules.mk

PKG_VERSION:=1.0.3-20241215
PKG_RELEASE:=

LUCI_TITLE:=LuCI support for Ubuntu2
LUCI_PKGARCH:=all
LUCI_DEPENDS:=+lsblk +docker +dockerd +luci-lib-taskd

define Package/luci-app-ubuntu2/conffiles
/etc/config/ubuntu2
endef

define Package/luci-app-ubuntu2/prerm
#!/bin/sh
/usr/libexec/istorec/ubuntu2.sh stop
exit 0
endef

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
