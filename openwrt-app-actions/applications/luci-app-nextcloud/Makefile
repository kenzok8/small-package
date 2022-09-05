

include $(TOPDIR)/rules.mk

PKG_VERSION:=1.1.0-20220830
PKG_RELEASE:=

LUCI_TITLE:=LuCI support for nextcloud
LUCI_PKGARCH:=all
LUCI_DEPENDS:=+docker +luci-lib-taskd

define Package/luci-app-nextcloud/conffiles
/etc/config/nextcloud
endef

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
