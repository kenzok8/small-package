

include $(TOPDIR)/rules.mk

PKG_VERSION:=1.0.1-20230108
PKG_RELEASE:=

LUCI_TITLE:=LuCI support for Navidrome
LUCI_PKGARCH:=all
LUCI_DEPENDS:=+lsblk +docker +luci-lib-taskd

define Package/luci-app-navidrome/conffiles
/etc/config/navidrome
endef

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
