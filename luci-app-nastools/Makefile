

include $(TOPDIR)/rules.mk

PKG_VERSION:=1.1.3-20240822
PKG_RELEASE:=

LUCI_TITLE:=LuCI support for nastools
LUCI_PKGARCH:=all
LUCI_DEPENDS:=+lsblk +docker +dockerd +luci-lib-taskd

define Package/luci-app-nastools/conffiles
/etc/config/nastools
endef

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
