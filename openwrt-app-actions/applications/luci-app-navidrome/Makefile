

include $(TOPDIR)/rules.mk

PKG_VERSION:=1.0.0-20221119
PKG_RELEASE:=

LUCI_TITLE:=LuCI support for Navidrome
LUCI_PKGARCH:=all
LUCI_DEPENDS:=+docker +luci-lib-taskd

define Package/luci-app-navidrome/conffiles
/etc/config/navidrome
endef

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
