

include $(TOPDIR)/rules.mk

PKG_VERSION:=1.1.5-20241129
PKG_RELEASE:=

LUCI_TITLE:=LuCI support for istoredup
LUCI_PKGARCH:=all
LUCI_DEPENDS:=+lsblk +docker +dockerd +luci-lib-taskd +vmease

define Package/luci-app-istoredup/conffiles
/etc/config/istoredup
endef

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
