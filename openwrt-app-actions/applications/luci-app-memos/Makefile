

include $(TOPDIR)/rules.mk

PKG_VERSION:=1.0.1-20230108
PKG_RELEASE:=

LUCI_TITLE:=LuCI support for Memos
LUCI_PKGARCH:=all
LUCI_DEPENDS:=+docker +luci-lib-taskd

define Package/luci-app-memos/conffiles
/etc/config/memos
endef

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
