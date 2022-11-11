

include $(TOPDIR)/rules.mk

PKG_VERSION:=1.0.0-20221111
PKG_RELEASE:=

LUCI_TITLE:=LuCI support for ChineseSubFinder
LUCI_PKGARCH:=all
LUCI_DEPENDS:=+docker +luci-lib-taskd

define Package/luci-app-chinesesubfinder/conffiles
/etc/config/chinesesubfinder
endef

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
