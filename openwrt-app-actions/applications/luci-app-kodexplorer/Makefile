

include $(TOPDIR)/rules.mk

PKG_VERSION:=1.2.1-20230108
PKG_RELEASE:=

LUCI_TITLE:=LuCI support for kodexplorer
LUCI_PKGARCH:=all
LUCI_DEPENDS:=+docker +luci-lib-taskd

define Package/luci-app-kodexplorer/conffiles
/etc/config/kodexplorer
endef

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
