

include $(TOPDIR)/rules.mk

PKG_VERSION:=1.0.2-20240822
PKG_RELEASE:=

LUCI_TITLE:=LuCI support for Owntone
LUCI_PKGARCH:=all
LUCI_DEPENDS:=+lsblk +docker +dockerd +luci-lib-taskd

define Package/luci-app-owntone/conffiles
/etc/config/owntone
endef

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
