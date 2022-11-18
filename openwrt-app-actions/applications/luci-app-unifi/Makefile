

include $(TOPDIR)/rules.mk

PKG_VERSION:=1.0.0-20221114
PKG_RELEASE:=

LUCI_TITLE:=LuCI support for UnifiController
LUCI_PKGARCH:=all
LUCI_DEPENDS:=+docker +luci-lib-taskd

define Package/luci-app-unifi/conffiles
/etc/config/unifi
endef

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
