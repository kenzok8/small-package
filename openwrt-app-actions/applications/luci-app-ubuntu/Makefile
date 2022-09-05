

include $(TOPDIR)/rules.mk

PKG_VERSION:=1.0.6
PKG_RELEASE:=20220626

LUCI_TITLE:=LuCI support for ubuntu
LUCI_PKGARCH:=all
LUCI_DEPENDS:=+docker +luci-lib-iform

define Package/luci-app-ubuntu/conffiles
/etc/config/ubuntu
endef

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature

