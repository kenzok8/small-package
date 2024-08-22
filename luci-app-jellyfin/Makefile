

include $(TOPDIR)/rules.mk

PKG_VERSION:=1.2.0-20240822
PKG_RELEASE:=

LUCI_TITLE:=LuCI support for jellyfin
LUCI_PKGARCH:=all
LUCI_DEPENDS:=+lsblk +docker +dockerd +luci-lib-taskd

define Package/luci-app-jellyfin/conffiles
/etc/config/jellyfin
endef

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature

